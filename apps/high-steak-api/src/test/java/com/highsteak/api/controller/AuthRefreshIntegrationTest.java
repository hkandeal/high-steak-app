package com.highsteak.api.controller;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class AuthRefreshIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void loginReturnsAccessAndRefreshTokens() throws Exception {
        String suffix = String.valueOf(System.nanoTime());
        JsonNode auth = register("refresh" + suffix, "refresh" + suffix + "@test.com", "Refresh User");

        assertNotNull(auth.get("token").asText());
        assertNotNull(auth.get("refreshToken").asText());
    }

    @Test
    void refreshRotatesTokensAndKeepsSessionAlive() throws Exception {
        String suffix = String.valueOf(System.nanoTime());
        JsonNode auth = register("rotate" + suffix, "rotate" + suffix + "@test.com", "Rotate User");
        String access = auth.get("token").asText();
        String refresh = auth.get("refreshToken").asText();

        JsonNode refreshed = refresh(refresh);
        assertNotEquals(access, refreshed.get("token").asText());
        assertNotEquals(refresh, refreshed.get("refreshToken").asText());

        mockMvc.perform(get("/auth/me").header("Authorization", bearer(refreshed.get("token").asText())))
                .andExpect(status().isOk());
    }

    @Test
    void reusedRefreshTokenRevokesFamily() throws Exception {
        String suffix = String.valueOf(System.nanoTime());
        JsonNode auth = register("reuse" + suffix, "reuse" + suffix + "@test.com", "Reuse User");
        String refresh = auth.get("refreshToken").asText();

        JsonNode rotated = refresh(refresh);

        mockMvc.perform(post("/auth/refresh")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"refreshToken":"%s"}
                                """.formatted(refresh)))
                .andExpect(status().isUnauthorized());

        mockMvc.perform(post("/auth/refresh")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"refreshToken":"%s"}
                                """.formatted(rotated.get("refreshToken").asText())))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void logoutRevokesRefreshToken() throws Exception {
        String suffix = String.valueOf(System.nanoTime());
        JsonNode auth = register("logout" + suffix, "logout" + suffix + "@test.com", "Logout User");
        String refresh = auth.get("refreshToken").asText();

        mockMvc.perform(post("/auth/logout")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"refreshToken":"%s"}
                                """.formatted(refresh)))
                .andExpect(status().isNoContent());

        mockMvc.perform(post("/auth/refresh")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"refreshToken":"%s"}
                                """.formatted(refresh)))
                .andExpect(status().isUnauthorized());
    }

    private JsonNode register(String username, String email, String displayName) throws Exception {
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
        return objectMapper.readTree(result.getResponse().getContentAsString());
    }

    private JsonNode refresh(String refreshToken) throws Exception {
        MvcResult result = mockMvc.perform(post("/auth/refresh")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"refreshToken":"%s"}
                                """.formatted(refreshToken)))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString());
    }

    private String bearer(String token) {
        return "Bearer " + token;
    }
}
