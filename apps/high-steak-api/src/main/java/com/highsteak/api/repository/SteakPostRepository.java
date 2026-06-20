package com.highsteak.api.repository;

import com.highsteak.api.domain.PostVisibility;
import com.highsteak.api.domain.SteakPost;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface SteakPostRepository extends JpaRepository<SteakPost, UUID> {

    @EntityGraph(attributePaths = {"user", "images", "reviewTags", "reviewTags.tag"})
    Page<SteakPost> findByHiddenFalseAndVisibilityOrderByCreatedAtDesc(
            PostVisibility visibility, Pageable pageable);

    @EntityGraph(attributePaths = {"user", "images", "reviewTags", "reviewTags.tag"})
    List<SteakPost> findByHiddenFalseAndVisibilityOrderByCreatedAtDesc(PostVisibility visibility);

    @EntityGraph(attributePaths = {"user", "images", "reviewTags", "reviewTags.tag"})
    Page<SteakPost> findByHiddenTrueOrderByCreatedAtDesc(Pageable pageable);

    @EntityGraph(attributePaths = {"user", "images", "reviewTags", "reviewTags.tag"})
    List<SteakPost> findByHiddenTrueOrderByCreatedAtDesc();

    @EntityGraph(attributePaths = {"user", "images", "reviewTags", "reviewTags.tag"})
    Page<SteakPost> findByUserIdOrderByCreatedAtDesc(UUID userId, Pageable pageable);

    @EntityGraph(attributePaths = {"user", "images", "reviewTags", "reviewTags.tag"})
    List<SteakPost> findByUserIdOrderByCreatedAtDesc(UUID userId);

    @EntityGraph(attributePaths = {"user", "images", "reviewTags", "reviewTags.tag"})
    @Query("""
            SELECT p FROM SteakPost p
            WHERE p.user.id = :userId
              AND (p.hidden = true OR p.moderationRestoredAt IS NOT NULL)
            ORDER BY p.createdAt DESC
            """)
    List<SteakPost> findModerationNoticesByUserId(@Param("userId") UUID userId);

    @EntityGraph(attributePaths = {"user", "images", "reviewTags", "reviewTags.tag"})
    Page<SteakPost> findByUserIdAndHiddenFalseAndVisibilityOrderByCreatedAtDesc(
            UUID userId, PostVisibility visibility, Pageable pageable);

    @EntityGraph(attributePaths = {"user", "images", "reviewTags", "reviewTags.tag"})
    List<SteakPost> findByUserIdAndHiddenFalseAndVisibilityOrderByCreatedAtDesc(
            UUID userId, PostVisibility visibility);

    @EntityGraph(attributePaths = {"user", "images", "reviewTags", "reviewTags.tag"})
    Page<SteakPost> findByUserIdInAndHiddenFalseOrderByCreatedAtDesc(
            Collection<UUID> userIds, Pageable pageable);

    @EntityGraph(attributePaths = {"user", "images", "reviewTags", "reviewTags.tag"})
    List<SteakPost> findByUserIdInAndHiddenFalseOrderByCreatedAtDesc(Collection<UUID> userIds);

    @EntityGraph(attributePaths = {"user", "images", "reviewTags", "reviewTags.tag"})
    Optional<SteakPost> findWithDetailsById(UUID id);

    @EntityGraph(attributePaths = {"user", "images", "reviewTags", "reviewTags.tag"})
    List<SteakPost> findWithDetailsByIdIn(Collection<UUID> ids);

    long countByUserIdAndHiddenFalse(UUID userId);

    long countByUserId(UUID userId);

    long countByUserIdAndHiddenFalseAndVisibility(UUID userId, PostVisibility visibility);

    @EntityGraph(attributePaths = {"user", "images", "reviewTags", "reviewTags.tag"})
    @Query("""
            SELECT p FROM SteakPost p
            WHERE p.user.id = :profileUserId
              AND p.hidden = false
              AND (
                  p.visibility = com.highsteak.api.domain.PostVisibility.PUBLIC
                  OR :viewerId = p.user.id
                  OR EXISTS (
                      SELECT 1 FROM UserSubscription s
                      WHERE s.id.subscriberId = :viewerId
                        AND s.id.targetUserId = p.user.id
                  )
              )
            ORDER BY p.createdAt DESC
            """)
    List<SteakPost> findVisiblePostsForProfile(
            @Param("profileUserId") UUID profileUserId,
            @Param("viewerId") UUID viewerId);

    @EntityGraph(attributePaths = {"user", "images", "reviewTags", "reviewTags.tag"})
    @Query("""
            SELECT p FROM SteakPost p
            WHERE p.user.id = :profileUserId
              AND p.hidden = false
              AND (
                  p.visibility = com.highsteak.api.domain.PostVisibility.PUBLIC
                  OR :viewerId = p.user.id
                  OR EXISTS (
                      SELECT 1 FROM UserSubscription s
                      WHERE s.id.subscriberId = :viewerId
                        AND s.id.targetUserId = p.user.id
                  )
              )
            ORDER BY p.createdAt DESC
            """)
    Page<SteakPost> findVisiblePostsForProfile(
            @Param("profileUserId") UUID profileUserId,
            @Param("viewerId") UUID viewerId,
            Pageable pageable);

    @Query("""
            SELECT COUNT(p) FROM SteakPost p
            WHERE p.user.id = :profileUserId
              AND p.hidden = false
              AND (
                  p.visibility = com.highsteak.api.domain.PostVisibility.PUBLIC
                  OR :viewerId = p.user.id
                  OR EXISTS (
                      SELECT 1 FROM UserSubscription s
                      WHERE s.id.subscriberId = :viewerId
                        AND s.id.targetUserId = p.user.id
                  )
              )
            """)
    long countVisiblePostsForProfile(
            @Param("profileUserId") UUID profileUserId,
            @Param("viewerId") UUID viewerId);
}
