package com.highsteak.api.service;

import com.highsteak.api.domain.UserNotificationPreference;
import com.highsteak.api.dto.NotificationDtos;
import com.highsteak.api.repository.UserNotificationPreferenceRepository;
import com.highsteak.api.security.UserPrincipal;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import static org.springframework.http.HttpStatus.NOT_FOUND;

@Service
@RequiredArgsConstructor
public class NotificationPreferenceService {

    private final UserNotificationPreferenceRepository preferenceRepository;

    @Transactional(readOnly = true)
    public NotificationDtos.NotificationPreferencesResponse getPreferences(UserPrincipal principal) {
        UserNotificationPreference prefs = preferenceRepository.findByUserId(principal.getId())
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "Preferences not found"));
        return toResponse(prefs);
    }

    @Transactional
    public NotificationDtos.NotificationPreferencesResponse updatePreferences(
            UserPrincipal principal, NotificationDtos.UpdateNotificationPreferencesRequest request) {
        UserNotificationPreference prefs = preferenceRepository.findByUserId(principal.getId())
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "Preferences not found"));

        if (request.emailEnabled() != null) {
            prefs.setEmailEnabled(request.emailEnabled());
        }
        if (request.welcomeEmail() != null) {
            prefs.setWelcomeEmail(request.welcomeEmail());
        }
        if (request.commentEmail() != null) {
            prefs.setCommentEmail(request.commentEmail());
        }
        if (request.followerEmail() != null) {
            prefs.setFollowerEmail(request.followerEmail());
        }
        if (request.moderationEmail() != null) {
            prefs.setModerationEmail(request.moderationEmail());
        }

        return toResponse(preferenceRepository.save(prefs));
    }

    private NotificationDtos.NotificationPreferencesResponse toResponse(UserNotificationPreference prefs) {
        return new NotificationDtos.NotificationPreferencesResponse(
                prefs.isEmailEnabled(),
                prefs.isWelcomeEmail(),
                prefs.isCommentEmail(),
                prefs.isFollowerEmail(),
                prefs.isModerationEmail());
    }
}
