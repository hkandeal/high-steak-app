package com.highsteak.api.security;

import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;

final class ResourceAuthSupport {

    private ResourceAuthSupport() {}

    static boolean hasAuthority(Authentication authentication, String authority) {
        return authentication.getAuthorities().stream()
                .map(GrantedAuthority::getAuthority)
                .anyMatch(authority::equals);
    }

    static String scope(String resource, String action, String qualifier) {
        return resource + ":" + action + ":" + qualifier;
    }
}
