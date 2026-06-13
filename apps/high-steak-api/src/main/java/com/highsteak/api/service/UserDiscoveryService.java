package com.highsteak.api.service;

import com.highsteak.api.domain.User;
import com.highsteak.api.dto.PostDtos;
import com.highsteak.api.dto.SubscriptionDtos;
import com.highsteak.api.repository.SteakPostRepository;
import com.highsteak.api.repository.UserRepository;
import com.highsteak.api.security.UserPrincipal;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Set;
import java.util.UUID;

import static org.springframework.http.HttpStatus.BAD_REQUEST;
import static org.springframework.http.HttpStatus.NOT_FOUND;

@Service
@RequiredArgsConstructor
public class UserDiscoveryService {

    private static final int MIN_QUERY_LENGTH = 2;

    private final UserRepository userRepository;
    private final SteakPostRepository steakPostRepository;
    private final SubscriptionService subscriptionService;
    private final SteakPostService steakPostService;

    @Transactional(readOnly = true)
    public List<SubscriptionDtos.UserPublicProfile> searchUsers(UserPrincipal principal, String query) {
        String normalized = query == null ? "" : query.trim();
        if (normalized.length() < MIN_QUERY_LENGTH) {
            throw new ResponseStatusException(BAD_REQUEST, "Search query must be at least 2 characters");
        }

        Set<UUID> subscribedIds = subscriptionService.getSubscribedUserIds(principal.getId());
        return userRepository.searchPublicUsers(normalized, principal.getId()).stream()
                .map(user -> subscriptionService.toPublicProfile(user, subscribedIds))
                .toList();
    }

    @Transactional(readOnly = true)
    public SubscriptionDtos.UserPublicProfile getUserProfile(UUID userId, UserPrincipal viewer) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "User not found"));
        if (viewer == null) {
            return subscriptionService.toPublicProfile(user, Set.of());
        }
        Set<UUID> subscribedIds = subscriptionService.getSubscribedUserIds(viewer.getId());
        return subscriptionService.toPublicProfile(user, subscribedIds);
    }

    @Transactional(readOnly = true)
    public List<PostDtos.PostResponse> getUserPublicPosts(UUID userId) {
        if (!userRepository.existsById(userId)) {
            throw new ResponseStatusException(NOT_FOUND, "User not found");
        }
        return steakPostRepository.findByUserIdAndHiddenFalseOrderByCreatedAtDesc(userId).stream()
                .map(steakPostService::toResponse)
                .toList();
    }
}
