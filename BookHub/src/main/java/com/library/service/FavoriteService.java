package com.library.service;

import com.library.entity.Book;
import com.library.entity.Favorite;
import com.library.entity.User;
import com.library.exception.ResourceNotFoundException;
import com.library.repository.BookRepository;
import com.library.repository.FavoriteRepository;
import com.library.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import lombok.extern.slf4j.Slf4j;

import java.util.List;
import java.util.stream.Collectors;

@Service
@Slf4j
public class FavoriteService {
    private final FavoriteRepository favoriteRepo;
    private final UserRepository userRepo;
    private final BookRepository bookRepo;

    public FavoriteService(FavoriteRepository favoriteRepo, UserRepository userRepo, BookRepository bookRepo) {
        this.favoriteRepo = favoriteRepo;
        this.userRepo = userRepo;
        this.bookRepo = bookRepo;
    }

    public List<Book> list(String userEmail) {
        User user = userRepo.findByEmail(userEmail)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + userEmail));
        return favoriteRepo.findByUserId(user.getId())
                .stream().map(Favorite::getBook).collect(Collectors.toList());
    }

    @Transactional
    public void add(String userEmail, Long bookId) {
        User user = userRepo.findByEmail(userEmail)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + userEmail));
        if (!favoriteRepo.existsByUserIdAndBookId(user.getId(), bookId)) {
            Book book = bookRepo.findById(bookId)
                    .orElseThrow(() -> new ResourceNotFoundException("Book not found: " + bookId));
            favoriteRepo.save(Favorite.builder().user(user).book(book).build());
            log.info("Favorite added by {} for book {}", userEmail, bookId);
        }
    }

    @Transactional
    public void remove(String userEmail, Long bookId) {
        User user = userRepo.findByEmail(userEmail)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + userEmail));
        favoriteRepo.deleteByUserIdAndBookId(user.getId(), bookId);
        log.info("Favorite removed by {} for book {}", userEmail, bookId);
    }
}
