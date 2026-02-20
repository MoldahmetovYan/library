package com.library.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.Instant;

@Entity
@Table(name = "history")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class History {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false)
    @JoinColumn(name = "user_id")
    private User user;

    @ManyToOne(optional = false)
    @JoinColumn(name = "book_id")
    private Book book;

    @Column(name = "last_opened", nullable = false)
    private Instant lastOpened;
}

