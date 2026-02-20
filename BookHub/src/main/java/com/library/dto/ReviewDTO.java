package com.library.dto;

import com.library.entity.Review;
import lombok.Value;
import lombok.Builder;
import java.time.LocalDateTime;
import java.time.ZoneId;

@Value
@Builder
public class ReviewDTO {
    String userName;
    int rating;
    String comment;
    LocalDateTime createdAt;

    public static ReviewDTO fromEntity(Review r) {
        return ReviewDTO.builder()
                .userName(r.getUser().getFullName())
                .rating(r.getRating())
                .comment(r.getComment())
                .createdAt(LocalDateTime.ofInstant(r.getCreatedAt(), ZoneId.systemDefault()))
                .build();
    }
}

