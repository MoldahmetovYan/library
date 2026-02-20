package com.library.config;

import com.library.dto.ErrorResponse;
import com.library.exception.ResourceNotFoundException;
import com.library.exception.DuplicateReviewException;
import jakarta.servlet.http.HttpServletRequest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;

import java.time.LocalDateTime;
import java.util.NoSuchElementException;
import java.util.stream.Collectors;

@ControllerAdvice
public class GlobalExceptionHandler {
    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponse> handleValidationErrors(MethodArgumentNotValidException ex, HttpServletRequest request) {
        String message = ex.getBindingResult().getFieldErrors().stream()
                .map(err -> err.getField() + ": " + err.getDefaultMessage())
                .collect(Collectors.joining(", "));
        log.warn("400 {} {} - validation failed: {}", request.getMethod(), request.getRequestURI(), message);
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(new ErrorResponse(message, HttpStatus.BAD_REQUEST.value(), LocalDateTime.now()));
    }

    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleNotFound(ResourceNotFoundException e) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(new ErrorResponse(e.getMessage(), HttpStatus.NOT_FOUND.value(), LocalDateTime.now()));
    }

    @ExceptionHandler(DuplicateReviewException.class)
    public ResponseEntity<ErrorResponse> handleDuplicate(DuplicateReviewException e) {
        return ResponseEntity.status(HttpStatus.CONFLICT)
                .body(new ErrorResponse(e.getMessage(), HttpStatus.CONFLICT.value(), LocalDateTime.now()));
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<ErrorResponse> handleIllegalArgument(IllegalArgumentException e, HttpServletRequest request) {
        log.warn("400 {} {} - illegal argument: {}", request.getMethod(), request.getRequestURI(), e.getMessage());
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(new ErrorResponse(e.getMessage(), HttpStatus.BAD_REQUEST.value(), LocalDateTime.now()));
    }

    @ExceptionHandler(MissingServletRequestParameterException.class)
    public ResponseEntity<ErrorResponse> handleMissingParam(MissingServletRequestParameterException e, HttpServletRequest request) {
        String message = "Missing required parameter: " + e.getParameterName();
        log.warn("400 {} {} - {}", request.getMethod(), request.getRequestURI(), message);
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(new ErrorResponse(message, HttpStatus.BAD_REQUEST.value(), LocalDateTime.now()));
    }

    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    public ResponseEntity<ErrorResponse> handleTypeMismatch(MethodArgumentTypeMismatchException e, HttpServletRequest request) {
        String message = "Invalid value for parameter '" + e.getName() + "': " + e.getValue();
        log.warn("400 {} {} - {}", request.getMethod(), request.getRequestURI(), message);
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(new ErrorResponse(message, HttpStatus.BAD_REQUEST.value(), LocalDateTime.now()));
    }

    @ExceptionHandler({NoSuchElementException.class, EmptyResultDataAccessException.class})
    public ResponseEntity<ErrorResponse> handleMissingEntity(Exception e, HttpServletRequest request) {
        String message = "Resource not found";
        log.warn("404 {} {} - {}", request.getMethod(), request.getRequestURI(), e.getMessage());
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(new ErrorResponse(message, HttpStatus.NOT_FOUND.value(), LocalDateTime.now()));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponse> handleAll(Exception e, HttpServletRequest request) {
        log.error("500 {} {} - {}", request.getMethod(), request.getRequestURI(), e.getMessage(), e);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(new ErrorResponse(e.getMessage(), HttpStatus.INTERNAL_SERVER_ERROR.value(), LocalDateTime.now()));
    }
}
