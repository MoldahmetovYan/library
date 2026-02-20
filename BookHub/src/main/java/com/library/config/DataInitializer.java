package com.library.config;

import com.library.entity.User;
import com.library.entity.Book;
import com.library.entity.Review;
import com.library.entity.Favorite;
import com.library.repository.UserRepository;
import com.library.repository.BookRepository;
import com.library.repository.ReviewRepository;
import com.library.repository.FavoriteRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import lombok.extern.slf4j.Slf4j;

@Configuration
@Slf4j
public class DataInitializer {

    @Bean
    CommandLineRunner initAdmin(UserRepository repo, BCryptPasswordEncoder encoder) {
        return args -> {
            if (repo.findByEmail("admin@library.com").isEmpty()) {
                repo.save(User.builder()
                        .email("admin@library.com")
                        .passwordHash(encoder.encode("admin123"))
                        .fullName("Administrator")
                        .role("ROLE_ADMIN")
                        .build());
                log.info("Admin created: admin@library.com / admin123");
            }
        };
    }

    @Bean
    CommandLineRunner loadData(UserRepository users, BookRepository books, ReviewRepository reviews, FavoriteRepository favorites, BCryptPasswordEncoder encoder) {
        return args -> {
            if (users.findByEmail("user1@library.com").isEmpty()) {
                users.save(User.builder().email("user1@library.com").passwordHash(encoder.encode("user123")).fullName("User One").role("ROLE_USER").build());
            }
            if (users.findByEmail("user2@library.com").isEmpty()) {
                users.save(User.builder().email("user2@library.com").passwordHash(encoder.encode("user123")).fullName("User Two").role("ROLE_USER").build());
            }

            if (books.count() == 0) {
                books.save(Book.builder().title("1984").author("George Orwell").genre("Dystopia").description("Classic dystopian novel").build());
                books.save(Book.builder().title("Brave New World").author("Aldous Huxley").genre("Dystopia").description("Iconic sci-fi").build());
                books.save(Book.builder().title("The Hobbit").author("J.R.R. Tolkien").genre("Fantasy").description("Adventure in Middle-earth").build());
                books.save(Book.builder().title("Clean Code").author("Robert C. Martin").genre("Programming").description("Best practices").build());
                books.save(Book.builder().title("The Pragmatic Programmer").author("Andrew Hunt").genre("Programming").description("Pragmatic tips").build());
            }

            var u1 = users.findByEmail("user1@library.com").orElse(null);
            var u2 = users.findByEmail("user2@library.com").orElse(null);
            var list = books.findAll();
            if (u1 != null && u2 != null && reviews.count() == 0 && !list.isEmpty()) {
                reviews.save(Review.builder().user(u1).book(list.get(0)).rating(5).comment("Amazing!").createdAt(java.time.Instant.now()).build());
                reviews.save(Review.builder().user(u2).book(list.get(0)).rating(4).comment("Great read").createdAt(java.time.Instant.now()).build());
                reviews.save(Review.builder().user(u1).book(list.get(1)).rating(4).comment("Thought-provoking").createdAt(java.time.Instant.now()).build());
            }

            if (u1 != null && !list.isEmpty()) {
                if (!favorites.existsByUserIdAndBookId(u1.getId(), list.get(0).getId())) {
                    favorites.save(Favorite.builder().user(u1).book(list.get(0)).build());
                }
            }
        };
    }
}
