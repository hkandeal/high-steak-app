package com.highsteak.api.controller;

import com.highsteak.api.dto.SubscriptionDtos;
import com.highsteak.api.service.SteakPostService;
import com.highsteak.api.service.SubscriptionService;
import com.highsteak.api.service.UserDiscoveryService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class SubscriptionControllerSecurityTest {

    private static final UUID TARGET_USER = UUID.fromString("00000000-0000-0000-0000-000000000002");

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private SubscriptionService subscriptionService;

    @MockitoBean
    private UserDiscoveryService userDiscoveryService;

    @MockitoBean
    private SteakPostService steakPostService;

    @Test
    void followingFeedRequiresAuthentication() throws Exception {
        mockMvc.perform(get("/posts/following"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @WithMockUser(authorities = {"subscriptions:read"})
    void followingFeedAllowedWithReadScope() throws Exception {
        when(steakPostService.getFollowingFeed(any())).thenReturn(List.of());
        mockMvc.perform(get("/posts/following"))
                .andExpect(status().isOk());
    }

    @Test
    @WithMockUser(authorities = {"posts:read"})
    void followingFeedForbiddenWithoutSubscriptionReadScope() throws Exception {
        mockMvc.perform(get("/posts/following"))
                .andExpect(status().isForbidden());
    }

    @Test
    void subscribeRequiresAuthentication() throws Exception {
        mockMvc.perform(post("/subscriptions/" + TARGET_USER))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @WithMockUser(authorities = {"subscriptions:write"})
    void subscribeAllowedWithWriteScope() throws Exception {
        when(subscriptionService.subscribe(any(), eq(TARGET_USER))).thenReturn(sampleSummary());
        mockMvc.perform(post("/subscriptions/" + TARGET_USER))
                .andExpect(status().isCreated());
    }

    @Test
    @WithMockUser(authorities = {"subscriptions:read"})
    void subscribeForbiddenWithoutWriteScope() throws Exception {
        mockMvc.perform(post("/subscriptions/" + TARGET_USER))
                .andExpect(status().isForbidden());
    }

    @Test
    void searchUsersRequiresAuthentication() throws Exception {
        mockMvc.perform(get("/users/search").param("q", "chef"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @WithMockUser(authorities = {"users:discover"})
    void searchUsersAllowedWithDiscoverScope() throws Exception {
        when(userDiscoveryService.searchUsers(any(), eq("chef"))).thenReturn(List.of());
        mockMvc.perform(get("/users/search").param("q", "chef"))
                .andExpect(status().isOk());
    }

    @Test
    @WithMockUser(authorities = {"posts:read"})
    void searchUsersForbiddenWithoutDiscoverScope() throws Exception {
        mockMvc.perform(get("/users/search").param("q", "chef"))
                .andExpect(status().isForbidden());
    }

    private SubscriptionDtos.SubscriptionSummary sampleSummary() {
        SubscriptionDtos.UserPublicProfile profile = new SubscriptionDtos.UserPublicProfile(
                TARGET_USER, "chef", "Chef", null, 0, true);
        return new SubscriptionDtos.SubscriptionSummary(profile, Instant.now());
    }
}
