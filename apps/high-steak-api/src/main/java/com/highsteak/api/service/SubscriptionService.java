package com.highsteak.api.service;

import com.highsteak.api.domain.PostVisibility;
import com.highsteak.api.domain.User;
import com.highsteak.api.domain.UserSubscription;
import com.highsteak.api.domain.UserSubscriptionId;
import com.highsteak.api.dto.SubscriptionDtos;
import com.highsteak.api.repository.SteakPostRepository;
import com.highsteak.api.repository.UserRepository;
import com.highsteak.api.repository.UserSubscriptionRepository;
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
public class SubscriptionService {

    private final UserSubscriptionRepository subscriptionRepository;
    private final UserRepository userRepository;
    private final SteakPostRepository steakPostRepository;

    @Transactional(readOnly = true)
    public List<SubscriptionDtos.SubscriptionSummary> listSubscriptions(UserPrincipal principal) {
        Set<UUID> subscribedIds = subscriptionRepository.findTargetUserIdsBySubscriberId(principal.getId());
        return subscriptionRepository.findByIdSubscriberIdOrderByCreatedAtDesc(principal.getId()).stream()
                .map(sub -> toSummary(sub, subscribedIds))
                .toList();
    }

    @Transactional
    public SubscriptionDtos.SubscriptionSummary subscribe(UserPrincipal principal, UUID targetUserId) {
        if (principal.getId().equals(targetUserId)) {
            throw new ResponseStatusException(BAD_REQUEST, "Cannot subscribe to yourself");
        }

        if (!userRepository.existsById(targetUserId)) {
            throw new ResponseStatusException(NOT_FOUND, "User not found");
        }

        UserSubscriptionId id = new UserSubscriptionId(principal.getId(), targetUserId);
        if (subscriptionRepository.existsById(id)) {
            throw new ResponseStatusException(org.springframework.http.HttpStatus.CONFLICT, "Already subscribed");
        }

        UserSubscription subscription = UserSubscription.builder()
                .id(id)
                .build();

        subscription = subscriptionRepository.save(subscription);
        Set<UUID> subscribedIds = subscriptionRepository.findTargetUserIdsBySubscriberId(principal.getId());
        return toSummary(subscription, subscribedIds);
    }

    @Transactional
    public void unsubscribe(UserPrincipal principal, UUID targetUserId) {
        UserSubscriptionId id = new UserSubscriptionId(principal.getId(), targetUserId);
        if (!subscriptionRepository.existsById(id)) {
            throw new ResponseStatusException(NOT_FOUND, "Subscription not found");
        }
        subscriptionRepository.deleteById(id);
    }

    @Transactional(readOnly = true)
    public Set<UUID> getSubscribedUserIds(UUID subscriberId) {
        return subscriptionRepository.findTargetUserIdsBySubscriberId(subscriberId);
    }

    @Transactional(readOnly = true)
    public SubscriptionDtos.UserPublicProfile toPublicProfile(User user, UUID viewerId) {
        Set<UUID> subscribedIds = viewerId == null
                ? Set.of()
                : subscriptionRepository.findTargetUserIdsBySubscriberId(viewerId);
        return toPublicProfile(user, subscribedIds, viewerId);
    }

    @Transactional(readOnly = true)
    public SubscriptionDtos.UserPublicProfile toPublicProfile(User user, Set<UUID> subscribedIds, UUID viewerId) {
        return new SubscriptionDtos.UserPublicProfile(
                user.getId(),
                user.getUsername(),
                user.getDisplayName(),
                user.getAvatarUrl(),
                countVisiblePosts(user.getId(), viewerId),
                subscribedIds.contains(user.getId()));
    }

    private long countVisiblePosts(UUID profileUserId, UUID viewerId) {
        if (viewerId == null) {
            return steakPostRepository.countByUserIdAndHiddenFalseAndVisibility(
                    profileUserId, PostVisibility.PUBLIC);
        }
        return steakPostRepository.countVisiblePostsForProfile(profileUserId, viewerId);
    }

    private SubscriptionDtos.SubscriptionSummary toSummary(
            UserSubscription subscription,
            Set<UUID> subscribedIds) {
        User target = userRepository.findById(subscription.getId().getTargetUserId())
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "User not found"));
        return new SubscriptionDtos.SubscriptionSummary(
                toPublicProfile(target, subscribedIds, subscription.getId().getSubscriberId()),
                subscription.getCreatedAt());
    }
}
