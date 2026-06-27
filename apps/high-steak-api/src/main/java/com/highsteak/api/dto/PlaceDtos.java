package com.highsteak.api.dto;

import com.highsteak.api.domain.CoverImageSource;
import com.highsteak.api.domain.LocationPrecision;
import com.highsteak.api.domain.PlaceProvider;
import com.highsteak.api.validation.ApiConstraints;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

public final class PlaceDtos {

    private PlaceDtos() {}

    public record PlaceSummary(
            UUID id,
            PlaceProvider provider,
            String name,
            String formattedAddress,
            BigDecimal latitude,
            BigDecimal longitude,
            LocationPrecision locationPrecision,
            String previewPhotoUrl,
            CoverImageSource previewPhotoSource
    ) {}

    public record PlaceSuggestion(
            PlaceProvider provider,
            String providerPlaceId,
            String name,
            String formattedAddress,
            BigDecimal latitude,
            BigDecimal longitude,
            String providerPhotoName,
            String previewPhotoUrl
    ) {}

    public record AutocompleteResponse(
            List<PlaceSuggestion> suggestions
    ) {}

    public record ResolvePlaceRequest(
            @NotNull PlaceProvider provider,
            @NotBlank @Size(max = 255) String providerPlaceId,
            @Size(max = ApiConstraints.RESTAURANT_NAME_MAX) String name,
            @DecimalMin("-90") @DecimalMax("90") BigDecimal latitude,
            @DecimalMin("-180") @DecimalMax("180") BigDecimal longitude,
            @Size(max = ApiConstraints.RESTAURANT_LOCATION_MAX) String formattedAddress,
            @Size(max = 120) String locality,
            @Size(max = 120) String adminArea,
            @Size(min = 2, max = 2) String countryCode
    ) {}

    public record PlaceNearbySummary(
            UUID id,
            String name,
            String formattedAddress,
            BigDecimal latitude,
            BigDecimal longitude,
            long distanceM,
            long postCount,
            Double avgRating,
            String coverImageUrl,
            CoverImageSource coverImageSource
    ) {}
}
