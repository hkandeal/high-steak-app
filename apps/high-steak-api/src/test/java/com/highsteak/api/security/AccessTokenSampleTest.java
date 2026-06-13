package com.highsteak.api.security;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.highsteak.api.domain.Permission;
import com.highsteak.api.domain.Role;
import com.highsteak.api.domain.User;
import org.junit.jupiter.api.Test;

import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.LinkedHashSet;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

class AccessTokenSampleTest {

    private final JwtService jwtService =
            new JwtService("change-me-in-production-use-at-least-32-characters!!", 86400000);

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Test
    void printSampleTokenWithEmbeddedUserClaims() throws Exception {
        UUID userId = UUID.fromString("a1b2c3d4-e5f6-7890-abcd-ef1234567890");
        User user = User.builder()
                .id(userId)
                .username("Carboy")
                .email("eng.greenbaret@gmail.com")
                .displayName("Hossam Kandel")
                .passwordHash("hash")
                .role(userRole())
                .build();

        String token = jwtService.generateToken(new UserPrincipal(user));
        System.out.println("\n=== Sample access token (USER) ===");
        System.out.println("Bearer " + token);
        System.out.println("Decoded payload:");
        System.out.println(objectMapper.writerWithDefaultPrettyPrinter().writeValueAsString(decodePayload(token)));
    }

    @SuppressWarnings("unchecked")
    private Map<String, Object> decodePayload(String token) throws Exception {
        String payload = token.split("\\.")[1];
        byte[] decoded = Base64.getUrlDecoder().decode(payload);
        return objectMapper.readValue(new String(decoded, StandardCharsets.UTF_8), Map.class);
    }

    private Role userRole() {
        Set<Permission> permissions = new LinkedHashSet<>();
        for (String scope : new String[] {
            "posts:read", "posts:write", "posts:read:own", "posts:delete:own"
        }) {
            String[] parts = scope.split(":");
            permissions.add(Permission.builder()
                    .scope(scope)
                    .resource(parts[0])
                    .action(parts[1])
                    .qualifier(parts.length > 2 ? parts[2] : null)
                    .build());
        }
        return Role.builder().id(1L).name("USER").permissions(permissions).build();
    }
}
