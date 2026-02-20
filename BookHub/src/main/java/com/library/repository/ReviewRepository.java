package com.library.repository;

import com.library.entity.Review;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import java.time.Instant;
import java.util.List;
import java.util.Optional;

public interface ReviewRepository extends JpaRepository<Review, Long> {
    List<Review> findByBookId(Long bookId);
    boolean existsByUserIdAndBookId(Long userId, Long bookId);
    Optional<Review> findByUserIdAndBookId(Long userId, Long bookId);

    @Query("select r.book.id as bookId, avg(r.rating) as avgRating from Review r group by r.book.id order by avg(r.rating) desc")
    List<Object[]> findTopBooks(Pageable pageable);

    @Query("select avg(r.rating) from Review r")
    Double overallAverageRating();

    @Query("select count(distinct r.book.id) from Review r")
    long countDistinctBooksReviewed();

    long countByCreatedAtAfter(Instant since);

    @Query("select r.user.email as email, count(r) as cnt from Review r group by r.user.email order by count(r) desc")
    List<Object[]> findTopReviewers(Pageable pageable);
}
