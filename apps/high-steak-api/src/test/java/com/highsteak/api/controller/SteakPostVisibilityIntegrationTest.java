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
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class SteakPostVisibilityIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private RoleRepository roleRepository;

    @Test
    void followersOnlyPostVisibilityRules() throws Exception {
        String suffix = UUID.randomUUID().toString().substring(0, 8);
        String authorToken = register("author" + suffix, "author" + suffix + "@test.com", "Author");
        String followerToken = register("follower" + suffix, "follower" + suffix + "@test.com", "Follower");
        String strangerToken = register("stranger" + suffix, "stranger" + suffix + "@test.com", "Stranger");

        UUID authorId = userIdForUsername("author" + suffix);
        UUID postId = createPost(authorToken, "Secret steak", "FOLLOWERS_ONLY");

        subscribe(followerToken, authorId);

        assertFalse(feedContainsPost(authorToken, postId, "/posts"));
        assertTrue(feedContainsPost(followerToken, postId, "/posts/following"));
        assertFalse(profileContainsPost(strangerToken, authorId, postId));
        assertTrue(profileContainsPost(followerToken, authorId, postId));
        assertTrue(profileContainsPost(authorToken, authorId, postId));

        mockMvc.perform(get("/posts/" + postId).header("Authorization", bearer(strangerToken)))
                .andExpect(status().isNotFound());
        mockMvc.perform(get("/posts/" + postId).header("Authorization", bearer(followerToken)))
                .andExpect(status().isOk());
        mockMvc.perform(get("/posts/" + postId + "/comments").header("Authorization", bearer(strangerToken)))
                .andExpect(status().isNotFound());
        mockMvc.perform(get("/posts/" + postId + "/comments").header("Authorization", bearer(followerToken)))
                .andExpect(status().isOk());

        String moderatorToken = promoteToModeratorAndLogin("mod" + suffix, "mod" + suffix + "@test.com", "Mod");
        mockMvc.perform(get("/posts/" + postId).header("Authorization", bearer(moderatorToken)))
                .andExpect(status().isOk());

        UUID publicPostId = createPost(authorToken, "Public steak", "PUBLIC");
        String imageUrl = fetchPost(authorToken, publicPostId).get("imageUrls").get(0).asText();
        mockMvc.perform(multipart("/posts/" + publicPostId)
                        .param("title", "Now followers only")
                        .param("rating", "4")
                        .param("visibility", "FOLLOWERS_ONLY")
                        .param("keepImageUrls", imageUrl)
                        .header("Authorization", bearer(authorToken))
                        .with(request -> {
                            request.setMethod("PATCH");
                            return request;
                        }))
                .andExpect(status().isOk());
        assertFalse(feedContainsPost(authorToken, publicPostId, "/posts"));
    }

    @Test
    void profilePostCountReflectsVisiblePosts() throws Exception {
        String suffix = UUID.randomUUID().toString().substring(0, 8);
        String authorToken = register("countauthor" + suffix, "countauthor" + suffix + "@test.com", "Author");
        String strangerToken = register("countstranger" + suffix, "countstranger" + suffix + "@test.com", "Stranger");

        UUID authorId = userIdForUsername("countauthor" + suffix);
        createPost(authorToken, "Public one", "PUBLIC");
        createPost(authorToken, "Private one", "FOLLOWERS_ONLY");

        JsonNode strangerProfile = fetchProfile(strangerToken, authorId);
        assertEquals(1, strangerProfile.get("postCount").asInt());

        JsonNode authorProfile = fetchProfile(authorToken, authorId);
        assertEquals(2, authorProfile.get("postCount").asInt());
    }

    private String register(String username, String email, String displayName) throws Exception {
        MvcResult result = mockMvc.perform(post("/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "username": "%s",
                                  "email": "%s",
                                  "password": "password123",
                                  "displayName": "%s"
                                }
                                """.formatted(username, email, displayName)))
                .andExpect(status().isCreated())
                .andReturn();
        return readToken(result);
    }

    private String login(String username) throws Exception {
        MvcResult result = mockMvc.perform(post("/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "username": "%s",
                                  "password": "password123"
                                }
                                """.formatted(username)))
                .andExpect(status().isOk())
                .andReturn();
        return readToken(result);
    }

    private String promoteToModeratorAndLogin(String username, String email, String displayName) throws Exception {
        register(username, email, displayName);
        User user = userRepository.findByUsername(username).orElseThrow();
        user.setRole(roleRepository.findByNameWithPermissions("MODERATOR").orElseThrow());
        userRepository.save(user);
        return login(username);
    }

    private UUID userIdForUsername(String username) {
        return userRepository.findByUsername(username).orElseThrow().getId();
    }

    private UUID createPost(String token, String title, String visibility) throws Exception {
        MvcResult result = mockMvc.perform(multipart("/posts")
                        .file(imageFile())
                        .param("title", title)
                        .param("rating", "5")
                        .param("visibility", visibility)
                        .header("Authorization", bearer(token)))
                .andExpect(status().isCreated())
                .andReturn();
        return UUID.fromString(objectMapper.readTree(result.getResponse().getContentAsString()).get("id").asText());
    }

    private void subscribe(String token, UUID targetUserId) throws Exception {
        mockMvc.perform(post("/subscriptions/" + targetUserId).header("Authorization", bearer(token)))
                .andExpect(status().isCreated());
    }

    private boolean feedContainsPost(String token, UUID postId, String path) throws Exception {
        MvcResult result = mockMvc.perform(get(path).header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andReturn();
        JsonNode body = objectMapper.readTree(result.getResponse().getContentAsString());
        JsonNode posts = body.get("content");
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

    private boolean profileContainsPost(String token, UUID userId, UUID postId) throws Exception {
        MvcResult result = mockMvc.perform(get("/users/" + userId + "/posts").header("Authorization", bearer(token)))
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

    private JsonNode fetchPost(String token, UUID postId) throws Exception {
        MvcResult result = mockMvc.perform(get("/posts/" + postId).header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString());
    }

    private JsonNode fetchProfile(String token, UUID userId) throws Exception {
        MvcResult result = mockMvc.perform(get("/users/" + userId).header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString());
    }

    private String readToken(MvcResult result) throws Exception {
        return objectMapper.readTree(result.getResponse().getContentAsString()).get("token").asText();
    }

    private String bearer(String token) {
        return "Bearer " + token;
    }

    private MockMultipartFile imageFile() {
        return new MockMultipartFile("images", "steak.jpg", "image/jpeg", "image-bytes".getBytes());
    }
}
