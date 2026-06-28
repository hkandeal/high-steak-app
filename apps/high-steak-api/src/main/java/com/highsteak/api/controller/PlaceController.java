package com.highsteak.api.controller;

import com.highsteak.api.dto.PageDtos;
import com.highsteak.api.dto.PlaceDtos;
import com.highsteak.api.dto.PostDtos;
import com.highsteak.api.security.UserPrincipal;
import com.highsteak.api.service.PlaceService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/places")
@RequiredArgsConstructor
public class PlaceController {

    private final PlaceService placeService;

    @GetMapping("/autocomplete")
    @PreAuthorize("hasAuthority('places:read')")
    public PlaceDtos.AutocompleteResponse autocomplete(
            @RequestParam String q,
            @RequestParam(required = false) @DecimalMin("-90") @DecimalMax("90") Double lat,
            @RequestParam(required = false) @DecimalMin("-180") @DecimalMax("180") Double lng) {
        return placeService.autocomplete(q, lat, lng);
    }

    @PostMapping("/resolve")
    @PreAuthorize("hasAuthority('places:read')")
    public PlaceDtos.PlaceSummary resolvePlace(@Valid @RequestBody PlaceDtos.ResolvePlaceRequest request) {
        return placeService.resolve(request);
    }

    @GetMapping("/nearby")
    @PreAuthorize("hasAuthority('places:read')")
    public PageDtos.PageResponse<PlaceDtos.PlaceNearbySummary> findNearby(
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestParam @DecimalMin("-90") @DecimalMax("90") double lat,
            @RequestParam @DecimalMin("-180") @DecimalMax("180") double lng,
            @RequestParam(required = false) Integer radiusM,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return placeService.findNearby(principal, lat, lng, radiusM, page, size);
    }

    @GetMapping("/google-preview/photo")
    public ResponseEntity<byte[]> getGooglePreviewPhoto(@RequestParam String providerPlaceId) {
        return placeService.streamGooglePreviewPhoto(providerPlaceId);
    }

    @GetMapping("/{placeId}")
    @PreAuthorize("hasAuthority('places:read')")
    public PlaceDtos.PlaceSummary getPlace(@PathVariable UUID placeId) {
        return placeService.getPlace(placeId);
    }

    @GetMapping("/{placeId}/posts")
    @PreAuthorize("hasAuthority('places:read')")
    public PageDtos.PageResponse<PostDtos.PostResponse> getPostsAtPlace(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable UUID placeId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return placeService.getPostsAtPlace(placeId, principal, page, size);
    }

    @GetMapping("/{placeId}/provider-photo")
    public ResponseEntity<byte[]> getProviderPhoto(@PathVariable UUID placeId) {
        return placeService.streamProviderPhoto(placeId);
    }
}
