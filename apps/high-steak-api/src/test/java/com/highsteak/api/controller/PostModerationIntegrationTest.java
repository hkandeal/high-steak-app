package com.highsteak.api.controller;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.highsteak.api.domain.User;
import com.highsteak.api.repository.RoleRepository;
import com.highsteak.api.repository.UserRepository;
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
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class PostModerationIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private RoleRepository roleRepository;

    @Test
    void hideWithReasonUnhideAndAuthorVisibility() throws Exception {
        String suffix = UUID.randomUUID().toString().substring(0, 8);
        String authorToken = register("author" + suffix, "author" + suffix + "@test.com", "Author");
        String strangerToken = register("stranger" + suffix, "stranger" + suffix + "@test.com", "Stranger");
        String moderatorToken = promoteToModeratorAndLogin("mod" + suffix, "mod" + suffix + "@test.com", "Mod");

        UUID authorId = userIdForUsername("author" + suffix);
        UUID postId = createPost(authorToken, "Flagged steak");

        mockMvc.perform(patch("/posts/" + postId + "/hide")
                        .header("Authorization", bearer(moderatorToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"reason\":\"Off-topic content\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.hidden").value(true))
                .andExpect(jsonPath("$.moderationReason").value("Off-topic content"));

        assertFalse(feedContainsPost(strangerToken, postId));

        mockMvc.perform(get("/posts/" + postId).header("Authorization", bearer(authorToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.hidden").value(true))
                .andExpect(jsonPath("$.moderationReason").value("Off-topic content"));

        mockMvc.perform(get("/posts/mine").header("Authorization", bearer(authorToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content[0].hidden").value(true));

        mockMvc.perform(get("/posts/mine/moderation-notices").header("Authorization", bearer(authorToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].hidden").value(true));

        mockMvc.perform(get("/users/" + authorId + "/posts").header("Authorization", bearer(authorToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content[0].hidden").value(true));

        mockMvc.perform(get("/posts/hidden").header("Authorization", bearer(moderatorToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content[0].id").value(postId.toString()));

        mockMvc.perform(patch("/posts/" + postId + "/unhide")
                        .header("Authorization", bearer(moderatorToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.hidden").value(false))
                .andExpect(jsonPath("$.moderationReason").isEmpty());

        mockMvc.perform(get("/posts/mine").header("Authorization", bearer(authorToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content[0].moderationRestoredAt").exists());

        mockMvc.perform(get("/posts/mine/moderation-notices").header("Authorization", bearer(authorToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].moderationRestoredAt").exists());

        assertTrue(feedContainsPost(strangerToken, postId));
    }

    private boolean feedContainsPost(String token, UUID postId) throws Exception {
        MvcResult result = mockMvc.perform(get("/posts").header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andReturn();
        JsonNode posts = objectMapper.readTree(result.getResponse().getContentAsString()).get("content");
        if (posts == null || !posts.isArray()) {
            return false;
        }
        for (JsonNode post : posts) {
            if (postId.toString().equals(post.get("id").asText())) {
                return true;
            }
        }
        return false;
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

    private String promoteToModeratorAndLogin(String username, String email, String displayName) throws Exception {
        register(username, email, displayName);
        User user = userRepository.findByUsername(username).orElseThrow();
        user.setRole(roleRepository.findByName("MODERATOR").orElseThrow());
        userRepository.save(user);
        MvcResult result = mockMvc.perform(post("/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"username":"%s","password":"Password123!"}
                                """.formatted(username)))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString()).get("token").asText();
    }

    private UUID userIdForUsername(String username) {
        return userRepository.findByUsername(username).orElseThrow().getId();
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
