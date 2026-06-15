package com.highsteak.api.controller;

import com.highsteak.api.dto.AuthDtos;
import com.highsteak.api.dto.PageDtos;
import com.highsteak.api.service.UserAdminService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class UserAdminControllerIntegrationTest {

    private static final UUID USER_ID = UUID.fromString("00000000-0000-0000-0000-000000000002");

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private UserAdminService userAdminService;

    private AuthDtos.AdminUserSummary sampleUser() {
        return new AuthDtos.AdminUserSummary(
                USER_ID,
                "chef",
                "chef@example.com",
                "Chef",
                null,
                "MODERATOR",
                false);
    }

    @Test
    void listUsersRequiresAuthentication() throws Exception {
        mockMvc.perform(get("/users"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @WithMockUser(authorities = {"users:read"})
    void listUsersReturnsPaginatedAdminSummariesWithRole() throws Exception {
        when(userAdminService.listUsers(isNull(), eq(0), eq(20))).thenReturn(
                new PageDtos.PageResponse<>(List.of(sampleUser()), 0, 20, 1, 1));

        mockMvc.perform(get("/users"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content[0].role").value("MODERATOR"))
                .andExpect(jsonPath("$.content[0].blocked").value(false))
                .andExpect(jsonPath("$.totalElements").value(1));
    }

    @Test
    @WithMockUser(authorities = {"users:read"})
    void listUsersAcceptsSearchAndPaginationParams() throws Exception {
        when(userAdminService.listUsers(eq("chef"), eq(1), eq(10))).thenReturn(
                new PageDtos.PageResponse<>(List.of(), 1, 10, 0, 0));

        mockMvc.perform(get("/users").param("q", "chef").param("page", "1").param("size", "10"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.page").value(1))
                .andExpect(jsonPath("$.size").value(10));
    }

    @Test
    @WithMockUser(authorities = {"posts:read"})
    void listUsersForbiddenWithoutReadScope() throws Exception {
        mockMvc.perform(get("/users"))
                .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(authorities = {"users:block"})
    void setUserBlockedReturnsUpdatedUser() throws Exception {
        AuthDtos.AdminUserSummary blocked = new AuthDtos.AdminUserSummary(
                USER_ID, "chef", "chef@example.com", "Chef", null, "USER", true);
        when(userAdminService.setUserBlocked(eq(USER_ID), eq(true), any())).thenReturn(blocked);

        mockMvc.perform(patch("/users/{id}/blocked", USER_ID)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"blocked\":true}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.blocked").value(true));
    }

    @Test
    @WithMockUser(authorities = {"users:read"})
    void setUserBlockedForbiddenWithoutBlockScope() throws Exception {
        mockMvc.perform(patch("/users/{id}/blocked", USER_ID)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"blocked\":true}"))
                .andExpect(status().isForbidden());
    }
}
