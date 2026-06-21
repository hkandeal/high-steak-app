package com.highsteak.api.service;

import com.highsteak.api.config.AuthProperties;
import com.highsteak.api.config.MailProperties;
import com.highsteak.api.domain.AccountDeletionToken;
import com.highsteak.api.domain.User;
import com.highsteak.api.repository.AccountDeletionTokenRepository;
import com.highsteak.api.repository.UserRepository;
import com.highsteak.api.security.UserPrincipal;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.util.Set;
import java.util.UUID;

import static org.springframework.http.HttpStatus.BAD_REQUEST;
import static org.springframework.http.HttpStatus.FORBIDDEN;
import static org.springframework.http.HttpStatus.NOT_FOUND;

@Service
@RequiredArgsConstructor
public class AccountDeletionService {

    private static final Set<String> STAFF_ROLES = Set.of("ADMIN", "MODERATOR");

    private final AccountDeletionTokenRepository tokenRepository;
    private final UserRepository userRepository;
    private final MailService mailService;
    private final EmailTemplateService emailTemplateService;
    private final MailProperties mailProperties;
    private final AuthProperties authProperties;
    private final RefreshTokenService refreshTokenService;

    @Transactional
    public void requestDeletion(UserPrincipal principal) {
        User user = userRepository.findByIdWithRoleAndPermissions(principal.getId())
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "User not found"));

        assertCanDeleteAccount(user);

        tokenRepository.invalidateActiveTokensForUser(user.getId(), Instant.now());

        String rawToken = RefreshTokenService.newRawToken();
        AccountDeletionToken entity = AccountDeletionToken.builder()
                .userId(user.getId())
                .tokenHash(RefreshTokenService.hashToken(rawToken))
                .expiresAt(Instant.now().plusSeconds(authProperties.getDeletionExpirationHours() * 3600L))
                .build();
        tokenRepository.save(entity);

        String confirmUrl = mailProperties.getBaseUrl() + "/confirm-account-deletion?token=" + rawToken;
        EmailTemplateService.EmailMessage message = emailTemplateService.confirmAccountDeletion(
                user.getDisplayName(),
                confirmUrl,
                authProperties.getDeletionExpirationHours());
        mailService.sendHtml(user.getEmail(), message.subject(), message.html(), message.text());
    }

    @Transactional
    public void confirmDeletion(String rawToken) {
        if (rawToken == null || rawToken.isBlank()) {
            throw new ResponseStatusException(BAD_REQUEST, "Deletion token is required");
        }

        AccountDeletionToken stored = tokenRepository
                .findActiveForUpdateByTokenHash(RefreshTokenService.hashToken(rawToken.trim()))
                .orElseThrow(() -> new ResponseStatusException(BAD_REQUEST, "Invalid or expired deletion link"));

        if (stored.getExpiresAt().isBefore(Instant.now())) {
            stored.setUsedAt(Instant.now());
            tokenRepository.save(stored);
            throw new ResponseStatusException(BAD_REQUEST, "Deletion link has expired");
        }

        User user = userRepository.findByIdWithRoleAndPermissions(stored.getUserId())
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "User not found"));

        assertCanDeleteAccount(user);

        String email = user.getEmail();
        String displayName = user.getDisplayName();
        UUID userId = user.getId();

        stored.setUsedAt(Instant.now());
        tokenRepository.save(stored);

        refreshTokenService.revokeAllForUser(userId);
        userRepository.delete(user);

        EmailTemplateService.EmailMessage goodbye = emailTemplateService.accountDeletedGoodbye(displayName);
        mailService.sendHtml(email, goodbye.subject(), goodbye.html(), goodbye.text());
    }

    private void assertCanDeleteAccount(User user) {
        if (STAFF_ROLES.contains(user.getRole().getName())) {
            throw new ResponseStatusException(FORBIDDEN, "Staff accounts cannot be deleted this way");
        }
    }
}
