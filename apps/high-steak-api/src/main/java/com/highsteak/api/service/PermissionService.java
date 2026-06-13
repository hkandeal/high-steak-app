package com.highsteak.api.service;

import com.highsteak.api.domain.Permission;
import com.highsteak.api.domain.Role;
import com.highsteak.api.domain.User;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Comparator;
import java.util.List;

@Service
public class PermissionService {

    @Transactional(readOnly = true)
    public List<String> scopesForUser(User user) {
        return scopesForRole(user.getRole());
    }

    @Transactional(readOnly = true)
    public List<String> scopesForRole(Role role) {
        if (role == null || role.getPermissions() == null) {
            return List.of();
        }
        return role.getPermissions().stream()
                .map(Permission::getScope)
                .sorted()
                .toList();
    }

    public static String scope(String resource, String action) {
        return resource + ":" + action;
    }

    public static String scope(String resource, String action, String qualifier) {
        return resource + ":" + action + ":" + qualifier;
    }
}
