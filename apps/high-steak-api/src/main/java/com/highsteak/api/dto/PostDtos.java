package com.highsteak.api.dto;

import java.time.Instant;

public final class PostDtos {

    private PostDtos() {}

    public record PostResponse(
            Long id,
            String title,
            String comment,
            int rating,
            String imageUrl,
            Instant createdAt,
            AuthDtos.UserSummary author
    ) {}
}
