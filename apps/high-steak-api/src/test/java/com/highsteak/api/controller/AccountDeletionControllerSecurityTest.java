package com.highsteak.api.controller;

import com.highsteak.api.service.AccountDeletionService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import static org.mockito.Mockito.verify;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class AccountDeletionControllerSecurityTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private AccountDeletionService accountDeletionService;

    @Test
    void requestAccountDeletionRequiresAuthentication() throws Exception {
        mockMvc.perform(post("/auth/request-account-deletion"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @WithMockUser
    void requestAccountDeletionAllowedWhenAuthenticated() throws Exception {
        mockMvc.perform(post("/auth/request-account-deletion"))
                .andExpect(status().isNoContent());
    }

    @Test
    void confirmAccountDeletionIsPublic() throws Exception {
        mockMvc.perform(post("/auth/confirm-account-deletion")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"token\":\"deletion-token\"}"))
                .andExpect(status().isNoContent());

        verify(accountDeletionService).confirmDeletion("deletion-token");
    }

    @Test
    void confirmAccountDeletionRequiresToken() throws Exception {
        mockMvc.perform(post("/auth/confirm-account-deletion")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isBadRequest());
    }
}
