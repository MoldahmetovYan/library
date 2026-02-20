package com.library.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;

@Getter @Setter
public class ReviewRequest {
    @Min(1) @Max(5)
    private int rating;

    @NotBlank
    @Size(max = 255)
    private String comment;
}
