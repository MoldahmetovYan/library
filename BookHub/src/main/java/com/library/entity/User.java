package com.library.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.Email;
import lombok.*;
import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

@Entity
@Table(name = "users")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(unique = true, nullable = false)
    @Email
    @NotBlank
    @Size(max = 255)
    private String email;

    @Column(nullable = false)
    @JsonIgnore
    @NotBlank
    @Size(max = 255)
    private String passwordHash;

    @Size(max = 255)
    private String fullName;

    @Column(nullable = false)
    @NotBlank
    @Size(max = 255)
    private String role; // ROLE_USER -> ROLE_ADMIN
}
