package com.highsteak.api.service;

import com.highsteak.api.config.AuthProperties;
import com.highsteak.api.config.MailProperties;
import com.highsteak.api.domain.PasswordResetToken;
import com.highsteak.api.domain.User;
import com.highsteak.api.dto.AuthDtos;
import com.highsteak.api.repository.PasswordResetTokenRepository;
import com.highsteak.api.repository.UserRepository;
import com.highsteak.api.validation.ApiConstraints;
import com.highsteak.api.validation.EmailValidation;
import com.highsteak.api.validation.TextValidation;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;

import static org.springframework.http.HttpStatus.BAD_REQUEST;
import static org.springframework.http.HttpStatus.NOT_FOUND;

@Service
@RequiredArgsConstructor
public class PasswordResetService {

    private static final String GENERIC_REQUEST_MESSAGE =
            "If an account matches those details, we sent a password reset link to its email.";

    private final PasswordResetTokenRepository tokenRepository;
    private final UserRepository userRepository;
    private final MailService mailService;
    private final EmailTemplateService emailTemplateService;
    private final MailProperties mailProperties;
    private final AuthProperties authProperties;
    private final RefreshTokenService refreshTokenService;
    private final PasswordEncoder passwordEncoder;

    @Transactional
    public AuthDtos.MessageResponse requestReset(String username, String email) {
        if (username == null || username.isBlank()) {
            throw new ResponseStatusException(BAD_REQUEST, "Username is required");
        }
        String normalizedUsername = TextValidation.bounded(
                username.trim(), "Username", 1, ApiConstraints.USERNAME_MAX);
        String normalizedEmail = EmailValidation.require(email);

        userRepository.findByUsername(normalizedUsername)
                .filter(user -> user.getEmail().equalsIgnoreCase(normalizedEmail))
                .filter(user -> !user.isBlocked())
                .ifPresent(this::sendResetEmail);

        return new AuthDtos.MessageResponse(GENERIC_REQUEST_MESSAGE);
    }

    @Transactional
    public void resetPassword(String rawToken, String password, String passwordConfirm) {
        if (rawToken == null || rawToken.isBlank()) {
            throw new ResponseStatusException(BAD_REQUEST, "Reset token is required");
        }
        if (password == null || !password.equals(passwordConfirm)) {
            throw new ResponseStatusException(BAD_REQUEST, "Passwords do not match");
        }
        TextValidation.bounded(
                password,
                "Password",
                ApiConstraints.PASSWORD_MIN,
                ApiConstraints.PASSWORD_MAX);

        PasswordResetToken stored = tokenRepository
                .findActiveForUpdateByTokenHash(RefreshTokenService.hashToken(rawToken.trim()))
                .orElseThrow(() -> new ResponseStatusException(BAD_REQUEST, "Invalid or expired reset link"));

        if (stored.getExpiresAt().isBefore(Instant.now())) {
            stored.setUsedAt(Instant.now());
            tokenRepository.save(stored);
            throw new ResponseStatusException(BAD_REQUEST, "Reset link has expired");
        }

        User user = userRepository.findById(stored.getUserId())
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "User not found"));

        if (user.isBlocked()) {
            stored.setUsedAt(Instant.now());
            tokenRepository.save(stored);
            throw new ResponseStatusException(BAD_REQUEST, "Invalid or expired reset link");
        }

        stored.setUsedAt(Instant.now());
        tokenRepository.save(stored);

        user.setPasswordHash(passwordEncoder.encode(password));
        userRepository.save(user);
        refreshTokenService.revokeAllForUser(user.getId());
    }

    private void sendResetEmail(User user) {
        tokenRepository.invalidateActiveTokensForUser(user.getId(), Instant.now());

        String rawToken = RefreshTokenService.newRawToken();
        PasswordResetToken entity = PasswordResetToken.builder()
                .userId(user.getId())
                .tokenHash(RefreshTokenService.hashToken(rawToken))
                .expiresAt(Instant.now().plusSeconds(authProperties.getPasswordResetExpirationHours() * 3600L))
                .build();
        tokenRepository.save(entity);

        String resetUrl = mailProperties.getBaseUrl() + "/reset-password?token=" + rawToken;
        String appResetUrl = "highsteaks://reset-password?token=" + rawToken;
        EmailTemplateService.EmailMessage message = emailTemplateService.passwordReset(
                user.getDisplayName(),
                resetUrl,
                appResetUrl,
                authProperties.getPasswordResetExpirationHours());
        mailService.sendHtml(user.getEmail(), message.subject(), message.html(), message.text());
    }
}
