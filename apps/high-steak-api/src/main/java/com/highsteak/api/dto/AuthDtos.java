package com.highsteak.api.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.util.List;
import java.util.UUID;

public final class AuthDtos {

    private AuthDtos() {}

    public record RegisterRequest(
            @NotBlank @Size(min = 3, max = 50) String username,
            @NotBlank @Email String email,
            @NotBlank @Size(min = 8, max = 100) String password,
            @NotBlank @Size(min = 2, max = 100) String displayName
    ) {}

    public record LoginRequest(
            @NotBlank String username,
            @NotBlank String password
    ) {}

    public record AuthResponse(
            String token
    ) {}

    public record UserSummary(
            UUID id,
            String username,
            String email,
            String displayName,
            String avatarUrl,
            String role,
            List<String> scopes
    ) {}

    public record UpdateUserRoleRequest(
            @NotBlank String role
    ) {}

    public record UpdateProfileRequest(
            @Size(min = 2, max = 100) String displayName,
            @Email String email
    ) {}

    public record UpdateProfileResponse(
            String token,
            UserSummary user
    ) {}
}
