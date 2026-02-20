package com.library;

import com.library.entity.User;
import com.library.repository.UserRepository;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class ApiSecurityIntegrationTests {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private BCryptPasswordEncoder passwordEncoder;

    @Test
    void loginReturnsTokenForValidUser() throws Exception {
        String token = loginAndGetToken("user1@library.com", "user123");
        assertThat(token).isNotBlank();
    }

    @Test
    void registerReturnsTokenForNewUser() throws Exception {
        String email = "autotest+" + UUID.randomUUID() + "@example.com";
        String payload = objectMapper.writeValueAsString(Map.of(
                "email", email,
                "password", "secret123",
                "fullName", "Autotest User"
        ));

        MvcResult result = mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(payload))
                .andExpect(status().isOk())
                .andReturn();

        JsonNode json = objectMapper.readTree(result.getResponse().getContentAsString());
        assertThat(json.path("token").asText()).isNotBlank();
        assertThat(json.path("role").asText()).isEqualTo("ROLE_USER");
    }

    @Test
    void createBookIsDeniedForAnonymousUser() throws Exception {
        String payload = objectMapper.writeValueAsString(Map.of(
                "title", "Anon Book",
                "author", "Anon Author"
        ));

        int status = mockMvc.perform(post("/api/books")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(payload))
                .andReturn()
                .getResponse()
                .getStatus();

        assertThat(status).isIn(401, 403);
    }

    @Test
    void createBookIsDeniedForRegularUser() throws Exception {
        String userToken = loginAndGetToken("user1@library.com", "user123");
        String payload = objectMapper.writeValueAsString(Map.of(
                "title", "User Book",
                "author", "User Author"
        ));

        mockMvc.perform(post("/api/books")
                        .header("Authorization", "Bearer " + userToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(payload))
                .andExpect(status().isForbidden());
    }

    @Test
    void createBookIsAllowedForAdmin() throws Exception {
        ensureAdminCredentials();
        String adminToken = loginAndGetToken("admin@library.com", "admin123");
        String payload = objectMapper.writeValueAsString(Map.of(
                "title", "Admin Book " + System.currentTimeMillis(),
                "author", "Admin Author",
                "genre", "Test"
        ));

        mockMvc.perform(post("/api/books")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(payload))
                .andExpect(status().isOk());
    }

    @Test
    void resetPasswordRequiresAuthentication() throws Exception {
        String payload = objectMapper.writeValueAsString(Map.of(
                "currentPassword", "user123",
                "newPassword", "newPass123"
        ));

        int status = mockMvc.perform(post("/api/auth/reset")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(payload))
                .andReturn()
                .getResponse()
                .getStatus();

        assertThat(status).isIn(401, 403);
    }

    @Test
    void resetPasswordRejectsWrongCurrentPassword() throws Exception {
        String userToken = loginAndGetToken("user1@library.com", "user123");
        String payload = objectMapper.writeValueAsString(Map.of(
                "currentPassword", "wrong-password",
                "newPassword", "newPass123"
        ));

        mockMvc.perform(post("/api/auth/reset")
                        .header("Authorization", "Bearer " + userToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(payload))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void getUnknownBookReturnsNotFound() throws Exception {
        mockMvc.perform(get("/api/books/999999999"))
                .andExpect(status().isNotFound());
    }

    private void ensureAdminCredentials() {
        User admin = userRepository.findByEmail("admin@library.com")
                .orElseGet(() -> User.builder()
                        .email("admin@library.com")
                        .fullName("Administrator")
                        .build());
        admin.setRole("ROLE_ADMIN");
        admin.setPasswordHash(passwordEncoder.encode("admin123"));
        userRepository.save(admin);
    }

    private String loginAndGetToken(String email, String password) throws Exception {
        String payload = objectMapper.writeValueAsString(Map.of(
                "email", email,
                "password", password
        ));

        MvcResult result = mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(payload))
                .andExpect(status().isOk())
                .andReturn();

        JsonNode json = objectMapper.readTree(result.getResponse().getContentAsString());
        String token = json.path("token").asText();
        assertThat(token).isNotBlank();
        return token;
    }
}
