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
import org.springframework.test.web.servlet.request.MockMultipartHttpServletRequestBuilder;

import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class SteakPostImageOrderIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void newUploadCanBeCoverWhenEditing() throws Exception {
        String suffix = UUID.randomUUID().toString().substring(0, 8);
        String token = register("cover" + suffix, "cover" + suffix + "@test.com", "Cover Tester");

        UUID postId = createPostWithImages(token, imageFile("first.jpg", "first".getBytes()));
        String existingUrl = fetchPost(token, postId).get("imageUrls").get(0).asText();

        MockMultipartFile coverUpload = imageFile("cover.jpg", "cover-bytes".getBytes());
        mockMvc.perform(multipart("/posts/" + postId)
                        .file(coverUpload)
                        .param("title", "Steak photos")
                        .param("rating", "5")
                        .param("imageOrder", "__new__:0")
                        .param("imageOrder", existingUrl)
                        .header("Authorization", bearer(token))
                        .with(request -> {
                            request.setMethod("PATCH");
                            return request;
                        }))
                .andExpect(status().isOk());

        JsonNode after = fetchPost(token, postId);
        assertEquals(2, after.get("imageUrls").size());
        assertTrue(after.get("imageUrls").get(0).asText().startsWith("/uploads/"));
        assertEquals(existingUrl, after.get("imageUrls").get(1).asText());
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
        return objectMapper.readTree(result.getResponse().getContentAsString()).get("token").asText();
    }

    private UUID createPostWithImages(String token, MockMultipartFile... files) throws Exception {
        MockMultipartHttpServletRequestBuilder builder = multipart("/posts");
        for (MockMultipartFile file : files) {
            builder = builder.file(file);
        }
        builder.param("title", "Steak photos")
                .param("rating", "5")
                .header("Authorization", bearer(token));
        MvcResult result = mockMvc.perform(builder).andExpect(status().isCreated()).andReturn();
        return UUID.fromString(objectMapper.readTree(result.getResponse().getContentAsString()).get("id").asText());
    }

    private JsonNode fetchPost(String token, UUID postId) throws Exception {
        MvcResult result = mockMvc.perform(get("/posts/" + postId).header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString());
    }

    private String bearer(String token) {
        return "Bearer " + token;
    }

    private MockMultipartFile imageFile(String filename, byte[] bytes) {
        return new MockMultipartFile("images", filename, "image/jpeg", bytes);
    }
}
