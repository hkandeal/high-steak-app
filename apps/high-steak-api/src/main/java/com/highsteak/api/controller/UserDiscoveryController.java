package com.highsteak.api.controller;

import com.highsteak.api.dto.PostDtos;
import com.highsteak.api.dto.SubscriptionDtos;
import com.highsteak.api.security.UserPrincipal;
import com.highsteak.api.service.UserDiscoveryService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/users")
@RequiredArgsConstructor
public class UserDiscoveryController {

    private final UserDiscoveryService userDiscoveryService;

    @GetMapping("/search")
    @PreAuthorize("hasAuthority('users:discover')")
    public List<SubscriptionDtos.UserPublicProfile> searchUsers(
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestParam("q") String query) {
        return userDiscoveryService.searchUsers(principal, query);
    }

    @GetMapping("/{id}")
    public SubscriptionDtos.UserPublicProfile getUserProfile(
            @PathVariable UUID id,
            @AuthenticationPrincipal UserPrincipal principal) {
        return userDiscoveryService.getUserProfile(id, principal);
    }

    @GetMapping("/{id}/posts")
    @PreAuthorize("hasAuthority('posts:read')")
    public List<PostDtos.PostResponse> getUserPosts(
            @PathVariable UUID id,
            @AuthenticationPrincipal UserPrincipal principal) {
        return userDiscoveryService.getUserPublicPosts(id, principal);
    }
}
