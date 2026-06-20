package com.highsteak.api.service;

import com.highsteak.api.config.AuthProperties;
import com.highsteak.api.config.MailProperties;
import com.highsteak.api.domain.EmailVerificationToken;
import com.highsteak.api.domain.User;
import com.highsteak.api.repository.EmailVerificationTokenRepository;
import com.highsteak.api.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.util.UUID;

import static org.springframework.http.HttpStatus.BAD_REQUEST;
import static org.springframework.http.HttpStatus.NOT_FOUND;

@Service
@RequiredArgsConstructor
public class EmailVerificationService {

    private final EmailVerificationTokenRepository tokenRepository;
    private final UserRepository userRepository;
    private final MailService mailService;
    private final EmailTemplateService emailTemplateService;
    private final MailProperties mailProperties;
    private final AuthProperties authProperties;

    @Transactional
    public void sendVerificationEmail(User user) {
        if (user.isEmailVerified()) {
            return;
        }

        tokenRepository.invalidateActiveTokensForUser(user.getId(), Instant.now());

        String rawToken = RefreshTokenService.newRawToken();
        EmailVerificationToken entity = EmailVerificationToken.builder()
                .userId(user.getId())
                .tokenHash(RefreshTokenService.hashToken(rawToken))
                .expiresAt(Instant.now().plusSeconds(authProperties.getVerificationExpirationHours() * 3600L))
                .build();
        tokenRepository.save(entity);

        String verifyUrl = mailProperties.getBaseUrl() + "/verify-email?token=" + rawToken;
        EmailTemplateService.EmailMessage message = emailTemplateService.verifyEmail(
                user.getDisplayName(),
                verifyUrl);
        mailService.sendHtml(user.getEmail(), message.subject(), message.html(), message.text());
    }

    @Transactional
    public EmailVerificationResult verifyEmail(String rawToken) {
        if (rawToken == null || rawToken.isBlank()) {
            throw new ResponseStatusException(BAD_REQUEST, "Verification token is required");
        }

        EmailVerificationToken stored = tokenRepository
                .findActiveForUpdateByTokenHash(RefreshTokenService.hashToken(rawToken.trim()))
                .orElseThrow(() -> new ResponseStatusException(BAD_REQUEST, "Invalid or expired verification link"));

        if (stored.getExpiresAt().isBefore(Instant.now())) {
            stored.setUsedAt(Instant.now());
            tokenRepository.save(stored);
            throw new ResponseStatusException(BAD_REQUEST, "Verification link has expired");
        }

        User user = userRepository.findByIdWithRoleAndPermissions(stored.getUserId())
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "User not found"));

        if (user.isEmailVerified()) {
            stored.setUsedAt(Instant.now());
            tokenRepository.save(stored);
            return new EmailVerificationResult(user, false);
        }

        user.setEmailVerified(true);
        userRepository.save(user);

        stored.setUsedAt(Instant.now());
        tokenRepository.save(stored);

        User verified = userRepository.findByIdWithRoleAndPermissions(user.getId()).orElse(user);
        return new EmailVerificationResult(verified, true);
    }

    @Transactional
    public void resendVerificationEmail(String email) {
        if (email == null || email.isBlank()) {
            return;
        }
        userRepository.findByEmail(email.trim()).ifPresent(user -> {
            if (!user.isEmailVerified() && !user.isBlocked()) {
                sendVerificationEmail(user);
            }
        });
    }

    public record EmailVerificationResult(User user, boolean newlyVerified) {}
}
