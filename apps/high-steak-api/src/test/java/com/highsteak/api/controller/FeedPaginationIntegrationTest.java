package com.highsteak.api.controller;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class FeedPaginationIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void feedAndCommentsPaginateByPageAndSize() throws Exception {
        String suffix = UUID.randomUUID().toString().substring(0, 8);
        String authorToken = register("pager" + suffix, "pager" + suffix + "@test.com", "Pager");
        String readerToken = register("reader" + suffix, "reader" + suffix + "@test.com", "Reader");

        long feedCountBefore = feedTotalElements(readerToken);

        UUID postId = null;
        for (int i = 0; i < 3; i++) {
            UUID created = createPost(authorToken, "Steak " + suffix + " " + i);
            if (i == 0) {
                postId = created;
            }
        }

        long feedCountAfter = feedCountBefore + 3;

        mockMvc.perform(get("/posts").param("page", "0").param("size", "2")
                        .header("Authorization", bearer(readerToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.page").value(0))
                .andExpect(jsonPath("$.size").value(2))
                .andExpect(jsonPath("$.totalElements").value((int) feedCountAfter))
                .andExpect(jsonPath("$.content.length()").value(2));

        MvcResult pageOne = mockMvc.perform(get("/posts").param("page", "1").param("size", "2")
                        .header("Authorization", bearer(readerToken)))
                .andExpect(status().isOk())
                .andReturn();
        JsonNode pageOneContent = objectMapper.readTree(pageOne.getResponse().getContentAsString()).get("content");
        assertTrue(pageOneContent.size() >= 1);

        for (int i = 0; i < 3; i++) {
            mockMvc.perform(post("/posts/" + postId + "/comments")
                            .header("Authorization", bearer(readerToken))
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("{\"body\":\"Comment " + i + "\"}"))
                    .andExpect(status().isCreated());
        }

        mockMvc.perform(get("/posts/" + postId + "/comments").param("page", "0").param("size", "2")
                        .header("Authorization", bearer(readerToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalElements").value(3))
                .andExpect(jsonPath("$.content.length()").value(2))
                .andExpect(jsonPath("$.content[0].body").value("Comment 2"));

        MvcResult pageTwo = mockMvc.perform(get("/posts/" + postId + "/comments")
                        .param("page", "1")
                        .param("size", "2")
                        .header("Authorization", bearer(readerToken)))
                .andExpect(status().isOk())
                .andReturn();
        JsonNode comments = objectMapper.readTree(pageTwo.getResponse().getContentAsString()).get("content");
        assertEquals(1, comments.size());
        assertTrue(comments.get(0).get("body").asText().startsWith("Comment "));
    }

    private long feedTotalElements(String token) throws Exception {
        MvcResult result = mockMvc.perform(get("/posts").param("size", "1")
                        .header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString()).get("totalElements").asLong();
    }

    private String register(String username, String email, String displayName) throws Exception {
        MvcResult result = mockMvc.perform(post("/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "username": "%s",
                                  "email": "%s",
                                  "password": "Password123!",
                                  "displayName": "%s"
                                }
                                """.formatted(username, email, displayName)))
                .andExpect(status().isCreated())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString()).get("token").asText();
    }

    private UUID createPost(String token, String title) throws Exception {
        MockMultipartFile image = new MockMultipartFile(
                "images", "steak.jpg", "image/jpeg", "image-bytes".getBytes());
        MvcResult result = mockMvc.perform(multipart("/posts")
                        .file(image)
                        .param("title", title)
                        .param("comment", "Nice")
                        .param("rating", "5")
                        .header("Authorization", bearer(token)))
                .andExpect(status().isCreated())
                .andReturn();
        return UUID.fromString(
                objectMapper.readTree(result.getResponse().getContentAsString()).get("id").asText());
    }

    private static String bearer(String token) {
        return "Bearer " + token;
    }
}
