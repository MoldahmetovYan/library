package com.library.dto;

import com.library.entity.Book;
import lombok.Builder;
import lombok.Value;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

@Value
@Builder
public class BookDTO {
    Long id;
    @NotBlank @Size(max = 255)
    String title;
    @NotBlank @Size(max = 255)
    String author;
    @Size(max = 255)
    String genre;
    @Size(max = 5000)
    String description;
    @Size(max = 255)
    String coverUrl;
    @Size(max = 255)
    String pdfUrl;

    public static BookDTO fromEntity(Book b) {
        return BookDTO.builder()
                .id(b.getId())
                .title(b.getTitle())
                .author(b.getAuthor())
                .genre(b.getGenre())
                .description(b.getDescription())
                .coverUrl(b.getCoverUrl())
                .pdfUrl(b.getPdfUrl())
                .build();
    }
}
