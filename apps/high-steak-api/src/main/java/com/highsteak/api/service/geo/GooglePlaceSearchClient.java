package com.highsteak.api.service.geo;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.highsteak.api.config.GeoProperties;
import com.highsteak.api.dto.PlaceDtos;
import com.highsteak.api.domain.PlaceProvider;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@Component
@RequiredArgsConstructor
public class GooglePlaceSearchClient {

    private static final Logger log = LoggerFactory.getLogger(GooglePlaceSearchClient.class);
    private static final String AUTOCOMPLETE_URL = "https://places.googleapis.com/v1/places:autocomplete";
    private static final String PLACE_DETAILS_URL = "https://places.googleapis.com/v1/places/";
    private static final String PHOTO_MEDIA_URL = "https://places.googleapis.com/v1/";

    public record PhotoMedia(byte[] bytes, MediaType contentType) {}

    private final GeoProperties geoProperties;
    private final ObjectMapper objectMapper;
    private final RestClient restClient = RestClient.create();

    public List<PlaceDtos.PlaceSuggestion> autocomplete(String query, Double latitude, Double longitude) {
        if (!isEnabled() || query == null || query.isBlank()) {
            return List.of();
        }
        try {
            var body = objectMapper.createObjectNode();
            body.put("input", query.trim());
            if (latitude != null && longitude != null) {
                var bias = body.putObject("locationBias").putObject("circle");
                bias.putObject("center").put("latitude", latitude).put("longitude", longitude);
                bias.put("radius", 50_000.0);
            }

            String response = restClient.post()
                    .uri(AUTOCOMPLETE_URL)
                    .header("X-Goog-Api-Key", geoProperties.getGoogle().getApiKey())
                    .header(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_JSON_VALUE)
                    .body(objectMapper.writeValueAsString(body))
                    .retrieve()
                    .body(String.class);

            return parseSuggestions(response);
        } catch (Exception ex) {
            log.warn("Google Places autocomplete failed: {}", ex.getMessage());
            return List.of();
        }
    }

    public Optional<PlaceDtos.PlaceSuggestion> fetchPlaceDetails(String providerPlaceId) {
        if (!isEnabled() || providerPlaceId == null || providerPlaceId.isBlank()) {
            return Optional.empty();
        }
        try {
            String encodedId = java.net.URLEncoder.encode(providerPlaceId, java.nio.charset.StandardCharsets.UTF_8);
            String response = restClient.get()
                    .uri(PLACE_DETAILS_URL + encodedId)
                    .header("X-Goog-Api-Key", geoProperties.getGoogle().getApiKey())
                    .header("X-Goog-FieldMask", "id,displayName,formattedAddress,location,addressComponents,photos")
                    .retrieve()
                    .body(String.class);

            return parsePlaceDetails(response);
        } catch (Exception ex) {
            log.warn("Google Place details failed for {}: {}", providerPlaceId, ex.getMessage());
            return Optional.empty();
        }
    }

    public Optional<PhotoMedia> fetchPhotoMedia(String photoResourceName, int maxPx) {
        if (!isEnabled() || photoResourceName == null || photoResourceName.isBlank()) {
            return Optional.empty();
        }
        try {
            String mediaResponse = restClient.get()
                    .uri(PHOTO_MEDIA_URL + photoResourceName + "/media?maxHeightPx=" + maxPx + "&skipHttpRedirect=true")
                    .header("X-Goog-Api-Key", geoProperties.getGoogle().getApiKey())
                    .retrieve()
                    .body(String.class);

            String photoUri = objectMapper.readTree(mediaResponse).path("photoUri").asText(null);
            if (photoUri == null || photoUri.isBlank()) {
                return Optional.empty();
            }

            return Optional.ofNullable(restClient.get()
                    .uri(photoUri)
                    .exchange((request, response) -> {
                        if (!response.getStatusCode().is2xxSuccessful() || response.getBody() == null) {
                            return null;
                        }
                        MediaType contentType = response.getHeaders().getContentType();
                        byte[] bytes = response.getBody().readAllBytes();
                        return new PhotoMedia(bytes, contentType != null ? contentType : MediaType.IMAGE_JPEG);
                    }));
        } catch (Exception ex) {
            log.warn("Google Place photo failed for {}: {}", photoResourceName, ex.getMessage());
            return Optional.empty();
        }
    }

    private boolean isEnabled() {
        return geoProperties.getGoogle().isEnabled()
                && geoProperties.getGoogle().getApiKey() != null
                && !geoProperties.getGoogle().getApiKey().isBlank();
    }

    private List<PlaceDtos.PlaceSuggestion> parseSuggestions(String response) throws Exception {
        JsonNode root = objectMapper.readTree(response);
        JsonNode suggestions = root.path("suggestions");
        if (!suggestions.isArray()) {
            return List.of();
        }
        List<PlaceDtos.PlaceSuggestion> results = new ArrayList<>();
        for (JsonNode item : suggestions) {
            JsonNode prediction = item.path("placePrediction");
            if (prediction.isMissingNode()) {
                continue;
            }
            String placeId = prediction.path("placeId").asText(null);
            String text = prediction.path("text").path("text").asText(null);
            if (placeId == null || text == null) {
                continue;
            }
            results.add(new PlaceDtos.PlaceSuggestion(
                    PlaceProvider.google,
                    placeId,
                    text,
                    null,
                    null,
                    null,
                    null,
                    null));
        }
        return results;
    }

    private Optional<PlaceDtos.PlaceSuggestion> parsePlaceDetails(String response) throws Exception {
        JsonNode root = objectMapper.readTree(response);
        String placeId = root.path("id").asText(null);
        String name = root.path("displayName").path("text").asText(null);
        String formattedAddress = root.path("formattedAddress").asText(null);
        JsonNode location = root.path("location");
        if (placeId == null || name == null || location.isMissingNode()) {
            return Optional.empty();
        }
        BigDecimal lat = location.path("latitude").decimalValue();
        BigDecimal lng = location.path("longitude").decimalValue();
        String photoName = null;
        JsonNode photos = root.path("photos");
        if (photos.isArray() && !photos.isEmpty()) {
            photoName = photos.get(0).path("name").asText(null);
        }
        return Optional.of(new PlaceDtos.PlaceSuggestion(
                PlaceProvider.google,
                placeId,
                name,
                formattedAddress,
                lat,
                lng,
                photoName,
                null));
    }
}
