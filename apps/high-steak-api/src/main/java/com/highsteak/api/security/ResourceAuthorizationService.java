package com.highsteak.api.security;

import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service("resourceAuth")
public class ResourceAuthorizationService {

    private final Map<String, ResourceOwnerResolver> resolversByResource;

    public ResourceAuthorizationService(List<ResourceOwnerResolver> resolvers) {
        this.resolversByResource = resolvers.stream()
                .collect(Collectors.toMap(ResourceOwnerResolver::resource, Function.identity()));
    }

    public boolean can(
            String resource,
            UUID resourceId,
            String ownAction,
            String anyAction,
            Authentication authentication) {
        if (authentication == null || !authentication.isAuthenticated()) {
            return false;
        }
        String anyScope = ResourceAuthSupport.scope(resource, anyAction, "any");
        if (ResourceAuthSupport.hasAuthority(authentication, anyScope)) {
            return true;
        }
        String ownScope = ResourceAuthSupport.scope(resource, ownAction, "own");
        if (!ResourceAuthSupport.hasAuthority(authentication, ownScope)) {
            return false;
        }
        ResourceOwnerResolver resolver = resolversByResource.get(resource);
        if (resolver == null) {
            return false;
        }
        UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
        return resolver.findOwnerId(resourceId)
                .map(ownerId -> ownerId.equals(principal.getId()))
                .orElse(false);
    }
}
