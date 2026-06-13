package com.highsteak.api.controller;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import static org.hamcrest.Matchers.is;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class AuthAvailabilityIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void checkUsernameRejectsLeadingDigit() throws Exception {
        mockMvc.perform(get("/auth/check-username").param("username", "1chef"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.available", is(false)))
                .andExpect(jsonPath("$.message", is("Username must not start with a number")));
    }

    @Test
    void checkUsernameRejectsInvalidCharacters() throws Exception {
        mockMvc.perform(get("/auth/check-username").param("username", "chef@grill"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.available", is(false)));
    }

    @Test
    void checkUsernameReportsAvailableForValidHandle() throws Exception {
        mockMvc.perform(get("/auth/check-username").param("username", "new_grill_master"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.available", is(true)));
    }

    @Test
    void checkEmailRejectsInvalidFormat() throws Exception {
        mockMvc.perform(get("/auth/check-email").param("email", "not-an-email"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.available", is(false)));
    }

    @Test
    void registerRejectsInvalidUsername() throws Exception {
        mockMvc.perform(post("/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "username": "9starts-with-number",
                                  "email": "chef@example.com",
                                  "password": "password123",
                                  "displayName": "Chef"
                                }
                                """))
                .andExpect(status().isBadRequest());
    }
}
