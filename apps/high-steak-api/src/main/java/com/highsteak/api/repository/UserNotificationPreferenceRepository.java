package com.highsteak.api.repository;

import com.highsteak.api.domain.UserNotificationPreference;

import java.util.Optional;
import java.util.UUID;

public interface UserNotificationPreferenceRepository
        extends org.springframework.data.jpa.repository.JpaRepository<UserNotificationPreference, UUID> {

    Optional<UserNotificationPreference> findByUserId(UUID userId);
}
