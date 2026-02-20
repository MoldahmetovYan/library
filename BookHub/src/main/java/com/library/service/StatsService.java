package com.library.service;

import com.library.repository.BookRepository;
import com.library.repository.UserRepository;
import com.library.repository.ReviewRepository;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.HashMap;
import java.util.Map;
import com.library.dto.StatsDTO;

@Service
public class StatsService {
    private final BookRepository bookRepo;
    private final UserRepository userRepo;
    private final ReviewRepository reviewRepo;

    public StatsService(BookRepository bookRepo, UserRepository userRepo, ReviewRepository reviewRepo) {
        this.bookRepo = bookRepo;
        this.userRepo = userRepo;
        this.reviewRepo = reviewRepo;
    }

    public StatsDTO getStats() {
        long books = bookRepo.count();
        long users = userRepo.count();
        long reviews = reviewRepo.count();
        Double avg = reviewRepo.overallAverageRating();
        double avgRating = avg == null ? 0.0 : avg;
        long reviewsLastWeek = reviewRepo.countByCreatedAtAfter(Instant.now().minus(7, ChronoUnit.DAYS));
        String topGenre = bookRepo.findTopGenres(PageRequest.of(0, 1)).stream().findFirst().orElse(null);
        String topUser = reviewRepo.findTopReviewers(PageRequest.of(0, 1)).stream()
                .findFirst()
                .map(r -> (String) r[0])
                .orElse(null);
        return StatsDTO.builder()
                .books(books)
                .users(users)
                .reviews(reviews)
                .avgRating(avgRating)
                .reviewsLastWeek(reviewsLastWeek)
                .topGenre(topGenre)
                .topUser(topUser)
                .build();
    }

    public Map<String, Object> getExtendedStats() {
        StatsDTO dto = getStats();
        Map<String, Object> stats = new HashMap<>();
        stats.put("books", dto.getBooks());
        stats.put("users", dto.getUsers());
        stats.put("reviews", dto.getReviews());
        stats.put("averageRating", dto.getAvgRating());
        stats.put("reviewsLastWeek", dto.getReviewsLastWeek());
        stats.put("topGenre", dto.getTopGenre());
        stats.put("topUser", dto.getTopUser());
        return stats;
    }
}
