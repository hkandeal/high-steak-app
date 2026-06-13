package com.highsteak.api.controller;

import com.highsteak.api.dto.AuthDtos;
import com.highsteak.api.security.UserPrincipal;
import com.highsteak.api.service.AuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    @PostMapping("/register")
    @ResponseStatus(HttpStatus.CREATED)
    public AuthDtos.AuthResponse register(@Valid @RequestBody AuthDtos.RegisterRequest request) {
        return authService.register(request);
    }

    @PostMapping("/login")
    public AuthDtos.AuthResponse login(@Valid @RequestBody AuthDtos.LoginRequest request) {
        return authService.login(request);
    }

    @GetMapping("/check-username")
    public AuthDtos.AvailabilityResponse checkUsername(@RequestParam String username) {
        return authService.checkUsernameAvailability(username);
    }

    @GetMapping("/check-email")
    public AuthDtos.AvailabilityResponse checkEmailAvailability(@RequestParam String email) {
        return authService.checkEmailAvailability(email);
    }

    @GetMapping("/me")
    public AuthDtos.UserSummary me(@AuthenticationPrincipal UserPrincipal principal) {
        return authService.getCurrentUser(principal);
    }

    @PatchMapping(value = "/me", consumes = MediaType.APPLICATION_JSON_VALUE)
    public AuthDtos.UpdateProfileResponse updateProfileJson(
            @AuthenticationPrincipal UserPrincipal principal,
            @Valid @RequestBody AuthDtos.UpdateProfileRequest request) {
        return authService.updateProfile(principal, request.displayName(), request.email(), null);
    }

    @PatchMapping(value = "/me", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public AuthDtos.UpdateProfileResponse updateProfileMultipart(
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestParam(required = false) String displayName,
            @RequestParam(required = false) String email,
            @RequestParam(required = false) MultipartFile avatar) {
        return authService.updateProfile(principal, displayName, email, avatar);
    }
}
