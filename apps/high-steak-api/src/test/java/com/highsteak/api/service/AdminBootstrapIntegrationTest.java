package com.highsteak.api.service;

import com.highsteak.api.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

@SpringBootTest
@ActiveProfiles("test")
@TestPropertySource(properties = "app.bootstrap.admin.enabled=true")
class AdminBootstrapIntegrationTest {

    @Autowired
    private AdminBootstrapService adminBootstrapService;

    @Autowired
    private UserRepository userRepository;

    @Test
    void bootstrapCreatesAdminWhenMissing() {
        adminBootstrapService.bootstrapAdminIfNeeded();

        assertTrue(userRepository.existsByRole_Name("ADMIN"));
        assertTrue(userRepository.existsByUsername("admin"));

        adminBootstrapService.bootstrapAdminIfNeeded();

        assertTrue(userRepository.existsByRole_Name("ADMIN"));
        assertEquals(1, userRepository.findByUsername("admin").stream().count());
    }
}
