package com.library.config;

import com.library.security.JwtAuthFilter;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

@Configuration
public class SecurityConfig {
    private final JwtAuthFilter jwtAuthFilter;
    private final List<String> allowedOrigins;

    public SecurityConfig(
            JwtAuthFilter jwtAuthFilter,
            @Value("${app.cors.allowed-origins}") String allowedOrigins
    ) {
        this.jwtAuthFilter = jwtAuthFilter;
        this.allowedOrigins = Arrays.stream(allowedOrigins.split(","))
                .map(String::trim)
                .filter(value -> !value.isBlank())
                .collect(Collectors.toList());
    }

    @Bean
    public BCryptPasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http.csrf(csrf -> csrf.disable());
        http.cors(cors -> cors.configurationSource(corsConfigurationSource()));
        http.authorizeHttpRequests(auth -> auth
                .requestMatchers(HttpMethod.POST, "/api/auth/register", "/api/auth/login", "/api/auth/refresh").permitAll()
                .requestMatchers(
                        "/v3/api-docs/**",
                        "/swagger-ui/**",
                        "/swagger-ui.html",
                        "/swagger-resources/**",
                        "/webjars/**"
                ).permitAll()
                .requestMatchers("/uploads/**").permitAll()
                .requestMatchers(HttpMethod.GET, "/api/books/**").permitAll()
                .requestMatchers(HttpMethod.POST, "/api/books/**").hasRole("ADMIN")
                .requestMatchers(HttpMethod.PUT, "/api/books/**").hasRole("ADMIN")
                .requestMatchers(HttpMethod.DELETE, "/api/books/**").hasRole("ADMIN")
                .requestMatchers("/api/users/**", "/api/favorites/**", "/api/reviews/**", "/api/history/**").authenticated()
                .requestMatchers("/api/admin/**").hasRole("ADMIN")
                .anyRequest().authenticated());
        http.addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class);
        return http.build();
    }

    @Bean
    public AuthenticationManager authManager(AuthenticationConfiguration config) throws Exception {
        return config.getAuthenticationManager();
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration config = new CorsConfiguration();
        config.setAllowedOrigins(allowedOrigins);
        config.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "OPTIONS"));
        config.setAllowedHeaders(List.of("Authorization", "Content-Type"));
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        return source;
    }
}
