package com.library.controller;

import com.library.entity.Book;
import com.library.service.HistoryService;
import com.library.dto.BookDTO;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;

@RestController
@RequestMapping("/api/history")
@CrossOrigin(origins = "*")
public class HistoryController {
    private final HistoryService historyService;

    public HistoryController(HistoryService historyService) {
        this.historyService = historyService;
    }

    @GetMapping
    @Operation(summary = "History list", description = "Returns reading history ordered by last opened")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "History returned"),
            @ApiResponse(responseCode = "401", description = "Unauthorized")
    })
    public List<BookDTO> list(Authentication auth) {
        return historyService.list(auth.getName()).stream().map(BookDTO::fromEntity).toList();
    }
}
