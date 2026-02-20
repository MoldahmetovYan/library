package com.library.controller;

import com.library.entity.Book;
import com.library.service.BookService;
import com.library.dto.BookDTO;
import org.springframework.http.ResponseEntity;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import jakarta.validation.Valid;
import java.util.List;
import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.UUID;
import org.springframework.security.core.Authentication;
import org.springframework.beans.factory.annotation.Value;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;

@RestController
@RequestMapping("/api/books")
@CrossOrigin(origins = "*")
public class BookController {

    private final BookService service;
    private final com.library.service.HistoryService historyService;
    @Value("${app.uploads.dir}")
    private String uploadDir;

    public BookController(BookService service, com.library.service.HistoryService historyService) {
        this.service = service;
        this.historyService = historyService;
    }

    @GetMapping
    @Operation(summary = "Get all books", description = "Returns paginated list of all books")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Books returned successfully")
    })
    public Page<BookDTO> getAll(Pageable pageable) {
        return service.getAll(pageable).map(BookDTO::fromEntity);
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get book by id", description = "Returns a single book and records view into history if authenticated")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Book returned"),
            @ApiResponse(responseCode = "404", description = "Book not found")
    })
    public ResponseEntity<BookDTO> getById(@PathVariable Long id, Authentication auth) {
        if (auth != null && auth.isAuthenticated()) {
            try { historyService.recordView(auth.getName(), id); } catch (Exception ignored) {}
        }
        return ResponseEntity.ok(BookDTO.fromEntity(service.getBook(id)));
    }

    @GetMapping("/search")
    @Operation(summary = "Search books", description = "Search by title or author")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Search results returned")
    })
    public List<BookDTO> search(@RequestParam(name = "query", required = false) String query,
                                @RequestParam(name = "q", required = false) String q) {
        String keyword = (query != null) ? query : (q != null ? q : "");
        return service.searchByTitleOrAuthor(keyword).stream().map(BookDTO::fromEntity).toList();
    }

    @GetMapping("/sorted")
    public ResponseEntity<Page<BookDTO>> getSortedBooks(
            @RequestParam(defaultValue = "title") String sortBy,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        return ResponseEntity.ok(service.getAllSorted(sortBy, page, size).map(BookDTO::fromEntity));
    }

    @PostMapping
    @Operation(summary = "Create book", description = "Create a new book entry")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Book created"),
            @ApiResponse(responseCode = "400", description = "Validation failed"),
            @ApiResponse(responseCode = "401", description = "Unauthorized")
    })
    public ResponseEntity<BookDTO> createBook(@Valid @RequestBody BookDTO dto) {
        Book book = new Book();
        book.setTitle(dto.getTitle());
        book.setAuthor(dto.getAuthor());
        book.setGenre(dto.getGenre());
        book.setDescription(dto.getDescription());
        return ResponseEntity.ok(BookDTO.fromEntity(service.addBook(book)));
    }

    @PutMapping("/{id}")
    @Operation(summary = "Update book", description = "Update book fields by id")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Book updated"),
            @ApiResponse(responseCode = "400", description = "Validation failed"),
            @ApiResponse(responseCode = "401", description = "Unauthorized"),
            @ApiResponse(responseCode = "404", description = "Book not found")
    })
    public ResponseEntity<BookDTO> updateBook(@PathVariable Long id, @Valid @RequestBody BookDTO dto) {
        Book updated = new Book();
        updated.setTitle(dto.getTitle());
        updated.setAuthor(dto.getAuthor());
        updated.setGenre(dto.getGenre());
        updated.setDescription(dto.getDescription());
        return ResponseEntity.ok(BookDTO.fromEntity(service.updateBook(id, updated)));
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Delete book", description = "Deletes a book by id")
    @ApiResponses({
            @ApiResponse(responseCode = "204", description = "Book deleted"),
            @ApiResponse(responseCode = "404", description = "Book not found"),
            @ApiResponse(responseCode = "401", description = "Unauthorized")
    })
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        service.deleteBook(id);
        return ResponseEntity.noContent().build();
    }

    @PostMapping(value = "/{id}/cover", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @Operation(summary = "Upload cover", description = "Uploads image file as book cover")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Cover uploaded"),
            @ApiResponse(responseCode = "400", description = "Invalid file"),
            @ApiResponse(responseCode = "404", description = "Book not found"),
            @ApiResponse(responseCode = "401", description = "Unauthorized")
    })
    public ResponseEntity<BookDTO> uploadCover(
            @PathVariable Long id,
            @RequestParam("file") MultipartFile file) throws IOException {

        if (file.isEmpty()) { throw new IllegalArgumentException("File is empty."); }
        if (file.getSize() > 10_000_000) { throw new IllegalArgumentException("File too large. Max 10MB."); }
        if (file.getContentType() == null || !file.getContentType().startsWith("image/")) {
            throw new IllegalArgumentException("Only image files are allowed.");
        }

        File dir = new File(uploadDir);
        if (!dir.exists()) dir.mkdirs();

        String filename = UUID.randomUUID() + "_" + file.getOriginalFilename();
        Path path = Paths.get(dir.getAbsolutePath(), filename);

        Files.copy(file.getInputStream(), path);

        Book book = service.getBook(id);
        book.setCoverUrl("/uploads/" + filename);
        service.addBook(book);

        return ResponseEntity.ok(BookDTO.fromEntity(book));
    }

    @PostMapping(value = "/{id}/pdf", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @Operation(summary = "Upload PDF", description = "Uploads book content as PDF")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "PDF uploaded"),
            @ApiResponse(responseCode = "400", description = "Invalid file"),
            @ApiResponse(responseCode = "404", description = "Book not found"),
            @ApiResponse(responseCode = "401", description = "Unauthorized")
    })
    public ResponseEntity<BookDTO> uploadPdf(
            @PathVariable Long id,
            @RequestParam("file") MultipartFile file) throws IOException {

        if (file.isEmpty()) { throw new IllegalArgumentException("File is empty."); }
        if (file.getSize() > 10_000_000) { throw new IllegalArgumentException("File too large. Max 10MB."); }
        if (file.getContentType() == null || !file.getContentType().equals("application/pdf")) {
            throw new IllegalArgumentException("Only PDF files are allowed.");
        }

        File dir = new File(uploadDir);
        if (!dir.exists()) dir.mkdirs();

        String filename = UUID.randomUUID() + "_" + file.getOriginalFilename();
        Path path = Paths.get(dir.getAbsolutePath(), filename);

        Files.copy(file.getInputStream(), path);

        Book book = service.getBook(id);
        book.setPdfUrl("/uploads/" + filename);
        service.addBook(book);

        return ResponseEntity.ok(BookDTO.fromEntity(book));
    }

    @GetMapping("/top")
    public List<BookDTO> top(@RequestParam(defaultValue = "10") int size) {
        return service.getTopBooks(size).stream().map(BookDTO::fromEntity).toList();
    }

    @GetMapping("/genre")
    public List<BookDTO> byGenre(@RequestParam String genre) {
        return service.getByGenre(genre).stream().map(BookDTO::fromEntity).toList();
    }
}
