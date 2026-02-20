package com.library.service;

import com.library.entity.Book;
import com.library.entity.History;
import com.library.entity.User;
import com.library.exception.ResourceNotFoundException;
import com.library.repository.BookRepository;
import com.library.repository.HistoryRepository;
import com.library.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import lombok.extern.slf4j.Slf4j;

import java.time.Instant;
import java.util.List;
import java.util.stream.Collectors;

@Service
@Slf4j
public class HistoryService {
    private final HistoryRepository historyRepo;
    private final UserRepository userRepo;
    private final BookRepository bookRepo;

    public HistoryService(HistoryRepository historyRepo, UserRepository userRepo, BookRepository bookRepo) {
        this.historyRepo = historyRepo;
        this.userRepo = userRepo;
        this.bookRepo = bookRepo;
    }

    public List<Book> list(String userEmail) {
        User u = userRepo.findByEmail(userEmail)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + userEmail));
        return historyRepo.findByUserIdOrderByLastOpenedDesc(u.getId())
                .stream().map(History::getBook).collect(Collectors.toList());
    }

    @Transactional
    public void recordView(String userEmail, Long bookId) {
        User u = userRepo.findByEmail(userEmail)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + userEmail));
        Book b = bookRepo.findById(bookId)
                .orElseThrow(() -> new ResourceNotFoundException("Book not found: " + bookId));
        History h = History.builder().user(u).book(b).lastOpened(Instant.now()).build();
        historyRepo.save(h);
        log.info("History recorded for {} viewing book {}", userEmail, bookId);
    }
}
