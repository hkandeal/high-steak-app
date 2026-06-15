package com.highsteak.api.dto;

import com.highsteak.api.validation.ApiConstraints;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.util.UUID;

public final class AuthDtos {

    private AuthDtos() {}

    public record RegisterRequest(
            @NotBlank @Size(min = ApiConstraints.USERNAME_MIN, max = ApiConstraints.USERNAME_MAX) String username,
            @NotBlank @Email @Size(max = ApiConstraints.EMAIL_MAX) String email,
            @NotBlank @Size(min = ApiConstraints.PASSWORD_MIN, max = ApiConstraints.PASSWORD_MAX) String password,
            @NotBlank @Size(min = ApiConstraints.DISPLAY_NAME_MIN, max = ApiConstraints.DISPLAY_NAME_MAX) String displayName
    ) {}

    public record LoginRequest(
            @NotBlank @Size(max = ApiConstraints.USERNAME_MAX) String username,
            @NotBlank @Size(max = ApiConstraints.PASSWORD_MAX) String password
    ) {}

    public record AuthResponse(
            String token
    ) {}

    public record UserSummary(
            UUID id,
            String username,
            String email,
            String displayName,
            String avatarUrl
    ) {}

    public record AdminUserSummary(
            UUID id,
            String username,
            String email,
            String displayName,
            String avatarUrl,
            String role,
            boolean blocked
    ) {}

    public record UpdateUserBlockedRequest(
            boolean blocked
    ) {}

    public record UpdateUserRoleRequest(
            @NotBlank String role
    ) {}

    public record UpdateProfileRequest(
            @Size(min = ApiConstraints.DISPLAY_NAME_MIN, max = ApiConstraints.DISPLAY_NAME_MAX) String displayName,
            @Email @Size(max = ApiConstraints.EMAIL_MAX) String email
    ) {}

    public record UpdateProfileResponse(
            String token,
            UserSummary user
    ) {}

    public record AvailabilityResponse(
            boolean available,
            String message
    ) {}
}
