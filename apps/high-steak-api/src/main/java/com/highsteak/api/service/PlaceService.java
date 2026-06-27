package com.highsteak.api.service;

import com.highsteak.api.config.GeoProperties;
import com.highsteak.api.domain.CoverImageSource;
import com.highsteak.api.domain.LocationPrecision;
import com.highsteak.api.domain.Place;
import com.highsteak.api.domain.PlaceProvider;
import com.highsteak.api.domain.PostVisibility;
import com.highsteak.api.domain.SteakPost;
import com.highsteak.api.dto.PageDtos;
import com.highsteak.api.dto.PlaceDtos;
import com.highsteak.api.dto.PostDtos;
import com.highsteak.api.repository.PlaceRepository;
import com.highsteak.api.repository.SteakPostRepository;
import com.highsteak.api.security.UserPrincipal;
import com.highsteak.api.service.geo.GooglePlaceSearchClient;
import com.highsteak.api.util.PaginationHelper;
import com.highsteak.api.validation.ApiConstraints;
import com.highsteak.api.validation.TextValidation;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.CacheControl;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.math.BigDecimal;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.TimeUnit;

import static org.springframework.http.HttpStatus.BAD_REQUEST;
import static org.springframework.http.HttpStatus.NOT_FOUND;

@Service
@RequiredArgsConstructor
public class PlaceService {

    private static final int AUTOCOMPLETE_PHOTO_ENRICH_LIMIT = 5;

    private final PlaceRepository placeRepository;
    private final SteakPostRepository steakPostRepository;
    private final SteakPostService steakPostService;
    private final GooglePlaceSearchClient googlePlaceSearchClient;
    private final GeoProperties geoProperties;

    @Transactional(readOnly = true)
    public PlaceDtos.AutocompleteResponse autocomplete(String query, Double latitude, Double longitude) {
        List<PlaceDtos.PlaceSuggestion> suggestions = googlePlaceSearchClient.autocomplete(query, latitude, longitude);
        List<PlaceDtos.PlaceSuggestion> enriched = new ArrayList<>(suggestions.size());
        for (int i = 0; i < suggestions.size(); i++) {
            PlaceDtos.PlaceSuggestion suggestion = suggestions.get(i);
            if (i < AUTOCOMPLETE_PHOTO_ENRICH_LIMIT && suggestion.provider() == PlaceProvider.google) {
                enriched.add(enrichGoogleSuggestion(suggestion));
            } else {
                enriched.add(withPreviewUrl(suggestion));
            }
        }
        return new PlaceDtos.AutocompleteResponse(enriched);
    }

    @Transactional
    public PlaceDtos.PlaceSummary resolve(PlaceDtos.ResolvePlaceRequest request) {
        PlaceDtos.PlaceSuggestion resolved = resolveSuggestion(request);

        Place place = placeRepository
                .findByProviderAndProviderPlaceId(resolved.provider(), resolved.providerPlaceId())
                .orElseGet(() -> Place.builder()
                        .provider(resolved.provider())
                        .providerPlaceId(resolved.providerPlaceId())
                        .build());

        place.setName(TextValidation.bounded(
                resolved.name(), "Place name", 1, ApiConstraints.RESTAURANT_NAME_MAX));
        place.setFormattedAddress(TextValidation.optional(
                resolved.formattedAddress(), "Address", ApiConstraints.RESTAURANT_LOCATION_MAX));
        place.setLatitude(resolved.latitude());
        place.setLongitude(resolved.longitude());
        place.setLocationPrecision(LocationPrecision.EXACT);
        if (resolved.providerPhotoName() != null && !resolved.providerPhotoName().isBlank()) {
            place.setProviderPhotoName(resolved.providerPhotoName());
        }
        place = placeRepository.save(place);
        return toSummary(place);
    }

    @Transactional(readOnly = true)
    public PlaceDtos.PlaceSummary getPlace(UUID placeId) {
        Place place = placeRepository.findById(placeId)
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "Place not found"));
        return toSummary(place);
    }

    @Transactional(readOnly = true)
    public PageDtos.PageResponse<PlaceDtos.PlaceNearbySummary> findNearby(
            double latitude,
            double longitude,
            Integer radiusM,
            int page,
            int size) {
        int effectiveRadius = normalizeRadius(radiusM);
        BoundingBox box = BoundingBox.around(latitude, longitude, effectiveRadius);
        Pageable pageable = PaginationHelper.pageable(page, size);

        List<PlaceRepository.PlaceNearbyProjection> rows = placeRepository.findNearbyWithPosts(
                latitude,
                longitude,
                box.minLat(),
                box.maxLat(),
                box.minLng(),
                box.maxLng(),
                effectiveRadius,
                pageable.getPageSize(),
                (int) pageable.getOffset());

        long total = placeRepository.countNearbyWithPosts(
                latitude,
                longitude,
                box.minLat(),
                box.maxLat(),
                box.minLng(),
                box.maxLng(),
                effectiveRadius);

        List<PlaceDtos.PlaceNearbySummary> content = rows.stream()
                .map(row -> {
                    CoverImage cover = resolveCoverImage(row.getPlaceId(), row.getProviderPhotoName());
                    return new PlaceDtos.PlaceNearbySummary(
                            row.getPlaceId(),
                            row.getPlaceName(),
                            row.getFormattedAddress(),
                            row.getLatitude(),
                            row.getLongitude(),
                            row.getDistanceM(),
                            row.getPostCount(),
                            row.getAvgRating(),
                            cover.url(),
                            cover.source());
                })
                .toList();

        int totalPages = pageable.getPageSize() == 0 ? 0 : (int) Math.ceil((double) total / pageable.getPageSize());
        return new PageDtos.PageResponse<>(
                content,
                pageable.getPageNumber(),
                pageable.getPageSize(),
                total,
                totalPages);
    }

    @Transactional(readOnly = true)
    public PageDtos.PageResponse<PostDtos.PostResponse> getPostsAtPlace(
            UUID placeId, UserPrincipal viewer, int page, int size) {
        if (!placeRepository.existsById(placeId)) {
            throw new ResponseStatusException(NOT_FOUND, "Place not found");
        }
        Pageable pageable = PaginationHelper.pageable(page, size);
        Page<SteakPost> posts = steakPostRepository.findByPlaceIdAndHiddenFalseAndVisibilityOrderByCreatedAtDesc(
                placeId, PostVisibility.PUBLIC, pageable);
        return PaginationHelper.toPageResponse(posts, post -> steakPostService.toResponse(post, viewer));
    }

    @Transactional(readOnly = true)
    public ResponseEntity<byte[]> streamProviderPhoto(UUID placeId) {
        Place place = placeRepository.findById(placeId)
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "Place not found"));
        if (place.getProviderPhotoName() == null || place.getProviderPhotoName().isBlank()) {
            throw new ResponseStatusException(NOT_FOUND, "No provider photo for place");
        }
        return streamPhotoResource(place.getProviderPhotoName());
    }

    @Transactional(readOnly = true)
    public ResponseEntity<byte[]> streamGooglePreviewPhoto(String providerPlaceId) {
        if (providerPlaceId == null || providerPlaceId.isBlank()) {
            throw new ResponseStatusException(BAD_REQUEST, "providerPlaceId is required");
        }
        String photoName = googlePlaceSearchClient.fetchPlaceDetails(providerPlaceId)
                .map(PlaceDtos.PlaceSuggestion::providerPhotoName)
                .filter(name -> name != null && !name.isBlank())
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "No Google photo for place"));
        return streamPhotoResource(photoName);
    }

    @Transactional(readOnly = true)
    public Place requirePlace(UUID placeId) {
        return placeRepository.findById(placeId)
                .orElseThrow(() -> new ResponseStatusException(BAD_REQUEST, "Place not found"));
    }

    public PlaceDtos.PlaceSummary toSummary(Place place) {
        if (place == null) {
            return null;
        }
        String previewPhotoUrl = null;
        CoverImageSource previewPhotoSource = null;
        if (place.getProviderPhotoName() != null && !place.getProviderPhotoName().isBlank()) {
            previewPhotoUrl = "/places/" + place.getId() + "/provider-photo";
            previewPhotoSource = CoverImageSource.GOOGLE;
        }
        return new PlaceDtos.PlaceSummary(
                place.getId(),
                place.getProvider(),
                place.getName(),
                place.getFormattedAddress(),
                place.getLatitude(),
                place.getLongitude(),
                place.getLocationPrecision(),
                previewPhotoUrl,
                previewPhotoSource);
    }

    public void applyPlaceSnapshot(SteakPost post, Place place) {
        post.setPlace(place);
        post.setRestaurantName(place.getName());
        post.setRestaurantLocation(place.getFormattedAddress() != null
                ? place.getFormattedAddress()
                : formatCoordinates(place));
    }

    private PlaceDtos.PlaceSuggestion resolveSuggestion(PlaceDtos.ResolvePlaceRequest request) {
        if (request.provider() == PlaceProvider.google) {
            return googlePlaceSearchClient.fetchPlaceDetails(request.providerPlaceId())
                    .orElseThrow(() -> new ResponseStatusException(BAD_REQUEST, "Could not resolve place from Google"));
        }
        if (request.provider() == PlaceProvider.manual) {
            if (request.name() == null || request.name().isBlank()) {
                throw new ResponseStatusException(BAD_REQUEST, "Place name is required");
            }
            if (request.latitude() == null || request.longitude() == null) {
                throw new ResponseStatusException(BAD_REQUEST, "Latitude and longitude are required");
            }
            validateCoordinates(request.latitude(), request.longitude());
            return new PlaceDtos.PlaceSuggestion(
                    PlaceProvider.manual,
                    request.providerPlaceId(),
                    request.name().trim(),
                    request.formattedAddress(),
                    request.latitude(),
                    request.longitude(),
                    null,
                    null);
        }
        throw new ResponseStatusException(BAD_REQUEST, "Unsupported place provider");
    }

    private PlaceDtos.PlaceSuggestion enrichGoogleSuggestion(PlaceDtos.PlaceSuggestion suggestion) {
        return googlePlaceSearchClient.fetchPlaceDetails(suggestion.providerPlaceId())
                .map(details -> withPreviewUrl(new PlaceDtos.PlaceSuggestion(
                        PlaceProvider.google,
                        suggestion.providerPlaceId(),
                        suggestion.name(),
                        details.formattedAddress() != null ? details.formattedAddress() : suggestion.formattedAddress(),
                        details.latitude() != null ? details.latitude() : suggestion.latitude(),
                        details.longitude() != null ? details.longitude() : suggestion.longitude(),
                        details.providerPhotoName(),
                        null)))
                .orElse(withPreviewUrl(suggestion));
    }

    private PlaceDtos.PlaceSuggestion withPreviewUrl(PlaceDtos.PlaceSuggestion suggestion) {
        String previewPhotoUrl = null;
        if (suggestion.provider() == PlaceProvider.google
                && suggestion.providerPhotoName() != null
                && !suggestion.providerPhotoName().isBlank()) {
            previewPhotoUrl = googlePreviewPhotoUrl(suggestion.providerPlaceId());
        }
        return new PlaceDtos.PlaceSuggestion(
                suggestion.provider(),
                suggestion.providerPlaceId(),
                suggestion.name(),
                suggestion.formattedAddress(),
                suggestion.latitude(),
                suggestion.longitude(),
                suggestion.providerPhotoName(),
                previewPhotoUrl);
    }

    private String googlePreviewPhotoUrl(String providerPlaceId) {
        return "/places/google-preview/photo?providerPlaceId="
                + URLEncoder.encode(providerPlaceId, StandardCharsets.UTF_8);
    }

    private ResponseEntity<byte[]> streamPhotoResource(String photoResourceName) {
        GooglePlaceSearchClient.PhotoMedia media = googlePlaceSearchClient
                .fetchPhotoMedia(photoResourceName, 800)
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "Provider photo unavailable"));
        return ResponseEntity.ok()
                .contentType(media.contentType())
                .cacheControl(CacheControl.maxAge(1, TimeUnit.DAYS).cachePublic())
                .body(media.bytes());
    }

    private int normalizeRadius(Integer radiusM) {
        int value = radiusM != null ? radiusM : geoProperties.getDefaultRadiusM();
        if (value <= 0) {
            throw new ResponseStatusException(BAD_REQUEST, "radiusM must be positive");
        }
        if (value > geoProperties.getMaxRadiusM()) {
            throw new ResponseStatusException(BAD_REQUEST, "radiusM exceeds maximum allowed");
        }
        return value;
    }

    private void validateCoordinates(BigDecimal latitude, BigDecimal longitude) {
        double lat = latitude.doubleValue();
        double lng = longitude.doubleValue();
        if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
            throw new ResponseStatusException(BAD_REQUEST, "Invalid coordinates");
        }
    }

    private String formatCoordinates(Place place) {
        return place.getLatitude() + ", " + place.getLongitude();
    }

    private CoverImage resolveCoverImage(UUID placeId, String providerPhotoName) {
        String postImage = steakPostRepository
                .findFirstByPlaceIdAndHiddenFalseAndVisibilityOrderByCreatedAtDesc(placeId, PostVisibility.PUBLIC)
                .flatMap(post -> post.getImages().stream().findFirst().map(image -> image.getImageUrl()))
                .orElse(null);
        if (postImage != null) {
            return new CoverImage(postImage, CoverImageSource.COMMUNITY);
        }
        if (providerPhotoName != null && !providerPhotoName.isBlank()) {
            return new CoverImage("/places/" + placeId + "/provider-photo", CoverImageSource.GOOGLE);
        }
        return new CoverImage(null, null);
    }

    private record CoverImage(String url, CoverImageSource source) {}

    private record BoundingBox(double minLat, double maxLat, double minLng, double maxLng) {
        static BoundingBox around(double lat, double lng, int radiusM) {
            double deltaLat = radiusM / 111_320.0;
            double deltaLng = radiusM / (111_320.0 * Math.cos(Math.toRadians(lat)));
            return new BoundingBox(lat - deltaLat, lat + deltaLat, lng - deltaLng, lng + deltaLng);
        }
    }
}
