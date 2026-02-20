package com.library.security;

import com.library.entity.User;
import com.library.repository.UserRepository;
import jakarta.servlet.*;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpHeaders;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.GenericFilterBean;
import java.io.IOException;
import java.util.Collections;

@Component
public class JwtAuthFilter extends GenericFilterBean {
    private final JwtService jwtService;
    private final UserRepository userRepo;

    public JwtAuthFilter(JwtService jwtService, UserRepository userRepo) {
        this.jwtService = jwtService;
        this.userRepo = userRepo;
    }

    @Override
    public void doFilter(ServletRequest req, ServletResponse res, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest request = (HttpServletRequest) req;
        String path = request.getRequestURI();
        if (path.startsWith("/v3/api-docs") || path.startsWith("/swagger-ui")) {
            chain.doFilter(req, res);
            return;
        }
        String authHeader = request.getHeader(HttpHeaders.AUTHORIZATION);

        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            String token = authHeader.substring(7);

            if (jwtService.isValid(token)) {
                String email = jwtService.extractEmail(token);
                User user = userRepo.findByEmail(email).orElse(null);
                if (user != null) {
                    var auth = new UsernamePasswordAuthenticationToken(
                            user.getEmail(), null,
                            Collections.singleton(() -> user.getRole()));
                    SecurityContextHolder.getContext().setAuthentication(auth);
                }
            }
        }
        chain.doFilter(req, res);
    }
}
