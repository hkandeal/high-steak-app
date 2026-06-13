package com.highsteak.api.controller;

import com.highsteak.api.dto.SubscriptionDtos;
import com.highsteak.api.security.UserPrincipal;
import com.highsteak.api.service.SubscriptionService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/subscriptions")
@RequiredArgsConstructor
public class SubscriptionController {

    private final SubscriptionService subscriptionService;

    @GetMapping
    @PreAuthorize("hasAuthority('subscriptions:read')")
    public List<SubscriptionDtos.SubscriptionSummary> listSubscriptions(
            @AuthenticationPrincipal UserPrincipal principal) {
        return subscriptionService.listSubscriptions(principal);
    }

    @PostMapping("/{userId}")
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize("hasAuthority('subscriptions:write')")
    public SubscriptionDtos.SubscriptionSummary subscribe(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable UUID userId) {
        return subscriptionService.subscribe(principal, userId);
    }

    @DeleteMapping("/{userId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @PreAuthorize("hasAuthority('subscriptions:write')")
    public void unsubscribe(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable UUID userId) {
        subscriptionService.unsubscribe(principal, userId);
    }
}
