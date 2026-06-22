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

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class EveryoneFeedIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private RoleRepository roleRepository;

    @Test
    void everyoneFeedExcludesOwnPublicPostsButShowsOthers() throws Exception {
        String suffix = UUID.randomUUID().toString().substring(0, 8);
        String authorToken = register("evauthor" + suffix, "evauthor" + suffix + "@test.com", "Author");
        String readerToken = register("evreader" + suffix, "evreader" + suffix + "@test.com", "Reader");

        UUID authorId = userIdForUsername("evauthor" + suffix);
        UUID publicPostId = createPost(authorToken, "Public steak", "PUBLIC");

        assertFalse(feedContainsPost(authorToken, publicPostId));
        assertTrue(feedContainsPost(readerToken, publicPostId));
        assertTrue(profileContainsPost(authorToken, authorId, publicPostId));
    }

    @Test
    void everyoneFeedStillExcludesFollowersOnlyPosts() throws Exception {
        String suffix = UUID.randomUUID().toString().substring(0, 8);
        String authorToken = register("evfo" + suffix, "evfo" + suffix + "@test.com", "Author");
        String readerToken = register("evfr" + suffix, "evfr" + suffix + "@test.com", "Reader");

        UUID followersOnlyPostId = createPost(authorToken, "Followers steak", "FOLLOWERS_ONLY");

        assertFalse(feedContainsPost(authorToken, followersOnlyPostId));
        assertFalse(feedContainsPost(readerToken, followersOnlyPostId));
    }

    @Test
    void moderatorEveryoneFeedExcludesOwnPosts() throws Exception {
        String suffix = UUID.randomUUID().toString().substring(0, 8);
        String authorToken = register("evma" + suffix, "evma" + suffix + "@test.com", "Author");
        String moderatorToken = promoteToModeratorAndLogin("evmm" + suffix, "evmm" + suffix + "@test.com", "Mod");

        UUID authorPostId = createPost(authorToken, "Community steak", "PUBLIC");
        UUID moderatorPostId = createPost(moderatorToken, "Mod steak", "PUBLIC");

        assertTrue(feedContainsPost(moderatorToken, authorPostId));
        assertFalse(feedContainsPost(moderatorToken, moderatorPostId));
        assertTrue(feedContainsPost(authorToken, moderatorPostId));
    }

    @Test
    void authorWithOnlyOwnPostsSeesNoOwnPostsInEveryoneFeed() throws Exception {
        String suffix = UUID.randomUUID().toString().substring(0, 8);
        String soloToken = register("evsolo" + suffix, "evsolo" + suffix + "@test.com", "Solo");
        UUID soloUserId = userIdForUsername("evsolo" + suffix);

        UUID soloPostId = createPost(soloToken, "My only steak", "PUBLIC");

        assertFalse(feedContainsPost(soloToken, soloPostId));

        MvcResult result = mockMvc.perform(get("/posts").header("Authorization", bearer(soloToken)))
                .andExpect(status().isOk())
                .andReturn();
        JsonNode content = objectMapper.readTree(result.getResponse().getContentAsString()).get("content");
        for (JsonNode post : content) {
            assertFalse(
                    soloUserId.toString().equals(post.get("author").get("id").asText()),
                    "Everyone feed must not include the viewer's own posts");
        }
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
