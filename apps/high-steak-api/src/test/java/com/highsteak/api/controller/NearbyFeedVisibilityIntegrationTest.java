package com.highsteak.api.controller;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
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
class NearbyFeedVisibilityIntegrationTest {

    private static final double LAT = 40.758896;
    private static final double LNG = -73.985130;

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private UserRepository userRepository;

    @Test
    void nearbyFeedAndMapIncludeFollowersOnlyPostsFromFollowedAuthors() throws Exception {
        String suffix = UUID.randomUUID().toString().substring(0, 8);
        String authorToken = register("nearauthor" + suffix, "nearauthor" + suffix + "@test.com", "Author");
        String followerToken = register("nearfollower" + suffix, "nearfollower" + suffix + "@test.com", "Follower");
        String strangerToken = register("nearstranger" + suffix, "nearstranger" + suffix + "@test.com", "Stranger");

        UUID authorId = userIdForUsername("nearauthor" + suffix);
        UUID placeId = resolveManualPlace(authorToken, "Nearby Steakhouse " + suffix);
        UUID followersOnlyPostId = createPostAtPlace(
                authorToken, "Followers steak " + suffix, placeId, "FOLLOWERS_ONLY");

        assertFalse(postsNearbyContain(followerToken, followersOnlyPostId));
        assertFalse(postsNearbyContain(strangerToken, followersOnlyPostId));

        subscribe(followerToken, authorId);

        assertTrue(postsNearbyContain(followerToken, followersOnlyPostId));
        assertFalse(postsNearbyContain(strangerToken, followersOnlyPostId));

        JsonNode followerPlaces = placesNearby(followerToken);
        assertTrue(containsPlaceWithPost(followerPlaces, placeId));
        JsonNode strangerPlaces = placesNearby(strangerToken);
        assertFalse(containsPlaceWithPost(strangerPlaces, placeId));

        JsonNode followerPlacePosts = placePosts(followerToken, placeId);
        assertEquals(1, followerPlacePosts.get("totalElements").asLong());
        assertEquals(
                followersOnlyPostId.toString(),
                followerPlacePosts.get("content").get(0).get("id").asText());

        JsonNode strangerPlacePosts = placePosts(strangerToken, placeId);
        assertEquals(0, strangerPlacePosts.get("totalElements").asLong());
    }

    private boolean postsNearbyContain(String token, UUID postId) throws Exception {
        MvcResult result = mockMvc.perform(get("/posts/nearby")
                        .param("lat", String.valueOf(LAT))
                        .param("lng", String.valueOf(LNG))
                        .param("radiusM", "50000")
                        .header("Authorization", bearer(token)))
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

    private JsonNode placesNearby(String token) throws Exception {
        MvcResult result = mockMvc.perform(get("/places/nearby")
                        .param("lat", String.valueOf(LAT))
                        .param("lng", String.valueOf(LNG))
                        .param("radiusM", "50000")
                        .header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString());
    }

    private boolean containsPlaceWithPost(JsonNode placesPage, UUID placeId) {
        JsonNode places = placesPage.get("content");
        if (places == null || !places.isArray()) {
            return false;
        }
        for (JsonNode place : places) {
            if (placeId.toString().equals(place.get("id").asText()) && place.get("postCount").asLong() > 0) {
                return true;
            }
        }
        return false;
    }

    private JsonNode placePosts(String token, UUID placeId) throws Exception {
        MvcResult result = mockMvc.perform(get("/places/" + placeId + "/posts")
                        .header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString());
    }

    private UUID resolveManualPlace(String token, String name) throws Exception {
        MvcResult result = mockMvc.perform(post("/places/resolve")
                        .header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "provider": "manual",
                                  "providerPlaceId": "%s",
                                  "name": "%s",
                                  "latitude": %s,
                                  "longitude": %s,
                                  "formattedAddress": "123 Test Ave"
                                }
                                """.formatted(UUID.randomUUID(), name, LAT, LNG)))
                .andExpect(status().isOk())
                .andReturn();
        return UUID.fromString(objectMapper.readTree(result.getResponse().getContentAsString()).get("id").asText());
    }

    private UUID createPostAtPlace(String token, String title, UUID placeId, String visibility)
            throws Exception {
        MvcResult result = mockMvc.perform(multipart("/posts")
                        .file(imageFile())
                        .param("title", title)
                        .param("rating", "5")
                        .param("visibility", visibility)
                        .param("placeId", placeId.toString())
                        .header("Authorization", bearer(token)))
                .andExpect(status().isCreated())
                .andReturn();
        return UUID.fromString(objectMapper.readTree(result.getResponse().getContentAsString()).get("id").asText());
    }

    private void subscribe(String token, UUID targetUserId) throws Exception {
        mockMvc.perform(post("/subscriptions/" + targetUserId).header("Authorization", bearer(token)))
                .andExpect(status().isCreated());
    }

    private UUID userIdForUsername(String username) {
        return userRepository.findByUsername(username).orElseThrow().getId();
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
