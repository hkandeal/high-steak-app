package com.highsteak.api.security;

import java.util.Optional;
import java.util.UUID;

public interface ResourceOwnerResolver {
    String resource();

    Optional<UUID> findOwnerId(UUID resourceId);
}
