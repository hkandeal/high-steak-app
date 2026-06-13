package com.highsteak.api.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

public final class PostDtos {

    private PostDtos() {}

    public record AuthorSummary(
            UUID id,
            String displayName
    ) {}

    public record ReviewTagSummary(
            UUID id,
            String label,
            String sentiment
    ) {}

    public record ReviewTagCatalog(
            List<ReviewTagSummary> positive,
            List<ReviewTagSummary> negative
    ) {}

    public record PostResponse(
            UUID id,
            String title,
            String comment,
            int rating,
            List<String> imageUrls,
            String restaurantName,
            String restaurantLocation,
            Instant createdAt,
            boolean hidden,
            AuthorSummary author,
            List<ReviewTagSummary> tags
    ) {}

    public record CommentResponse(
            UUID id,
            String body,
            Instant createdAt,
            AuthorSummary author
    ) {}

    public record CreateCommentRequest(
            @NotBlank @Size(max = 2000) String body
    ) {}
}
