package com.library.dto;

import com.library.entity.User;
import lombok.Value;
import lombok.Builder;

@Value
@Builder
public class UserDTO {
    String email;
    String fullName;
    String role;

    public static UserDTO fromEntity(User u) {
        return UserDTO.builder()
                .email(u.getEmail())
                .fullName(u.getFullName())
                .role(u.getRole())
                .build();
    }
}

