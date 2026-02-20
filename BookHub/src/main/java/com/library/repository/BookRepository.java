package com.library.repository;

import com.library.entity.Book;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import java.util.List;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

public interface BookRepository extends JpaRepository<Book, Long> {
    List<Book> findByTitleContainingIgnoreCase(String title);
    List<Book> findByAuthorContainingIgnoreCase(String author);
    List<Book> findByTitleContainingIgnoreCaseOrAuthorContainingIgnoreCase(String title, String author);
    List<Book> findByGenreIgnoreCase(String genre);
    Page<Book> findAll(Pageable pageable);

    @Query("select b.genre from Book b where b.genre is not null and b.genre <> '' group by b.genre order by count(b) desc")
    List<String> findTopGenres(org.springframework.data.domain.Pageable pageable);
}
