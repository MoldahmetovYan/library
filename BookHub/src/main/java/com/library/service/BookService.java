package com.library.service;

import com.library.entity.Book;
import com.library.repository.BookRepository;
import com.library.repository.ReviewRepository;
import com.library.exception.ResourceNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Sort.Order;
import org.springframework.transaction.annotation.Transactional;
import lombok.extern.slf4j.Slf4j;
import java.util.List;

@Service
@Slf4j
public class BookService {

    private final BookRepository repo;
    private final ReviewRepository reviewRepo;

    public BookService(BookRepository repo, ReviewRepository reviewRepo) {
        this.repo = repo;
        this.reviewRepo = reviewRepo;
    }

    public List<Book> getAllBooks() {
        return repo.findAll();
    }

    public Book getBook(Long id) {
        return repo.findById(id).orElseThrow(() -> new ResourceNotFoundException("Book not found: " + id));
    }

    @Transactional
    public Book addBook(Book book) {
        Book saved = repo.save(book);
        log.info("Book created/updated: {} - {}", saved.getId(), saved.getTitle());
        return saved;
    }

    @Transactional
    public Book updateBook(Long id, Book updatedBook) {
        Book existing = getBook(id);
        existing.setTitle(updatedBook.getTitle());
        existing.setAuthor(updatedBook.getAuthor());
        existing.setGenre(updatedBook.getGenre());
        existing.setDescription(updatedBook.getDescription());
        Book saved = repo.save(existing);
        log.info("Book updated: {}", id);
        return saved;
    }

    @Transactional
    public void deleteBook(Long id) {
        Book existing = getBook(id);
        repo.delete(existing);
        log.info("Book deleted: {}", id);
    }

    public List<Book> search(String keyword) {
        return searchByTitleOrAuthor(keyword);
    }

    public List<Book> searchByTitleOrAuthor(String keyword) {
        if (keyword == null || keyword.isBlank()) {
            return repo.findAll();
        }
        return repo.findByTitleContainingIgnoreCaseOrAuthorContainingIgnoreCase(keyword, keyword);
    }

    public Page<Book> getAllSorted(String sortBy, int page, int size) {
        if (sortBy == null || sortBy.isBlank()) sortBy = "title";
        Pageable pageable = PageRequest.of(page, size, Sort.by(sortBy).ascending());
        return repo.findAll(pageable);
    }

    public java.util.List<Book> getTopBooks(int limit) {
        var rows = reviewRepo.findTopBooks(PageRequest.of(0, limit));
        java.util.List<Long> ids = new java.util.ArrayList<>();
        for (Object[] r : rows) ids.add((Long) r[0]);
        if (ids.isEmpty()) return java.util.List.of();
        return repo.findAllById(ids);
    }

    public java.util.List<Book> getByGenre(String genre) {
        return repo.findByGenreIgnoreCase(genre);
    }

    public Page<Book> getAll(Pageable pageable) {
        Order ratingOrder = pageable.getSort().getOrderFor("rating");
        if (ratingOrder != null) {
            var rows = reviewRepo.findTopBooks(PageRequest.of(pageable.getPageNumber(), pageable.getPageSize()));
            java.util.List<Long> ids = new java.util.ArrayList<>();
            for (Object[] r : rows) ids.add((Long) r[0]);
            java.util.Map<Long, Book> map = new java.util.HashMap<>();
            for (Book b : repo.findAllById(ids)) map.put(b.getId(), b);
            java.util.List<Book> ordered = new java.util.ArrayList<>();
            for (Long id : ids) { Book b = map.get(id); if (b != null) ordered.add(b); }
            long total = reviewRepo.countDistinctBooksReviewed();
            return new PageImpl<>(ordered, pageable, total);
        }
        return repo.findAll(pageable);
    }
}
