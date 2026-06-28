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
    Page<SteakPost> findByHiddenFalseAndVisibilityAndUserIdNotOrderByCreatedAtDesc(
            PostVisibility visibility, UUID userId, Pageable pageable);

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

    @EntityGraph(attributePaths = {"user", "place", "images", "reviewTags", "reviewTags.tag"})
    Optional<SteakPost> findWithDetailsById(UUID id);

    @EntityGraph(attributePaths = {"user", "place", "images", "reviewTags", "reviewTags.tag"})
    Page<SteakPost> findByPlaceIdAndHiddenFalseAndVisibilityOrderByCreatedAtDesc(
            UUID placeId, PostVisibility visibility, Pageable pageable);

    @EntityGraph(attributePaths = {"user", "place", "images", "reviewTags", "reviewTags.tag"})
    @Query("""
            SELECT p FROM SteakPost p
            WHERE p.place.id = :placeId
              AND p.hidden = false
              AND (
                  p.visibility = com.highsteak.api.domain.PostVisibility.PUBLIC
                  OR p.user.id = :viewerId
                  OR EXISTS (
                      SELECT 1 FROM UserSubscription s
                      WHERE s.id.subscriberId = :viewerId
                        AND s.id.targetUserId = p.user.id
                  )
              )
            ORDER BY p.createdAt DESC
            """)
    Page<SteakPost> findVisiblePostsAtPlace(
            @Param("placeId") UUID placeId,
            @Param("viewerId") UUID viewerId,
            Pageable pageable);

    @EntityGraph(attributePaths = {"images"})
    Optional<SteakPost> findFirstByPlaceIdAndHiddenFalseAndVisibilityOrderByCreatedAtDesc(
            UUID placeId, PostVisibility visibility);

    @EntityGraph(attributePaths = {"user", "images", "reviewTags", "reviewTags.tag"})
    List<SteakPost> findWithDetailsByIdIn(Collection<UUID> ids);

    long countByUserIdAndHiddenFalse(UUID userId);

    long countByUserId(UUID userId);

    long countByUserIdAndHiddenFalseAndVisibility(UUID userId, PostVisibility visibility);

    @Query(value = """
            SELECT sp.id
            FROM steak_posts sp
            INNER JOIN places p ON p.id = sp.place_id
            WHERE sp.hidden = false
              AND p.latitude BETWEEN :minLat AND :maxLat
              AND p.longitude BETWEEN :minLng AND :maxLng
              AND 6371000 * ACOS(LEAST(1.0, GREATEST(-1.0,
                  COS(RADIANS(:lat)) * COS(RADIANS(p.latitude))
                      * COS(RADIANS(p.longitude) - RADIANS(:lng))
                  + SIN(RADIANS(:lat)) * SIN(RADIANS(p.latitude))
              ))) <= :radiusM
              AND (
                  sp.visibility = 'PUBLIC'
                  OR sp.user_id = :viewerId
                  OR EXISTS (
                      SELECT 1 FROM user_subscriptions us
                      WHERE us.subscriber_id = :viewerId
                        AND us.target_user_id = sp.user_id
                  )
              )
            ORDER BY sp.created_at DESC
            LIMIT :limit OFFSET :offset
            """, nativeQuery = true)
    List<String> findNearbyPostIds(
            @Param("viewerId") String viewerId,
            @Param("lat") double lat,
            @Param("lng") double lng,
            @Param("minLat") double minLat,
            @Param("maxLat") double maxLat,
            @Param("minLng") double minLng,
            @Param("maxLng") double maxLng,
            @Param("radiusM") int radiusM,
            @Param("limit") int limit,
            @Param("offset") int offset);

    @Query(value = """
            SELECT COUNT(*)
            FROM steak_posts sp
            INNER JOIN places p ON p.id = sp.place_id
            WHERE sp.hidden = false
              AND p.latitude BETWEEN :minLat AND :maxLat
              AND p.longitude BETWEEN :minLng AND :maxLng
              AND 6371000 * ACOS(LEAST(1.0, GREATEST(-1.0,
                  COS(RADIANS(:lat)) * COS(RADIANS(p.latitude))
                      * COS(RADIANS(p.longitude) - RADIANS(:lng))
                  + SIN(RADIANS(:lat)) * SIN(RADIANS(p.latitude))
              ))) <= :radiusM
              AND (
                  sp.visibility = 'PUBLIC'
                  OR sp.user_id = :viewerId
                  OR EXISTS (
                      SELECT 1 FROM user_subscriptions us
                      WHERE us.subscriber_id = :viewerId
                        AND us.target_user_id = sp.user_id
                  )
              )
            """, nativeQuery = true)
    long countNearbyPosts(
            @Param("viewerId") String viewerId,
            @Param("lat") double lat,
            @Param("lng") double lng,
            @Param("minLat") double minLat,
            @Param("maxLat") double maxLat,
            @Param("minLng") double minLng,
            @Param("maxLng") double maxLng,
            @Param("radiusM") int radiusM);

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
