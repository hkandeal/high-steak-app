package com.highsteak.api.repository;

import com.highsteak.api.domain.UserSubscription;
import com.highsteak.api.domain.UserSubscriptionId;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Set;
import java.util.UUID;

public interface UserSubscriptionRepository extends JpaRepository<UserSubscription, UserSubscriptionId> {

    List<UserSubscription> findByIdSubscriberIdOrderByCreatedAtDesc(UUID subscriberId);

    boolean existsByIdSubscriberIdAndIdTargetUserId(UUID subscriberId, UUID targetUserId);

    @Query("""
            SELECT s.id.targetUserId FROM UserSubscription s
            WHERE s.id.subscriberId = :subscriberId
            """)
    Set<UUID> findTargetUserIdsBySubscriberId(@Param("subscriberId") UUID subscriberId);
}
