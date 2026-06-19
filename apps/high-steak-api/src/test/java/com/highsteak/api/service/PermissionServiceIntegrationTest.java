package com.highsteak.api.service;

import com.highsteak.api.repository.RoleRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertTrue;

@SpringBootTest
@ActiveProfiles("test")
class PermissionServiceIntegrationTest {

    @Autowired
    private PermissionService permissionService;

    @Autowired
    private RoleRepository roleRepository;

    @Test
    void userRoleHasBasePostScopesFromDatabase() {
        var role = roleRepository.findByNameWithPermissions("USER").orElseThrow();
        List<String> scopes = permissionService.scopesForRole(role);
        assertTrue(scopes.contains("posts:read"));
        assertTrue(scopes.contains("posts:write"));
        assertTrue(scopes.contains("posts:delete:own"));
        assertTrue(scopes.contains("users:discover"));
        assertTrue(scopes.contains("subscriptions:read"));
        assertTrue(scopes.contains("subscriptions:write"));
        assertTrue(scopes.contains("bookmarks:read"));
        assertTrue(scopes.contains("bookmarks:write"));
        assertTrue(scopes.contains("comments:write"));
    }

    @Test
    void moderatorRoleHasModerationAndUserListScopesFromDatabase() {
        var role = roleRepository.findByNameWithPermissions("MODERATOR").orElseThrow();
        List<String> scopes = permissionService.scopesForRole(role);
        assertTrue(scopes.contains("posts:moderate"));
        assertTrue(scopes.contains("users:read"));
        assertTrue(scopes.contains("users:block"));
    }

    @Test
    void adminRoleHasUserManagementScopesFromDatabase() {
        var role = roleRepository.findByNameWithPermissions("ADMIN").orElseThrow();
        List<String> scopes = permissionService.scopesForRole(role);
        assertTrue(scopes.contains("users:read"));
        assertTrue(scopes.contains("users:manage"));
        assertTrue(scopes.contains("posts:moderate"));
    }
}
