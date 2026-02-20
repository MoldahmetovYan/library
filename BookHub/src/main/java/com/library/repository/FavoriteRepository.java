package com.library.repository;

import com.library.entity.Favorite;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface FavoriteRepository extends JpaRepository<Favorite, Long> {
    List<Favorite> findByUserId(Long userId);
    boolean existsByUserIdAndBookId(Long userId, Long bookId);
    void deleteByUserIdAndBookId(Long userId, Long bookId);
}

