package com.library.entity;

import jakarta.persistence.*;
import lombok.*;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

@Entity
@Table(name = "books")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Book {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable=false)
    @NotBlank
    @Size(max = 255)
    private String title;

    @Column(nullable=false)
    @NotBlank
    @Size(max = 255)
    private String author;

    @Size(max = 255)
    private String genre;

    @Column(length=5000)
    @Size(max = 5000)
    private String description;

    @Size(max = 255)
    private String coverUrl;

    @Size(max = 255)
    private String pdfUrl;
}
