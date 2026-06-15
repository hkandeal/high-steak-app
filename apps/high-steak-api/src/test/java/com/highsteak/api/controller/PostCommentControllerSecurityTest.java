package com.highsteak.api.controller;

import com.highsteak.api.dto.PageDtos;
import com.highsteak.api.dto.PostDtos;
import com.highsteak.api.service.PostCommentService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class PostCommentControllerSecurityTest {

    private static final UUID POST_ID = UUID.fromString("00000000-0000-0000-0000-000000000010");

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private PostCommentService commentService;

    @Test
    void listCommentsRequiresAuthentication() throws Exception {
        mockMvc.perform(get("/posts/" + POST_ID + "/comments"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @WithMockUser(authorities = {"posts:read"})
    void listCommentsAllowedWithReadScope() throws Exception {
        when(commentService.listComments(any(), eq(POST_ID), eq(0), eq(20)))
                .thenReturn(new PageDtos.PageResponse<>(List.of(), 0, 20, 0, 0));
        mockMvc.perform(get("/posts/" + POST_ID + "/comments"))
                .andExpect(status().isOk());
    }

    @Test
    void addCommentRequiresAuthentication() throws Exception {
        mockMvc.perform(post("/posts/" + POST_ID + "/comments")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"body\":\"Nice sear!\"}"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @WithMockUser(authorities = {"comments:write"})
    void addCommentAllowedWithWriteScope() throws Exception {
        when(commentService.addComment(any(), eq(POST_ID), eq("Nice sear!"))).thenReturn(sampleComment());
        mockMvc.perform(post("/posts/" + POST_ID + "/comments")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"body\":\"Nice sear!\"}"))
                .andExpect(status().isCreated());
    }

    @Test
    @WithMockUser(authorities = {"posts:read"})
    void addCommentForbiddenWithoutWriteScope() throws Exception {
        mockMvc.perform(post("/posts/" + POST_ID + "/comments")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"body\":\"Nice sear!\"}"))
                .andExpect(status().isForbidden());
    }

    private PostDtos.CommentResponse sampleComment() {
        PostDtos.AuthorSummary author = new PostDtos.AuthorSummary(
                UUID.fromString("00000000-0000-0000-0000-000000000001"),
                "Chef");
        return new PostDtos.CommentResponse(
                UUID.fromString("00000000-0000-0000-0000-000000000011"),
                "Nice sear!",
                Instant.now(),
                author);
    }
}
