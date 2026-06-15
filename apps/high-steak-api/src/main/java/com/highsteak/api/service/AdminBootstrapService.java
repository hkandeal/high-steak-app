package com.highsteak.api.service;

import com.highsteak.api.config.AdminBootstrapProperties;
import com.highsteak.api.domain.Role;
import com.highsteak.api.domain.User;
import com.highsteak.api.repository.RoleRepository;
import com.highsteak.api.repository.UserRepository;
import com.highsteak.api.validation.EmailValidation;
import com.highsteak.api.validation.TextValidation;
import com.highsteak.api.validation.ApiConstraints;
import com.highsteak.api.validation.UsernameValidation;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import static org.springframework.http.HttpStatus.NOT_FOUND;

@Service
@RequiredArgsConstructor
@Slf4j
public class AdminBootstrapService {

    private final AdminBootstrapProperties properties;
    private final UserRepository userRepository;
    private final RoleRepository roleRepository;
    private final PasswordEncoder passwordEncoder;

    @Transactional
    public void bootstrapAdminIfNeeded() {
        if (!properties.isEnabled()) {
            log.info("Admin bootstrap disabled");
            return;
        }

        if (userRepository.existsByRole_Name("ADMIN")) {
            log.debug("Admin user already exists — skipping bootstrap");
            return;
        }

        if (userRepository.existsByUsername(properties.getUsername())) {
            log.warn("Bootstrap skipped: username '{}' already exists but no ADMIN role holder found",
                    properties.getUsername());
            return;
        }

        String username = UsernameValidation.require(properties.getUsername());
        String email = EmailValidation.require(properties.getEmail());
        String displayName = TextValidation.bounded(
                properties.getDisplayName().trim(),
                "Display name",
                ApiConstraints.DISPLAY_NAME_MIN,
                ApiConstraints.DISPLAY_NAME_MAX);
        TextValidation.bounded(
                properties.getPassword(),
                "Password",
                ApiConstraints.PASSWORD_MIN,
                ApiConstraints.PASSWORD_MAX);

        Role adminRole = roleRepository.findByNameWithPermissions("ADMIN")
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "ADMIN role not configured"));

        User admin = User.builder()
                .username(username)
                .email(email)
                .displayName(displayName)
                .passwordHash(passwordEncoder.encode(properties.getPassword()))
                .role(adminRole)
                .build();

        userRepository.save(admin);
        log.info("Bootstrapped admin user '{}'", username);
    }
}
