package com.library.controller;

import com.library.entity.User;
import com.library.service.UserService;
import com.library.dto.UserDTO;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import java.util.Map;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;

@RestController
@RequestMapping("/api/users")
@CrossOrigin(origins = "*")
public class UserController {
    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping("/me")
    @Operation(summary = "Get profile", description = "Returns current user's profile")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Profile returned"),
            @ApiResponse(responseCode = "401", description = "Unauthorized")
    })
    public ResponseEntity<UserDTO> me(Authentication auth) {
        String email = auth.getName();
        User u = userService.getByEmail(email);
        return ResponseEntity.ok(UserDTO.fromEntity(u));
    }

    @PostMapping("/update")
    @Operation(summary = "Update profile", description = "Updates name and password")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Profile updated"),
            @ApiResponse(responseCode = "400", description = "Validation failed"),
            @ApiResponse(responseCode = "401", description = "Unauthorized")
    })
    public ResponseEntity<UserDTO> update(Authentication auth, @RequestBody Map<String, String> data) {
        String email = auth.getName();
        String fullName = data.get("fullName");
        String newPassword = data.get("newPassword");
        User updated = userService.updateProfile(email, fullName, newPassword);
        return ResponseEntity.ok(UserDTO.fromEntity(updated));
    }

    @DeleteMapping("/delete")
    @Operation(summary = "Delete account", description = "Deletes current user's account")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Account deleted"),
            @ApiResponse(responseCode = "401", description = "Unauthorized")
    })
    public ResponseEntity<?> delete(Authentication auth) {
        String email = auth.getName();
        userService.deleteAccount(email);
        return ResponseEntity.ok(Map.of("message", "Account deleted"));
    }
}
