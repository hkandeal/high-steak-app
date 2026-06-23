package com.highsteak.api.controller;

import com.highsteak.api.dto.AuthDtos;
import com.highsteak.api.service.PasswordResetService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class PasswordResetControllerSecurityTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private PasswordResetService passwordResetService;

    @Test
    void requestPasswordResetIsPublic() throws Exception {
        when(passwordResetService.requestReset(anyString(), anyString()))
                .thenReturn(new AuthDtos.MessageResponse("If an account matches those details, we sent a password reset link to its email."));

        mockMvc.perform(post("/auth/request-password-reset")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"username":"griller","email":"griller@example.com"}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").isNotEmpty());

        verify(passwordResetService).requestReset("griller", "griller@example.com");
    }

    @Test
    void requestPasswordResetRequiresUsernameAndEmail() throws Exception {
        mockMvc.perform(post("/auth/request-password-reset")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void resetPasswordIsPublic() throws Exception {
        mockMvc.perform(post("/auth/reset-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"token":"reset-token","password":"newpass12","passwordConfirm":"newpass12"}
                                """))
                .andExpect(status().isNoContent());

        verify(passwordResetService).resetPassword("reset-token", "newpass12", "newpass12");
    }

    @Test
    void resetPasswordRequiresToken() throws Exception {
        mockMvc.perform(post("/auth/reset-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"password":"newpass12","passwordConfirm":"newpass12"}
                                """))
                .andExpect(status().isBadRequest());
    }
}
