package com.library.controller;

import com.library.entity.Book;
import com.library.service.FavoriteService;
import com.library.dto.BookDTO;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;

@RestController
@RequestMapping("/api/favorites")
@CrossOrigin(origins = "*")
public class FavoriteController {
    private final FavoriteService favoriteService;

    public FavoriteController(FavoriteService favoriteService) {
        this.favoriteService = favoriteService;
    }

    @GetMapping
    @Operation(summary = "List favorites", description = "Returns authenticated user's favorite books")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Favorites returned successfully"),
            @ApiResponse(responseCode = "401", description = "Unauthorized")
    })
    public List<BookDTO> list(Authentication auth) {
        return favoriteService.list(auth.getName()).stream().map(BookDTO::fromEntity).toList();
    }

    @PostMapping
    @Operation(summary = "Add to favorites", description = "Adds a book to favorites")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Added successfully"),
            @ApiResponse(responseCode = "401", description = "Unauthorized"),
            @ApiResponse(responseCode = "404", description = "Book not found")
    })
    public ResponseEntity<?> add(Authentication auth, @RequestParam Long bookId) {
        favoriteService.add(auth.getName(), bookId);
        return ResponseEntity.ok().build();
    }

    @DeleteMapping
    @Operation(summary = "Remove favorite", description = "Removes book from favorites")
    @ApiResponses({
            @ApiResponse(responseCode = "204", description = "Removed successfully"),
            @ApiResponse(responseCode = "401", description = "Unauthorized")
    })
    public ResponseEntity<?> remove(Authentication auth, @RequestParam Long bookId) {
        favoriteService.remove(auth.getName(), bookId);
        return ResponseEntity.noContent().build();
    }
}
