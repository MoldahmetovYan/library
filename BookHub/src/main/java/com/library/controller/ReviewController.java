package com.library.controller;

import com.library.entity.Review;
import com.library.service.ReviewService;
import com.library.dto.ReviewDTO;
import com.library.dto.ReviewRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.Map;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;

@RestController
@RequestMapping("/api/reviews")
@CrossOrigin(origins = "*")
public class ReviewController {
    private final ReviewService reviewService;

    public ReviewController(ReviewService reviewService) {
        this.reviewService = reviewService;
    }

    @GetMapping("/{bookId}")
    @Operation(summary = "List reviews", description = "Returns all reviews for a book")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Reviews returned"),
            @ApiResponse(responseCode = "404", description = "Book not found")
    })
    public List<ReviewDTO> list(@PathVariable Long bookId) {
        return reviewService.getByBook(bookId).stream().map(ReviewDTO::fromEntity).toList();
    }

    @PostMapping("/{bookId}")
    @Operation(summary = "Add review", description = "Creates a new review for a book by current user")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Review created"),
            @ApiResponse(responseCode = "400", description = "Validation failed"),
            @ApiResponse(responseCode = "401", description = "Unauthorized"),
            @ApiResponse(responseCode = "409", description = "Duplicate review")
    })
    public ResponseEntity<ReviewDTO> add(Authentication auth, @PathVariable Long bookId, @RequestBody @jakarta.validation.Valid ReviewRequest req) {
        Review r = reviewService.add(auth.getName(), bookId, req.getRating(), req.getComment());
        return ResponseEntity.ok(ReviewDTO.fromEntity(r));
    }

    @PutMapping("/{bookId}")
    @Operation(summary = "Update review", description = "Updates current user's review for a book")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Review updated"),
            @ApiResponse(responseCode = "400", description = "Validation failed"),
            @ApiResponse(responseCode = "401", description = "Unauthorized"),
            @ApiResponse(responseCode = "404", description = "Review not found")
    })
    public ResponseEntity<ReviewDTO> update(Authentication auth, @PathVariable Long bookId, @RequestBody @jakarta.validation.Valid ReviewRequest req) {
        Review r = reviewService.update(auth.getName(), bookId, req.getRating(), req.getComment());
        return ResponseEntity.ok(ReviewDTO.fromEntity(r));
    }

    @DeleteMapping("/{bookId}")
    @Operation(summary = "Delete review", description = "Deletes current user's review for a book")
    @ApiResponses({
            @ApiResponse(responseCode = "204", description = "Review deleted"),
            @ApiResponse(responseCode = "401", description = "Unauthorized"),
            @ApiResponse(responseCode = "404", description = "Review not found")
    })
    public ResponseEntity<?> delete(Authentication auth, @PathVariable Long bookId) {
        reviewService.delete(auth.getName(), bookId);
        return ResponseEntity.noContent().build();
    }
}
