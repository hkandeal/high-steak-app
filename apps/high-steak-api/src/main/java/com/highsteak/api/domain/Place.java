package com.highsteak.api.domain;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "places")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Place {

    @Id
    @JdbcTypeCode(SqlTypes.VARCHAR)
    @Column(columnDefinition = "CHAR(36)", nullable = false, updatable = false, length = 36)
    private UUID id;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 32)
    private PlaceProvider provider;

    @Column(name = "provider_place_id", nullable = false)
    private String providerPlaceId;

    @Column(nullable = false, length = 120)
    private String name;

    @Column(name = "formatted_address", length = 255)
    private String formattedAddress;

    @Column(length = 120)
    private String locality;

    @Column(name = "admin_area", length = 120)
    private String adminArea;

    @Column(name = "country_code", length = 2)
    private String countryCode;

    @Column(nullable = false, precision = 9, scale = 6)
    private BigDecimal latitude;

    @Column(nullable = false, precision = 9, scale = 6)
    private BigDecimal longitude;

    @Column(name = "provider_photo_name", length = 512)
    private String providerPhotoName;

    @Enumerated(EnumType.STRING)
    @Column(name = "location_precision", nullable = false, length = 16)
    @Builder.Default
    private LocationPrecision locationPrecision = LocationPrecision.EXACT;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @PrePersist
    void onCreate() {
        if (id == null) {
            id = UUID.randomUUID();
        }
        Instant now = Instant.now();
        if (createdAt == null) {
            createdAt = now;
        }
        if (updatedAt == null) {
            updatedAt = now;
        }
    }

    @PreUpdate
    void onUpdate() {
        updatedAt = Instant.now();
    }
}
