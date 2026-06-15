package com.highsteak.api.dto;

import java.time.Instant;
import java.util.UUID;

public final class SubscriptionDtos {

    private SubscriptionDtos() {}

    public record UserPublicProfile(
            UUID id,
            String username,
            String displayName,
            String avatarUrl,
            long postCount,
            boolean subscribed,
            Boolean blocked,
            String role
    ) {}

    public record SubscriptionSummary(
            UserPublicProfile user,
            Instant subscribedAt
    ) {}
}
