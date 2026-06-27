package com.highsteak.api.dto;

import com.highsteak.api.domain.PostVisibility;
import com.highsteak.api.validation.ApiConstraints;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

public final class PostDtos {

    private PostDtos() {}

    public record AuthorSummary(
            UUID id,
            String displayName,
            String avatarUrl,
            String avatarThumbnailUrl,
            Boolean subscribed
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
            PlaceDtos.PlaceSummary place,
            Instant createdAt,
            boolean hidden,
            String moderationReason,
            java.time.Instant moderationRestoredAt,
            PostVisibility visibility,
            AuthorSummary author,
            List<ReviewTagSummary> tags,
            boolean bookmarked
    ) {}

    public record HidePostRequest(
            @Size(max = ApiConstraints.MODERATION_REASON_MAX) String reason
    ) {}

    public record CommentResponse(
            UUID id,
            String body,
            Instant createdAt,
            AuthorSummary author
    ) {}

    public record CreateCommentRequest(
            @NotBlank @Size(max = ApiConstraints.COMMENT_BODY_MAX) String body
    ) {}

    public record UpdateCommentRequest(
            @NotBlank @Size(max = ApiConstraints.COMMENT_BODY_MAX) String body
    ) {}
}
