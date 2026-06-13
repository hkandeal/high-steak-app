package com.highsteak.api.controller;

import com.highsteak.api.dto.AuthDtos;
import com.highsteak.api.security.UserPrincipal;
import com.highsteak.api.service.UserAdminService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/users")
@RequiredArgsConstructor
public class UserAdminController {

    private final UserAdminService userAdminService;

    @GetMapping
    @PreAuthorize("hasAuthority('users:read')")
    public List<AuthDtos.UserSummary> listUsers() {
        return userAdminService.listUsers();
    }

    @PatchMapping("/{id}/role")
    @PreAuthorize("hasAuthority('users:manage')")
    public AuthDtos.UserSummary updateUserRole(
            @PathVariable UUID id,
            @Valid @RequestBody AuthDtos.UpdateUserRoleRequest request,
            @AuthenticationPrincipal UserPrincipal principal) {
        return userAdminService.updateUserRole(id, request.role(), principal);
    }
}
