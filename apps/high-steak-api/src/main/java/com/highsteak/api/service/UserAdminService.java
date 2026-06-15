package com.highsteak.api.service;

import com.highsteak.api.domain.Role;
import com.highsteak.api.domain.User;
import com.highsteak.api.dto.AuthDtos;
import com.highsteak.api.dto.PageDtos;
import com.highsteak.api.repository.RoleRepository;
import com.highsteak.api.repository.UserRepository;
import com.highsteak.api.security.UserPrincipal;
import com.highsteak.api.validation.TextValidation;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.UUID;

import static org.springframework.http.HttpStatus.BAD_REQUEST;
import static org.springframework.http.HttpStatus.FORBIDDEN;
import static org.springframework.http.HttpStatus.NOT_FOUND;

@Service
@RequiredArgsConstructor
public class UserAdminService {

    private static final int DEFAULT_PAGE_SIZE = 20;
    private static final int MAX_PAGE_SIZE = 50;

    private final UserRepository userRepository;
    private final RoleRepository roleRepository;

    @Transactional(readOnly = true)
    public PageDtos.PageResponse<AuthDtos.AdminUserSummary> listUsers(String query, int page, int size) {
        int pageSize = Math.min(Math.max(size, 1), MAX_PAGE_SIZE);
        int pageIndex = Math.max(page, 0);
        String normalizedQuery = normalizeQuery(query);

        Pageable pageable = PageRequest.of(pageIndex, pageSize);
        Page<User> users = userRepository.searchAdminUsers(normalizedQuery, pageable);

        return new PageDtos.PageResponse<>(
                users.getContent().stream()
                        .map(user -> userRepository.findByIdWithRoleAndPermissions(user.getId()).orElse(user))
                        .map(this::toAdminSummary)
                        .toList(),
                users.getNumber(),
                users.getSize(),
                users.getTotalElements(),
                users.getTotalPages());
    }

    @Transactional
    public AuthDtos.AdminUserSummary updateUserRole(UUID userId, String roleName, UserPrincipal actor) {
        if (actor.getId().equals(userId)) {
            throw new ResponseStatusException(BAD_REQUEST, "You cannot change your own role");
        }
        if (!"USER".equals(roleName) && !"MODERATOR".equals(roleName)) {
            throw new ResponseStatusException(BAD_REQUEST, "Only USER and MODERATOR roles can be assigned");
        }
        User user = userRepository.findByIdWithRoleAndPermissions(userId)
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "User not found"));
        if ("ADMIN".equals(user.getRole().getName())) {
            throw new ResponseStatusException(FORBIDDEN, "Cannot change an admin account");
        }
        Role role = roleRepository.findByName(roleName)
                .orElseThrow(() -> new ResponseStatusException(BAD_REQUEST, "Unknown role: " + roleName));
        user.setRole(role);
        user = userRepository.save(user);
        user = userRepository.findByIdWithRoleAndPermissions(user.getId()).orElse(user);
        return toAdminSummary(user);
    }

    @Transactional
    public AuthDtos.AdminUserSummary setUserBlocked(UUID userId, boolean blocked, UserPrincipal actor) {
        if (actor.getId().equals(userId)) {
            throw new ResponseStatusException(BAD_REQUEST, "You cannot block your own account");
        }
        User user = userRepository.findByIdWithRoleAndPermissions(userId)
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "User not found"));

        if (!actor.hasScope("users:manage")) {
            String targetRole = user.getRole().getName();
            if ("ADMIN".equals(targetRole) || "MODERATOR".equals(targetRole)) {
                throw new ResponseStatusException(FORBIDDEN, "Cannot block staff accounts");
            }
        }

        user.setBlocked(blocked);
        user = userRepository.save(user);
        return toAdminSummary(user);
    }

    private String normalizeQuery(String query) {
        if (query == null || query.isBlank()) {
            return null;
        }
        return TextValidation.bounded(query.trim(), "Search query", 0, 100);
    }

    private AuthDtos.AdminUserSummary toAdminSummary(User user) {
        return new AuthDtos.AdminUserSummary(
                user.getId(),
                user.getUsername(),
                user.getEmail(),
                user.getDisplayName(),
                user.getAvatarUrl(),
                user.getRole().getName(),
                user.isBlocked());
    }
}
