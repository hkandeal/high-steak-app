package com.highsteak.api.dto;

public final class NotificationDtos {

    private NotificationDtos() {}

    public record NotificationPreferencesResponse(
            boolean emailEnabled,
            boolean welcomeEmail,
            boolean commentEmail,
            boolean followerEmail,
            boolean moderationEmail) {}

    public record UpdateNotificationPreferencesRequest(
            Boolean emailEnabled,
            Boolean welcomeEmail,
            Boolean commentEmail,
            Boolean followerEmail,
            Boolean moderationEmail) {}
}
