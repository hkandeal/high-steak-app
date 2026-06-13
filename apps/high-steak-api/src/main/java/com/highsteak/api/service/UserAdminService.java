package com.highsteak.api.service;

import com.highsteak.api.domain.Role;
import com.highsteak.api.domain.User;
import com.highsteak.api.dto.AuthDtos;
import com.highsteak.api.repository.RoleRepository;
import com.highsteak.api.repository.UserRepository;
import com.highsteak.api.security.UserPrincipal;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.UUID;

import static org.springframework.http.HttpStatus.BAD_REQUEST;
import static org.springframework.http.HttpStatus.NOT_FOUND;

@Service
@RequiredArgsConstructor
public class UserAdminService {

    private final UserRepository userRepository;
    private final RoleRepository roleRepository;
    private final AuthService authService;

    @Transactional(readOnly = true)
    public List<AuthDtos.UserSummary> listUsers() {
        return userRepository.findAll().stream()
                .map(user -> userRepository.findByIdWithRoleAndPermissions(user.getId()).orElse(user))
                .map(authService::toSummary)
                .toList();
    }

    @Transactional
    public AuthDtos.UserSummary updateUserRole(UUID userId, String roleName, UserPrincipal actor) {
        if (actor.getId().equals(userId)) {
            throw new ResponseStatusException(BAD_REQUEST, "You cannot change your own role");
        }
        Role role = roleRepository.findByName(roleName)
                .orElseThrow(() -> new ResponseStatusException(BAD_REQUEST, "Unknown role: " + roleName));
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "User not found"));
        user.setRole(role);
        user = userRepository.save(user);
        user = userRepository.findByIdWithRoleAndPermissions(user.getId()).orElse(user);
        return authService.toSummary(user);
    }
}
