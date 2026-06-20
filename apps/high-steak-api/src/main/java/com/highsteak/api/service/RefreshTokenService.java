package com.highsteak.api.service;

import com.highsteak.api.domain.RefreshToken;
import com.highsteak.api.domain.User;
import com.highsteak.api.dto.AuthDtos;
import com.highsteak.api.repository.RefreshTokenRepository;
import com.highsteak.api.repository.UserRepository;
import com.highsteak.api.security.JwtService;
import com.highsteak.api.security.UserPrincipal;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Instant;
import java.util.Base64;
import java.util.HexFormat;
import java.util.UUID;

import static org.springframework.http.HttpStatus.UNAUTHORIZED;

@Service
@RequiredArgsConstructor
public class RefreshTokenService {

    private static final int TOKEN_BYTES = 32;
    private static final SecureRandom SECURE_RANDOM = new SecureRandom();

    private final RefreshTokenRepository refreshTokenRepository;
    private final UserRepository userRepository;
    private final JwtService jwtService;
    private final RefreshTokenRevocationService refreshTokenRevocationService;

    @Value("${app.jwt.refresh-expiration-ms}")
    private long refreshExpirationMs;

    @Transactional
    public AuthDtos.AuthResponse issueSession(User user) {
        User loaded = userRepository.findByIdWithRoleAndPermissions(user.getId()).orElse(user);
        UserPrincipal principal = new UserPrincipal(loaded);
        String accessToken = jwtService.generateToken(principal);
        String refreshToken = issueRefreshToken(loaded);
        return new AuthDtos.AuthResponse(accessToken, refreshToken);
    }

    @Transactional
    public AuthDtos.AuthResponse refresh(String rawRefreshToken) {
        if (rawRefreshToken == null || rawRefreshToken.isBlank()) {
            throw new ResponseStatusException(UNAUTHORIZED, "Refresh token is required");
        }

        String tokenHash = hash(rawRefreshToken);
        RefreshToken stored = refreshTokenRepository.findByTokenHash(tokenHash)
                .orElseThrow(() -> new ResponseStatusException(UNAUTHORIZED, "Invalid refresh token"));

        if (stored.getRevokedAt() != null) {
            refreshTokenRevocationService.revokeFamily(stored.getFamilyId());
            throw new ResponseStatusException(UNAUTHORIZED, "Invalid refresh token");
        }

        if (stored.getExpiresAt().isBefore(Instant.now())) {
            stored.setRevokedAt(Instant.now());
            refreshTokenRepository.save(stored);
            throw new ResponseStatusException(UNAUTHORIZED, "Refresh token expired");
        }

        User user = userRepository.findByIdWithRoleAndPermissions(stored.getUser().getId())
                .orElseThrow(() -> new ResponseStatusException(UNAUTHORIZED, "Invalid refresh token"));

        if (user.isBlocked()) {
            refreshTokenRevocationService.revokeAllForUser(user.getId());
            throw new ResponseStatusException(UNAUTHORIZED, "Account is blocked");
        }

        if (!user.isEmailVerified()) {
            refreshTokenRevocationService.revokeAllForUser(user.getId());
            throw new ResponseStatusException(UNAUTHORIZED, "Please verify your email before logging in");
        }

        stored.setRevokedAt(Instant.now());
        refreshTokenRepository.save(stored);

        UserPrincipal principal = new UserPrincipal(user);
        String accessToken = jwtService.generateToken(principal);
        String nextRefreshToken = issueRefreshTokenInFamily(user, stored.getFamilyId());
        return new AuthDtos.AuthResponse(accessToken, nextRefreshToken);
    }

    @Transactional
    public void revoke(String rawRefreshToken) {
        if (rawRefreshToken == null || rawRefreshToken.isBlank()) {
            return;
        }
        refreshTokenRepository.findByTokenHash(hash(rawRefreshToken)).ifPresent(token -> {
            token.setRevokedAt(Instant.now());
            refreshTokenRepository.save(token);
        });
    }

    @Transactional
    public void revokeAllForUser(UUID userId) {
        refreshTokenRevocationService.revokeAllForUser(userId);
    }

    private String issueRefreshToken(User user) {
        return issueRefreshTokenInFamily(user, UUID.randomUUID());
    }

    private String issueRefreshTokenInFamily(User user, UUID familyId) {
        String raw = generateRawToken();
        RefreshToken entity = RefreshToken.builder()
                .user(user)
                .tokenHash(hash(raw))
                .familyId(familyId)
                .expiresAt(Instant.now().plusMillis(refreshExpirationMs))
                .build();
        refreshTokenRepository.save(entity);
        return raw;
    }

    private static String generateRawToken() {
        byte[] bytes = new byte[TOKEN_BYTES];
        SECURE_RANDOM.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    public static String newRawToken() {
        return generateRawToken();
    }

    public static String hashToken(String rawToken) {
        return hash(rawToken);
    }

    static String hash(String rawToken) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hashed = digest.digest(rawToken.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(hashed);
        } catch (NoSuchAlgorithmException ex) {
            throw new IllegalStateException("SHA-256 not available", ex);
        }
    }
}
