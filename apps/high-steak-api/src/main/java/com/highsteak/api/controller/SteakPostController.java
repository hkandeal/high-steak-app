package com.highsteak.api.controller;

import com.highsteak.api.dto.PostDtos;
import com.highsteak.api.security.UserPrincipal;
import com.highsteak.api.service.ReviewTagService;
import com.highsteak.api.service.SteakPostService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/posts")
@RequiredArgsConstructor
public class SteakPostController {

    private final SteakPostService steakPostService;
    private final ReviewTagService reviewTagService;

    @GetMapping("/review-tags")
    @PreAuthorize("hasAuthority('posts:read')")
    public PostDtos.ReviewTagCatalog getReviewTags() {
        return reviewTagService.getCatalog();
    }

    @GetMapping
    @PreAuthorize("hasAuthority('posts:read')")
    public List<PostDtos.PostResponse> getFeed() {
        return steakPostService.getFeed();
    }

    @GetMapping("/mine")
    @PreAuthorize("hasAuthority('posts:read:own')")
    public List<PostDtos.PostResponse> getMyPosts(@AuthenticationPrincipal UserPrincipal principal) {
        return steakPostService.getMyPosts(principal);
    }

    @GetMapping("/hidden")
    @PreAuthorize("hasAuthority('posts:moderate')")
    public List<PostDtos.PostResponse> getHiddenPosts() {
        return steakPostService.getHiddenPosts();
    }

    @GetMapping("/following")
    @PreAuthorize("hasAuthority('subscriptions:read')")
    public List<PostDtos.PostResponse> getFollowingFeed(@AuthenticationPrincipal UserPrincipal principal) {
        return steakPostService.getFollowingFeed(principal);
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAuthority('posts:read')")
    public PostDtos.PostResponse getPost(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable UUID id) {
        return steakPostService.getPost(id, principal);
    }

    @PostMapping(consumes = "multipart/form-data")
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize("hasAuthority('posts:write')")
    public PostDtos.PostResponse createPost(
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestParam String title,
            @RequestParam(required = false) String comment,
            @RequestParam int rating,
            @RequestParam(required = false) String restaurantName,
            @RequestParam(required = false) String restaurantLocation,
            @RequestParam(required = false) String visibility,
            @RequestParam("images") MultipartFile[] images,
            @RequestParam(required = false) List<UUID> tagIds) {
        return steakPostService.createPost(
                principal, title, comment, rating, restaurantName, restaurantLocation,
                visibility, images, tagIds);
    }

    @PatchMapping(path = "/{id}", consumes = "multipart/form-data")
    @PreAuthorize("hasAuthority('posts:write')")
    public PostDtos.PostResponse updatePost(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable UUID id,
            @RequestParam String title,
            @RequestParam(required = false) String comment,
            @RequestParam int rating,
            @RequestParam(required = false) String restaurantName,
            @RequestParam(required = false) String restaurantLocation,
            @RequestParam(required = false) String visibility,
            @RequestParam(required = false) List<String> keepImageUrls,
            @RequestParam(required = false) MultipartFile[] images,
            @RequestParam(required = false) List<UUID> tagIds) {
        return steakPostService.updatePost(
                principal, id, title, comment, rating, restaurantName, restaurantLocation,
                visibility, keepImageUrls, images, tagIds);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @PreAuthorize("@resourceAuth.can('posts', #id, 'delete', 'delete', authentication)")
    public void deletePost(@PathVariable UUID id) {
        steakPostService.deletePost(id);
    }

    @PatchMapping("/{id}/hide")
    @PreAuthorize("hasAuthority('posts:moderate')")
    public PostDtos.PostResponse hidePost(@PathVariable UUID id) {
        return steakPostService.hidePost(id);
    }
}
