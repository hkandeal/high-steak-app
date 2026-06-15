package com.highsteak.api.controller;

import com.highsteak.api.dto.AuthDtos;
import com.highsteak.api.dto.PageDtos;
import com.highsteak.api.security.UserPrincipal;
import com.highsteak.api.service.UserAdminService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/users")
@RequiredArgsConstructor
public class UserAdminController {

    private final UserAdminService userAdminService;

    @GetMapping
    @PreAuthorize("hasAuthority('users:read')")
    public PageDtos.PageResponse<AuthDtos.AdminUserSummary> listUsers(
            @RequestParam(required = false) String q,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return userAdminService.listUsers(q, page, size);
    }

    @PatchMapping("/{id}/role")
    @PreAuthorize("hasAuthority('users:manage')")
    public AuthDtos.AdminUserSummary updateUserRole(
            @PathVariable UUID id,
            @Valid @RequestBody AuthDtos.UpdateUserRoleRequest request,
            @AuthenticationPrincipal UserPrincipal principal) {
        return userAdminService.updateUserRole(id, request.role(), principal);
    }

    @PatchMapping("/{id}/blocked")
    @PreAuthorize("hasAuthority('users:block')")
    public AuthDtos.AdminUserSummary setUserBlocked(
            @PathVariable UUID id,
            @Valid @RequestBody AuthDtos.UpdateUserBlockedRequest request,
            @AuthenticationPrincipal UserPrincipal principal) {
        return userAdminService.setUserBlocked(id, request.blocked(), principal);
    }
}
