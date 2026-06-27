package com.highsteak.api.repository;

import com.highsteak.api.domain.Place;
import com.highsteak.api.domain.PlaceProvider;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;
import java.util.UUID;

public interface PlaceRepository extends JpaRepository<Place, UUID> {

    Optional<Place> findByProviderAndProviderPlaceId(PlaceProvider provider, String providerPlaceId);

    @Query(value = """
            SELECT
                p.id AS place_id,
                p.name AS place_name,
                p.formatted_address,
                p.latitude,
                p.longitude,
                p.provider_photo_name AS provider_photo_name,
                CAST(ROUND(6371000 * ACOS(LEAST(1.0, GREATEST(-1.0,
                    COS(RADIANS(:lat)) * COS(RADIANS(p.latitude))
                        * COS(RADIANS(p.longitude) - RADIANS(:lng))
                    + SIN(RADIANS(:lat)) * SIN(RADIANS(p.latitude))
                )))) AS SIGNED) AS distance_m,
                COUNT(sp.id) AS post_count,
                AVG(sp.rating) AS avg_rating
            FROM places p
            INNER JOIN steak_posts sp ON sp.place_id = p.id
            WHERE sp.hidden = false
              AND sp.visibility = 'PUBLIC'
              AND p.latitude BETWEEN :minLat AND :maxLat
              AND p.longitude BETWEEN :minLng AND :maxLng
            GROUP BY p.id, p.name, p.formatted_address, p.latitude, p.longitude, p.provider_photo_name
            HAVING 6371000 * ACOS(LEAST(1.0, GREATEST(-1.0,
                COS(RADIANS(:lat)) * COS(RADIANS(p.latitude))
                    * COS(RADIANS(p.longitude) - RADIANS(:lng))
                + SIN(RADIANS(:lat)) * SIN(RADIANS(p.latitude))
            ))) <= :radiusM
            ORDER BY distance_m
            LIMIT :limit OFFSET :offset
            """, nativeQuery = true)
    java.util.List<PlaceNearbyProjection> findNearbyWithPosts(
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
            SELECT COUNT(*) FROM (
                SELECT p.id
                FROM places p
                INNER JOIN steak_posts sp ON sp.place_id = p.id
                WHERE sp.hidden = false
                  AND sp.visibility = 'PUBLIC'
                  AND p.latitude BETWEEN :minLat AND :maxLat
                  AND p.longitude BETWEEN :minLng AND :maxLng
                GROUP BY p.id, p.latitude, p.longitude
                HAVING 6371000 * ACOS(LEAST(1.0, GREATEST(-1.0,
                    COS(RADIANS(:lat)) * COS(RADIANS(p.latitude))
                        * COS(RADIANS(p.longitude) - RADIANS(:lng))
                    + SIN(RADIANS(:lat)) * SIN(RADIANS(p.latitude))
                ))) <= :radiusM
            ) nearby
            """, nativeQuery = true)
    long countNearbyWithPosts(
            @Param("lat") double lat,
            @Param("lng") double lng,
            @Param("minLat") double minLat,
            @Param("maxLat") double maxLat,
            @Param("minLng") double minLng,
            @Param("maxLng") double maxLng,
            @Param("radiusM") int radiusM);

    interface PlaceNearbyProjection {
        UUID getPlaceId();

        String getPlaceName();

        String getFormattedAddress();

        java.math.BigDecimal getLatitude();

        java.math.BigDecimal getLongitude();

        long getDistanceM();

        long getPostCount();

        Double getAvgRating();

        String getProviderPhotoName();
    }
}
