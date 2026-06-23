package com.highsteak.api.service;

import com.highsteak.api.domain.Role;
import com.highsteak.api.domain.User;
import com.highsteak.api.repository.RoleRepository;
import com.highsteak.api.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.web.server.ResponseStatusException;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;

@SpringBootTest
@ActiveProfiles("test")
@TestPropertySource(properties = "app.mail.enabled=true")
class PasswordResetServiceIntegrationTest {

    @Autowired
    private PasswordResetService passwordResetService;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private RoleRepository roleRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @MockitoBean
    private MailService mailService;

    private User user;

    @BeforeEach
    void setUp() {
        userRepository.deleteAll();
        Role role = roleRepository.findByName("USER").orElseThrow();
        user = userRepository.save(User.builder()
                .username("resetuser")
                .email("reset@example.com")
                .displayName("Reset User")
                .passwordHash(passwordEncoder.encode("oldpassword1"))
                .role(role)
                .emailVerified(true)
                .build());
    }

    @Test
    void requestResetSendsEmailWhenUsernameAndEmailMatch() {
        passwordResetService.requestReset("resetuser", "reset@example.com");

        ArgumentCaptor<String> textCaptor = ArgumentCaptor.forClass(String.class);
        verify(mailService).sendHtml(eq("reset@example.com"), anyString(), anyString(), textCaptor.capture());
        assertThat(textCaptor.getValue()).contains("/reset-password?token=");
        assertThat(textCaptor.getValue()).contains("highsteaks://reset-password?token=");
    }

    @Test
    void requestResetDoesNotSendEmailWhenEmailDoesNotMatch() {
        passwordResetService.requestReset("resetuser", "other@example.com");

        verify(mailService, never()).sendHtml(anyString(), anyString(), anyString(), anyString());
    }

    @Test
    void requestResetDoesNotSendEmailForBlockedUser() {
        user.setBlocked(true);
        userRepository.save(user);

        passwordResetService.requestReset("resetuser", "reset@example.com");

        verify(mailService, never()).sendHtml(anyString(), anyString(), anyString(), anyString());
    }

    @Test
    void resetPasswordUpdatesHashAndRevokesSessions() {
        passwordResetService.requestReset("resetuser", "reset@example.com");

        ArgumentCaptor<String> textCaptor = ArgumentCaptor.forClass(String.class);
        verify(mailService).sendHtml(eq("reset@example.com"), anyString(), anyString(), textCaptor.capture());
        String token = extractToken(textCaptor.getValue());

        passwordResetService.resetPassword(token, "newpassword1", "newpassword1");

        User updated = userRepository.findByUsername("resetuser").orElseThrow();
        assertThat(passwordEncoder.matches("newpassword1", updated.getPasswordHash())).isTrue();
        assertThat(passwordEncoder.matches("oldpassword1", updated.getPasswordHash())).isFalse();
    }

    @Test
    void resetPasswordRejectsMismatchedPasswords() {
        assertThatThrownBy(() -> passwordResetService.resetPassword("token", "newpassword1", "otherpass1"))
                .isInstanceOf(ResponseStatusException.class)
                .hasMessageContaining("Passwords do not match");
    }

    @Test
    void resetPasswordRejectsInvalidToken() {
        assertThatThrownBy(() -> passwordResetService.resetPassword("bad-token", "newpassword1", "newpassword1"))
                .isInstanceOf(ResponseStatusException.class)
                .hasMessageContaining("Invalid or expired");
    }

    private static String extractToken(String emailText) {
        int start = emailText.indexOf("/reset-password?token=") + "/reset-password?token=".length();
        int end = emailText.indexOf('\n', start);
        if (end < 0) {
            end = emailText.length();
        }
        return emailText.substring(start, end).trim();
    }
}
