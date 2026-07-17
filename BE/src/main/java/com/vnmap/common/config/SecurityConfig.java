package com.vnmap.common.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.vnmap.common.model.ApiError;
import com.vnmap.common.model.ApiResponse;
import com.vnmap.common.security.JwtAuthenticationFilter;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

import java.io.IOException;
import java.util.UUID;

@Configuration
public class SecurityConfig {

    private static final String ADMIN = "ADMIN";
    private static final String MANAGER = "MANAGER";
    private static final String STAFF = "STAFF";
    private static final String STUDENT = "STUDENT";
    private static final String EVENTS_API = "/api/v1/events/**";

    @Bean
    SecurityFilterChain securityFilterChain(
            HttpSecurity http,
            JwtAuthenticationFilter jwtAuthenticationFilter,
            ObjectMapper objectMapper
    ) throws Exception {
        http
                .csrf(AbstractHttpConfigurer::disable)
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .exceptionHandling(exceptions -> exceptions
                        .authenticationEntryPoint((request, response, authException) ->
                                writeError(request, response, objectMapper, HttpServletResponse.SC_UNAUTHORIZED, "UNAUTHORIZED", "Unauthorized"))
                        .accessDeniedHandler((request, response, accessDeniedException) ->
                                writeError(request, response, objectMapper, HttpServletResponse.SC_FORBIDDEN, "FORBIDDEN", "Forbidden"))
                )
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers(HttpMethod.POST, "/api/v1/auth/login", "/api/v1/auth/refresh", "/api/v1/auth/google").permitAll()
                        .requestMatchers(HttpMethod.GET, "/actuator/health").permitAll()
                        .requestMatchers(HttpMethod.GET, "/swagger-ui/**", "/api-docs/**", "/swagger-ui.html").permitAll()
                        .requestMatchers(HttpMethod.GET, "/api/v1/campaigns", "/api/v1/campaigns/*", "/api/v1/campaigns/*/events", EVENTS_API, "/api/v1/schools/**").hasAnyRole(STAFF, MANAGER, ADMIN, STUDENT)
                        .requestMatchers(HttpMethod.POST, "/api/v1/campaigns/*/student-registrations").hasAnyRole(STAFF, MANAGER, ADMIN, STUDENT)
                        .requestMatchers(HttpMethod.PUT, "/api/v1/student-registrations/*/status").hasAnyRole(STAFF, MANAGER, ADMIN)
                        .requestMatchers(HttpMethod.GET, "/api/v1/student-registrations/my").hasAnyRole(STAFF, MANAGER, ADMIN, STUDENT)
                        .requestMatchers(HttpMethod.GET, "/api/v1/campaigns/*/student-registrations").hasAnyRole(STAFF, MANAGER, ADMIN)
                        .requestMatchers(HttpMethod.GET, "/api/v1/staff/student-registrations").hasAnyRole(STAFF, MANAGER, ADMIN)
                        .requestMatchers(HttpMethod.POST, "/api/v1/student-registrations/bulk-status").hasAnyRole(STAFF, MANAGER, ADMIN)
                        .requestMatchers(HttpMethod.GET, "/api/v1/students/**", "/api/v1/persons/**", "/api/v1/student-relatives/**").hasAnyRole(STAFF, MANAGER, ADMIN)
                        .requestMatchers(HttpMethod.GET, "/api/v1/employees", "/api/v1/events/*/schools", "/api/v1/events/*/assignments").hasAnyRole(STAFF, MANAGER, ADMIN)
                        .requestMatchers(HttpMethod.GET, "/api/v1/campaigns/*/dashboard").hasAnyRole(MANAGER, ADMIN)
                        .requestMatchers(HttpMethod.POST, "/api/v1/events/*/interactions").hasAnyRole(STAFF, MANAGER, ADMIN)
                        .requestMatchers(HttpMethod.PUT, "/api/v1/events/*/interactions/*").hasAnyRole(STAFF, MANAGER, ADMIN)
                        .requestMatchers(HttpMethod.DELETE, "/api/v1/events/*/interactions/*").hasAnyRole(STAFF, MANAGER, ADMIN)
                        .requestMatchers("/api/v1/users/**").hasRole(ADMIN)
                        .requestMatchers("/api/v1/reports/**").hasAnyRole(MANAGER, ADMIN)
                        .requestMatchers(HttpMethod.POST, "/api/v1/employees").hasRole(ADMIN)
                        .requestMatchers(HttpMethod.PUT, "/api/v1/employees/**").hasRole(ADMIN)
                        .requestMatchers(HttpMethod.DELETE, "/api/v1/employees/**").hasRole(ADMIN)
                        .requestMatchers(HttpMethod.POST, "/api/v1/campaigns", "/api/v1/campaigns/*/events", "/api/v1/events/*/schools", "/api/v1/events/*/assignments").hasAnyRole(MANAGER, ADMIN)
                        .requestMatchers(HttpMethod.PUT, "/api/v1/campaigns/**", EVENTS_API).hasAnyRole(MANAGER, ADMIN)
                        .requestMatchers(HttpMethod.DELETE, "/api/v1/campaigns/**", EVENTS_API).hasAnyRole(MANAGER, ADMIN)
                        .requestMatchers("/api/v1/students/**", "/api/v1/persons/**", "/api/v1/student-relatives/**").hasAnyRole(MANAGER, ADMIN)
                        .requestMatchers(HttpMethod.POST, "/api/v1/geo/admin/calculate-centroids").hasAnyRole(MANAGER, ADMIN)
                        .requestMatchers("/api/v1/geo/**", "/api/v1/weather/**").permitAll()
                        .requestMatchers("/api/analytics/**").hasAnyRole(STAFF, MANAGER, ADMIN)
                        .requestMatchers(HttpMethod.POST, "/api/v1/notifications/token").authenticated()
                        .requestMatchers(HttpMethod.DELETE, "/api/v1/notifications/token").authenticated()
                        .requestMatchers(HttpMethod.GET, "/api/v1/notifications", "/api/v1/notifications/unread-count").authenticated()
                        .requestMatchers(HttpMethod.PUT, "/api/v1/notifications/*/read").authenticated()
                        .requestMatchers(HttpMethod.POST, "/api/v1/notifications/read-all").authenticated()
                        .requestMatchers(HttpMethod.POST, "/api/v1/notifications/send").hasAnyRole(MANAGER, ADMIN)
                        .anyRequest().authenticated()
                )
                .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);
        return http.build();
    }

    @Bean
    PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    private void writeError(HttpServletRequest request, HttpServletResponse response, ObjectMapper objectMapper,
                            int status, String code, String message) throws IOException {
        String traceId = UUID.randomUUID().toString().substring(0, 8);
        ApiError details = new ApiError(status, code, request.getRequestURI(), traceId, null);
        response.setStatus(status);
        response.setContentType("application/json");
        objectMapper.writeValue(response.getWriter(), ApiResponse.error(message, details, traceId));
    }
}

