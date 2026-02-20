package com.library.controller;

import com.library.dto.BookDTO;
import com.library.entity.Book;
import com.library.service.BookService;
import org.springframework.graphql.data.method.annotation.Argument;
import org.springframework.graphql.data.method.annotation.MutationMapping;
import org.springframework.graphql.data.method.annotation.QueryMapping;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;

import java.util.List;

@Controller
public class GraphQlBookController {

    private final BookService bookService;

    public GraphQlBookController(BookService bookService) {
        this.bookService = bookService;
    }

    @QueryMapping
    public List<BookDTO> books() {
        return bookService.getAllBooks().stream().map(BookDTO::fromEntity).toList();
    }

    @QueryMapping
    public BookDTO bookById(@Argument Long id) {
        return BookDTO.fromEntity(bookService.getBook(id));
    }

    @MutationMapping
    public BookDTO addBook(@Argument BookInput input, Authentication auth) {
        if (auth == null || auth.getAuthorities().stream().noneMatch(a -> "ROLE_ADMIN".equals(a.getAuthority()))) {
            throw new AccessDeniedException("Admin role is required for GraphQL mutation");
        }
        Book book = new Book();
        book.setTitle(input.title());
        book.setAuthor(input.author());
        book.setGenre(input.genre());
        book.setDescription(input.description());
        return BookDTO.fromEntity(bookService.addBook(book));
    }

    public record BookInput(
            String title,
            String author,
            String genre,
            String description
    ) {
    }
}
