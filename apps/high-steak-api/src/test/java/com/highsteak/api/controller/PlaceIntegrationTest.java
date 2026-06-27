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
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class PlaceIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void resolveManualPlaceCreatePostAndFindNearby() throws Exception {
        String suffix = UUID.randomUUID().toString().substring(0, 8);
        String token = register("pluser" + suffix, "pluser" + suffix + "@test.com", "Place User");

        UUID placeId = resolveManualPlace(token, "Test Steakhouse " + suffix, "40.758896", "-73.985130");
        UUID postId = createPostAtPlace(token, "Tagged steak " + suffix, placeId);

        JsonNode post = getPost(token, postId);
        assertEquals(placeId.toString(), post.get("place").get("id").asText());
        assertEquals("Test Steakhouse " + suffix, post.get("restaurantName").asText());

        JsonNode nearby = getNearby(token, 40.758896, -73.985130, 50_000);
        assertTrue(nearby.get("content").isArray());
        assertFalse(nearby.get("content").isEmpty());
        assertEquals(placeId.toString(), nearby.get("content").get(0).get("id").asText());
        assertEquals(1, nearby.get("content").get(0).get("postCount").asLong());

        JsonNode placePosts = getPlacePosts(token, placeId);
        assertEquals(1, placePosts.get("totalElements").asLong());
        assertEquals(postId.toString(), placePosts.get("content").get(0).get("id").asText());
    }

    private UUID resolveManualPlace(String token, String name, String lat, String lng) throws Exception {
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
                                """.formatted(UUID.randomUUID(), name, lat, lng)))
                .andExpect(status().isOk())
                .andReturn();
        return UUID.fromString(objectMapper.readTree(result.getResponse().getContentAsString()).get("id").asText());
    }

    private UUID createPostAtPlace(String token, String title, UUID placeId) throws Exception {
        MvcResult result = mockMvc.perform(multipart("/posts")
                        .file(imageFile())
                        .param("title", title)
                        .param("rating", "5")
                        .param("placeId", placeId.toString())
                        .header("Authorization", bearer(token)))
                .andExpect(status().isCreated())
                .andReturn();
        return UUID.fromString(objectMapper.readTree(result.getResponse().getContentAsString()).get("id").asText());
    }

    private JsonNode getPost(String token, UUID postId) throws Exception {
        MvcResult result = mockMvc.perform(get("/posts/" + postId)
                        .header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString());
    }

    private JsonNode getNearby(String token, double lat, double lng, int radiusM) throws Exception {
        MvcResult result = mockMvc.perform(get("/places/nearby")
                        .param("lat", String.valueOf(lat))
                        .param("lng", String.valueOf(lng))
                        .param("radiusM", String.valueOf(radiusM))
                        .header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString());
    }

    private JsonNode getPlacePosts(String token, UUID placeId) throws Exception {
        MvcResult result = mockMvc.perform(get("/places/" + placeId + "/posts")
                        .header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString());
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
