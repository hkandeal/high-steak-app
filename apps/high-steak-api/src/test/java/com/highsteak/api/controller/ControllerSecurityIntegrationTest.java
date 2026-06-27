package com.highsteak.api.controller;

import com.highsteak.api.dto.AuthDtos;
import com.highsteak.api.domain.PostVisibility;
import com.highsteak.api.dto.PostDtos;
import com.highsteak.api.service.SteakPostService;
import com.highsteak.api.service.UserAdminService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class ControllerSecurityIntegrationTest {

    private static final UUID POST_ID = UUID.fromString("00000000-0000-0000-0000-000000000010");

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private SteakPostService steakPostService;

    @MockitoBean
    private UserAdminService userAdminService;

    @Test
    void createPostRequiresAuthentication() throws Exception {
        mockMvc.perform(multipart("/posts")
                        .file(imageFile())
                        .param("title", "Ribeye")
                        .param("rating", "5"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @WithMockUser(authorities = {"posts:write"})
    void createPostAllowedWithWriteScope() throws Exception {
        when(steakPostService.createPost(any(), anyString(), any(), anyInt(), any(), any(), any(), any(), any(), any()))
                .thenReturn(samplePost());

        mockMvc.perform(multipart("/posts")
                        .file(imageFile())
                        .param("title", "Ribeye")
                        .param("rating", "5"))
                .andExpect(status().isCreated());
    }

    @Test
    @WithMockUser(authorities = {"posts:read"})
    void createPostForbiddenWithoutWriteScope() throws Exception {
        mockMvc.perform(multipart("/posts")
                        .file(imageFile())
                        .param("title", "Ribeye")
                        .param("rating", "5"))
                .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(authorities = {"posts:write"})
    void getMyPostsForbiddenWithoutReadOwnScope() throws Exception {
        mockMvc.perform(get("/posts/mine"))
                .andExpect(status().isForbidden());
    }

    @Test
    void listUsersRequiresAuthentication() throws Exception {
        mockMvc.perform(get("/users"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @WithMockUser(authorities = {"users:read"})
    void listUsersAllowedWithReadScope() throws Exception {
        mockMvc.perform(get("/users"))
                .andExpect(status().isOk());
    }

    @Test
    @WithMockUser(authorities = {"posts:write"})
    void listUsersForbiddenWithoutReadScope() throws Exception {
        mockMvc.perform(get("/users"))
                .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(authorities = {"users:manage"})
    void updateRoleAllowedWithManageScope() throws Exception {
        mockMvc.perform(patch("/users/00000000-0000-0000-0000-000000000002/role")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"role\":\"MODERATOR\"}"))
                .andExpect(status().isOk());
    }

    @Test
    @WithMockUser(authorities = {"users:read"})
    void updateRoleForbiddenWithoutManageScope() throws Exception {
        mockMvc.perform(patch("/users/00000000-0000-0000-0000-000000000002/role")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"role\":\"MODERATOR\"}"))
                .andExpect(status().isForbidden());
    }

    private MockMultipartFile imageFile() {
        return new MockMultipartFile("images", "steak.jpg", "image/jpeg", "image-bytes".getBytes());
    }

    private PostDtos.PostResponse samplePost() {
        PostDtos.AuthorSummary author = new PostDtos.AuthorSummary(
                UUID.fromString("00000000-0000-0000-0000-000000000001"),
                "Chef",
                null,
                null,
                null);
        return new PostDtos.PostResponse(
                POST_ID, "Ribeye", "Great sear", 5, List.of("/uploads/steak.jpg"),
                null, null, null, Instant.now(), false, null, null, PostVisibility.PUBLIC, author, List.of(), false);
    }
}
