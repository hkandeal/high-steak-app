package com.highsteak.api.controller;

import com.highsteak.api.dto.PageDtos;
import com.highsteak.api.dto.PostDtos;
import com.highsteak.api.service.BookmarkService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class BookmarkControllerSecurityTest {

    private static final UUID POST_ID = UUID.fromString("00000000-0000-0000-0000-000000000010");

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private BookmarkService bookmarkService;

    @Test
    void listBookmarksRequiresAuthentication() throws Exception {
        mockMvc.perform(get("/bookmarks"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @WithMockUser(authorities = {"bookmarks:read"})
    void listBookmarksAllowedWithReadScope() throws Exception {
        when(bookmarkService.listBookmarkedPosts(any(), eq(0), eq(20)))
                .thenReturn(new PageDtos.PageResponse<>(List.of(), 0, 20, 0, 0));
        mockMvc.perform(get("/bookmarks"))
                .andExpect(status().isOk());
    }

    @Test
    @WithMockUser(authorities = {"posts:read"})
    void listBookmarksForbiddenWithoutReadScope() throws Exception {
        mockMvc.perform(get("/bookmarks"))
                .andExpect(status().isForbidden());
    }

    @Test
    void bookmarkPostRequiresAuthentication() throws Exception {
        mockMvc.perform(post("/posts/" + POST_ID + "/bookmark"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @WithMockUser(authorities = {"bookmarks:write"})
    void bookmarkPostAllowedWithWriteScope() throws Exception {
        doNothing().when(bookmarkService).bookmarkPost(any(), eq(POST_ID));
        mockMvc.perform(post("/posts/" + POST_ID + "/bookmark"))
                .andExpect(status().isNoContent());
    }

    @Test
    @WithMockUser(authorities = {"bookmarks:read"})
    void bookmarkPostForbiddenWithoutWriteScope() throws Exception {
        mockMvc.perform(post("/posts/" + POST_ID + "/bookmark"))
                .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(authorities = {"bookmarks:write"})
    void unbookmarkPostAllowedWithWriteScope() throws Exception {
        doNothing().when(bookmarkService).unbookmarkPost(any(), eq(POST_ID));
        mockMvc.perform(delete("/posts/" + POST_ID + "/bookmark"))
                .andExpect(status().isNoContent());
    }
}
