package com.highsteak.api.service;

import com.highsteak.api.domain.User;
import com.highsteak.api.dto.PostDtos;
import com.highsteak.api.dto.SubscriptionDtos;
import com.highsteak.api.repository.UserRepository;
import com.highsteak.api.security.UserPrincipal;
import com.highsteak.api.validation.TextValidation;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Set;
import java.util.UUID;

import static org.springframework.http.HttpStatus.NOT_FOUND;

@Service
@RequiredArgsConstructor
public class UserDiscoveryService {

    private final UserRepository userRepository;
    private final SubscriptionService subscriptionService;
    private final SteakPostService steakPostService;

    @Transactional(readOnly = true)
    public List<SubscriptionDtos.UserPublicProfile> searchUsers(UserPrincipal principal, String query) {
        String normalized = TextValidation.requireSearchQuery(query);

        Set<UUID> subscribedIds = subscriptionService.getSubscribedUserIds(principal.getId());
        return userRepository.searchPublicUsers(normalized, principal.getId()).stream()
                .map(user -> subscriptionService.toPublicProfile(user, subscribedIds, principal.getId()))
                .toList();
    }

    @Transactional(readOnly = true)
    public SubscriptionDtos.UserPublicProfile getUserProfile(UUID userId, UserPrincipal viewer) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "User not found"));
        if (viewer == null) {
            return subscriptionService.toPublicProfile(user, Set.of(), null);
        }
        Set<UUID> subscribedIds = subscriptionService.getSubscribedUserIds(viewer.getId());
        return subscriptionService.toPublicProfile(user, subscribedIds, viewer.getId());
    }

    @Transactional(readOnly = true)
    public List<PostDtos.PostResponse> getUserPublicPosts(UUID userId, UserPrincipal viewer) {
        return steakPostService.getVisiblePostsForProfile(userId, viewer);
    }
}
