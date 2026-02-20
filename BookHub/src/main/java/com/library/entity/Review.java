package com.library.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Size;
import jakarta.validation.constraints.NotBlank;
import lombok.*;
import java.time.Instant;

@Entity
@Table(name = "reviews")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Review {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false)
    @JoinColumn(name = "user_id")
    private User user;

    @ManyToOne(optional = false)
    @JoinColumn(name = "book_id")
    private Book book;

    @Column(nullable = false)
    @Min(1) @Max(5)
    private int rating; // 1..5

    @Column(length = 255)
    @NotBlank
    @Size(max = 255)
    private String comment;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;
}
