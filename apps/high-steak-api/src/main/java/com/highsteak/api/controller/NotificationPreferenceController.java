package com.highsteak.api.controller;

import com.highsteak.api.dto.NotificationDtos;
import com.highsteak.api.security.UserPrincipal;
import com.highsteak.api.service.NotificationPreferenceService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/users/me/notification-preferences")
@RequiredArgsConstructor
public class NotificationPreferenceController {

    private final NotificationPreferenceService preferenceService;

    @GetMapping
    @PreAuthorize("hasAuthority('posts:read')")
    public NotificationDtos.NotificationPreferencesResponse getPreferences(
            @AuthenticationPrincipal UserPrincipal principal) {
        return preferenceService.getPreferences(principal);
    }

    @PatchMapping
    @PreAuthorize("hasAuthority('posts:read')")
    public NotificationDtos.NotificationPreferencesResponse updatePreferences(
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestBody NotificationDtos.UpdateNotificationPreferencesRequest request) {
        return preferenceService.updatePreferences(principal, request);
    }
}
