package com.library.service;

import com.library.entity.User;
import com.library.exception.ResourceNotFoundException;
import com.library.repository.UserRepository;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import lombok.extern.slf4j.Slf4j;

@Service
@Slf4j
public class UserService {
    private final UserRepository userRepo;
    private final BCryptPasswordEncoder encoder;

    public UserService(UserRepository userRepo, BCryptPasswordEncoder encoder) {
        this.userRepo = userRepo;
        this.encoder = encoder;
    }

    public User getByEmail(String email) {
        return userRepo.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + email));
    }

    @Transactional
    public User updateProfile(String email, String fullName, String newPassword) {
        User user = getByEmail(email);
        if (fullName != null && !fullName.isBlank()) user.setFullName(fullName);
        if (newPassword != null && !newPassword.isBlank()) user.setPasswordHash(encoder.encode(newPassword));
        User saved = userRepo.save(user);
        log.info("Profile updated for {}", email);
        return saved;
    }

    @Transactional
    public void deleteAccount(String email) {
        User user = getByEmail(email);
        userRepo.delete(user);
        log.info("Account deleted for {}", email);
    }
}
