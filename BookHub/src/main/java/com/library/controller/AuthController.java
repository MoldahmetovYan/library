package com.library.controller;

import com.library.entity.User;
import com.library.repository.UserRepository;
import com.library.security.JwtService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.web.bind.annotation.*;
import java.util.Map;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpHeaders;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;

@RestController
@RequestMapping("/api/auth")
@CrossOrigin(origins = "*")
public class AuthController {

    private final UserRepository repo;
    private final BCryptPasswordEncoder encoder;
    private final JwtService jwt;

    public AuthController(UserRepository repo, BCryptPasswordEncoder encoder, JwtService jwt) {
        this.repo = repo;
        this.encoder = encoder;
        this.jwt = jwt;
    }

    @PostMapping("/register")
    @Operation(summary = "Register", description = "Registers a new user and returns JWT token")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Registered successfully"),
            @ApiResponse(responseCode = "400", description = "Email already exists")
    })
    public ResponseEntity<?> register(@RequestBody Map<String, String> data) {
        String email = data.get("email");
        String password = data.get("password");
        String name = data.get("fullName");

        if (repo.findByEmail(email).isPresent()) {
            return ResponseEntity.badRequest().body("Email already exists");
        }

        User user = User.builder()
                .email(email)
                .passwordHash(encoder.encode(password))
                .fullName(name)
                .role("ROLE_USER")
                .build();

        repo.save(user);
        String token = jwt.generateToken(user.getEmail(), user.getRole());
        return ResponseEntity.ok(Map.of("token", token, "role", user.getRole()));
    }

    @PostMapping("/login")
    @Operation(summary = "Login", description = "Authenticates user and returns JWT token")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Login successful"),
            @ApiResponse(responseCode = "401", description = "Invalid credentials")
    })
    public ResponseEntity<?> login(@RequestBody Map<String, String> data) {
        String email = data.get("email");
        String password = data.get("password");

        User user = repo.findByEmail(email).orElse(null);
        if (user == null || !encoder.matches(password, user.getPasswordHash())) {
            return ResponseEntity.status(401).body("Invalid credentials");
        }

        String token = jwt.generateToken(user.getEmail(), user.getRole());
        return ResponseEntity.ok(Map.of("token", token, "role", user.getRole()));
    }

    @PostMapping("/refresh")
    @Operation(summary = "Refresh token", description = "Issues a new JWT token")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Token refreshed"),
            @ApiResponse(responseCode = "401", description = "Invalid token")
    })
    public ResponseEntity<?> refresh(HttpServletRequest request, @RequestBody(required = false) Map<String, String> data) {
        String authHeader = request.getHeader(HttpHeaders.AUTHORIZATION);
        String token = null;
        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            token = authHeader.substring(7);
        } else if (data != null) {
            token = data.get("token");
        }
        if (token == null || !jwt.isValid(token)) {
            return ResponseEntity.status(401).body("Invalid token");
        }
        String email = jwt.extractEmail(token);
        var user = repo.findByEmail(email).orElse(null);
        if (user == null) {
            return ResponseEntity.status(401).body("Invalid token");
        }
        String newToken = jwt.generateToken(user.getEmail(), user.getRole());
        return ResponseEntity.ok(Map.of("token", newToken, "role", user.getRole()));
    }

    @PostMapping("/reset")
    @Operation(summary = "Reset password", description = "Changes password for authenticated user")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Password changed"),
            @ApiResponse(responseCode = "400", description = "Invalid request body"),
            @ApiResponse(responseCode = "401", description = "Unauthorized or invalid current password")
    })
    public ResponseEntity<?> resetPassword(Authentication auth, @RequestBody Map<String, String> data) {
        if (auth == null || auth.getName() == null || auth.getName().isBlank()) {
            return ResponseEntity.status(401).body(Map.of("error", "Unauthorized"));
        }

        String currentPassword = data.get("currentPassword");
        String newPassword = data.get("newPassword");
        if (currentPassword == null || currentPassword.isBlank()
                || newPassword == null || newPassword.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of("error", "currentPassword and newPassword are required"));
        }
        if (newPassword.length() < 6) {
            return ResponseEntity.badRequest().body(Map.of("error", "newPassword must be at least 6 characters"));
        }

        User user = repo.findByEmail(auth.getName()).orElse(null);
        if (user == null) {
            return ResponseEntity.status(401).body(Map.of("error", "Unauthorized"));
        }
        if (!encoder.matches(currentPassword, user.getPasswordHash())) {
            return ResponseEntity.status(401).body(Map.of("error", "Current password is incorrect"));
        }

        user.setPasswordHash(encoder.encode(newPassword));
        repo.save(user);

        return ResponseEntity.ok(Map.of("message", "Password changed successfully"));
    }
}
