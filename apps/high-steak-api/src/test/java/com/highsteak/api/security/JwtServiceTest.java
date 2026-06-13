package com.highsteak.api.security;

import com.highsteak.api.domain.Permission;
import com.highsteak.api.domain.Role;
import com.highsteak.api.domain.User;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

class JwtServiceTest {

    private JwtService jwtService;
    private static final UUID USER_ID = UUID.fromString("550e8400-e29b-41d4-a716-446655440000");

    @BeforeEach
    void setUp() {
        jwtService = new JwtService("change-me-in-production-use-at-least-32-characters!!", 3600000);
    }

    @Test
    void generatedTokenContainsUserProfileClaims() {
        User user = User.builder()
                .id(USER_ID)
                .username("Carboy")
                .email("eng.greenbaret@gmail.com")
                .displayName("Hossam Kandel")
                .passwordHash("hash")
                .role(moderatorRole())
                .build();
        UserPrincipal principal = new UserPrincipal(user);

        String token = jwtService.generateToken(principal);

        assertEquals("Carboy", jwtService.extractUsername(token));
        assertEquals(USER_ID, jwtService.extractUserId(token));
        assertEquals("eng.greenbaret@gmail.com", jwtService.extractEmail(token));
        assertEquals("Hossam Kandel", jwtService.extractDisplayName(token));
        assertEquals(List.of("MODERATOR"), jwtService.extractRoles(token));
        List<String> scopes = jwtService.extractScopes(token);
        assertTrue(scopes.contains("posts:moderate"));
        assertTrue(scopes.contains("posts:delete:any"));
    }

    private Role moderatorRole() {
        Set<Permission> permissions = new LinkedHashSet<>();
        permissions.add(permission("posts:moderate"));
        permissions.add(permission("posts:delete:any"));
        permissions.add(permission("posts:write"));
        return Role.builder().id(2L).name("MODERATOR").permissions(permissions).build();
    }

    private Permission permission(String scope) {
        String[] parts = scope.split(":");
        String resource = parts[0];
        String action = parts[1];
        String qualifier = parts.length > 2 ? parts[2] : null;
        return Permission.builder().scope(scope).resource(resource).action(action).qualifier(qualifier).build();
    }
}
