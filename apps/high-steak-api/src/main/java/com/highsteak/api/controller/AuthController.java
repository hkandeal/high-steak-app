package com.highsteak.api.controller;

import com.highsteak.api.dto.AuthDtos;
import com.highsteak.api.security.UserPrincipal;
import com.highsteak.api.service.AccountDeletionService;
import com.highsteak.api.service.AuthService;
import com.highsteak.api.service.PasswordResetService;
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
    private final AccountDeletionService accountDeletionService;
    private final PasswordResetService passwordResetService;

    @PostMapping("/register")
    @ResponseStatus(HttpStatus.CREATED)
    public AuthDtos.RegisterResponse register(@Valid @RequestBody AuthDtos.RegisterRequest request) {
        return authService.register(request);
    }

    @PostMapping("/verify-email")
    public AuthDtos.AuthResponse verifyEmail(@Valid @RequestBody AuthDtos.VerifyEmailRequest request) {
        return authService.verifyEmailAndLogin(request.token());
    }

    @PostMapping("/resend-verification")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void resendVerification(@Valid @RequestBody AuthDtos.ResendVerificationRequest request) {
        authService.resendVerificationEmail(request.email());
    }

    @PostMapping("/login")
    public AuthDtos.AuthResponse login(@Valid @RequestBody AuthDtos.LoginRequest request) {
        return authService.login(request);
    }

    @PostMapping("/refresh")
    public AuthDtos.AuthResponse refresh(@RequestBody(required = false) AuthDtos.RefreshRequest request) {
        String refreshToken = request != null ? request.refreshToken() : null;
        return authService.refresh(refreshToken);
    }

    @PostMapping("/logout")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void logout(@RequestBody(required = false) AuthDtos.LogoutRequest request) {
        String refreshToken = request != null ? request.refreshToken() : null;
        authService.logout(refreshToken);
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
        return authService.updateProfile(principal, request.displayName(), null);
    }

    @PatchMapping(value = "/me", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public AuthDtos.UpdateProfileResponse updateProfileMultipart(
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestParam(required = false) String displayName,
            @RequestParam(required = false) MultipartFile avatar) {
        return authService.updateProfile(principal, displayName, avatar);
    }

    @PostMapping("/request-account-deletion")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void requestAccountDeletion(@AuthenticationPrincipal UserPrincipal principal) {
        accountDeletionService.requestDeletion(principal);
    }

    @PostMapping("/confirm-account-deletion")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void confirmAccountDeletion(@Valid @RequestBody AuthDtos.ConfirmAccountDeletionRequest request) {
        accountDeletionService.confirmDeletion(request.token());
    }

    @PostMapping("/request-password-reset")
    public AuthDtos.MessageResponse requestPasswordReset(
            @Valid @RequestBody AuthDtos.RequestPasswordResetRequest request) {
        return passwordResetService.requestReset(request.username(), request.email());
    }

    @PostMapping("/reset-password")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void resetPassword(@Valid @RequestBody AuthDtos.ResetPasswordRequest request) {
        passwordResetService.resetPassword(request.token(), request.password(), request.passwordConfirm());
    }
}
