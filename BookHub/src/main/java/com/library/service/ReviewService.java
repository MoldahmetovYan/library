package com.library.service;

import com.library.entity.Book;
import com.library.entity.Review;
import com.library.entity.User;
import com.library.repository.BookRepository;
import com.library.repository.ReviewRepository;
import com.library.repository.UserRepository;
import com.library.exception.DuplicateReviewException;
import com.library.exception.ResourceNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import lombok.extern.slf4j.Slf4j;

import java.time.Instant;
import java.util.List;

@Service
@Slf4j
public class ReviewService {
    private final ReviewRepository reviewRepo;
    private final UserRepository userRepo;
    private final BookRepository bookRepo;

    public ReviewService(ReviewRepository reviewRepo, UserRepository userRepo, BookRepository bookRepo) {
        this.reviewRepo = reviewRepo;
        this.userRepo = userRepo;
        this.bookRepo = bookRepo;
    }

    public List<Review> getByBook(Long bookId) {
        return reviewRepo.findByBookId(bookId);
    }

    @Transactional
    public Review add(String userEmail, Long bookId, int rating, String comment) {
        User user = userRepo.findByEmail(userEmail)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + userEmail));
        Book book = bookRepo.findById(bookId)
                .orElseThrow(() -> new ResourceNotFoundException("Book not found: " + bookId));
        if (reviewRepo.existsByUserIdAndBookId(user.getId(), bookId)) {
            throw new DuplicateReviewException("User already reviewed this book");
        }
        Review review = Review.builder()
                .user(user)
                .book(book)
                .rating(rating)
                .comment(comment)
                .createdAt(Instant.now())
                .build();
        Review saved = reviewRepo.save(review);
        log.info("Review added by {} for book {}", userEmail, bookId);
        return saved;
    }

    @Transactional
    public Review update(String userEmail, Long bookId, int rating, String comment) {
        User user = userRepo.findByEmail(userEmail)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + userEmail));
        Review existing = reviewRepo.findByUserIdAndBookId(user.getId(), bookId)
                .orElseThrow(() -> new ResourceNotFoundException("Review not found"));
        existing.setRating(rating);
        existing.setComment(comment);
        Review saved = reviewRepo.save(existing);
        log.info("Review updated by {} for book {}", userEmail, bookId);
        return saved;
    }

    @Transactional
    public void delete(String userEmail, Long bookId) {
        User user = userRepo.findByEmail(userEmail)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + userEmail));
        Review review = reviewRepo.findByUserIdAndBookId(user.getId(), bookId)
                .orElseThrow(() -> new ResourceNotFoundException("Review not found"));
        reviewRepo.delete(review);
        log.info("Review deleted by {} for book {}", userEmail, bookId);
    }
}
