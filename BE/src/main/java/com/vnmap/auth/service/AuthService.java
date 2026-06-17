package com.vnmap.auth.service;

import com.vnmap.auth.dto.AuthResponse;
import com.vnmap.auth.dto.AuthUserDto;
import com.vnmap.common.security.CurrentUser;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.time.Duration;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.Base64;

@Service
public class AuthService {

    private final JdbcTemplate jdbc;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final Duration refreshTtl;
    private final SecureRandom secureRandom = new SecureRandom();

    public AuthService(
            JdbcTemplate jdbc,
            PasswordEncoder passwordEncoder,
            JwtService jwtService,
            @Value("${security.jwt.refresh-token-ttl:${JWT_REFRESH_TOKEN_TTL:PT168H}}") Duration refreshTtl
    ) {
        this.jdbc = jdbc;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
        this.refreshTtl = refreshTtl;
    }

    @Transactional
    public AuthResponse login(String email, String password) {
        UserWithPassword user = findUserByEmail(email);
        if (!"ACTIVE".equals(user.status()) || !passwordEncoder.matches(password, user.passwordHash())) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Email or password is incorrect");
        }
        jdbc.update("UPDATE app_users SET last_login_at = CURRENT_TIMESTAMP WHERE id = ?", user.id());
        return issueTokens(user.toCurrentUser());
    }

    @Transactional
    public AuthResponse refresh(String refreshToken) {
        String hash = hash(refreshToken);
        RefreshRow token = jdbc.query(
                """
                SELECT rt.id, rt.user_id, rt.expires_at, rt.revoked_at
                FROM refresh_tokens rt
                WHERE rt.token_hash = ?
                """,
                (rs, rowNum) -> new RefreshRow(
                        rs.getLong("id"),
                        rs.getLong("user_id"),
                        rs.getObject("expires_at", LocalDateTime.class),
                        rs.getObject("revoked_at", LocalDateTime.class)
                ),
                hash
        ).stream().findFirst().orElseThrow(() ->
                new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid refresh token"));

        if (token.revokedAt() != null || token.expiresAt().isBefore(LocalDateTime.now(ZoneOffset.UTC))) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid refresh token");
        }
        jdbc.update("UPDATE refresh_tokens SET revoked_at = CURRENT_TIMESTAMP WHERE id = ?", token.id());
        CurrentUser user = findUserById(token.userId()).toCurrentUser();
        return issueTokens(user);
    }

    @Transactional
    public void logout(String refreshToken) {
        if (refreshToken == null || refreshToken.isBlank()) {
            return;
        }
        jdbc.update("UPDATE refresh_tokens SET revoked_at = CURRENT_TIMESTAMP WHERE token_hash = ?", hash(refreshToken));
    }

    public AuthUserDto me(CurrentUser user) {
        return new AuthUserDto(user.id(), user.email(), user.role(), user.status(), user.employeeId(), user.studentId());
    }

    public UserWithPassword findUserByEmail(String email) {
        return jdbc.query(
                """
                SELECT id, email, password_hash, role, status, employee_id, student_id
                FROM app_users
                WHERE LOWER(email) = LOWER(?)
                """,
                (rs, rowNum) -> new UserWithPassword(
                        rs.getLong("id"),
                        rs.getString("email"),
                        rs.getString("password_hash"),
                        rs.getString("role"),
                        rs.getString("status"),
                        rs.getObject("employee_id", Long.class),
                        rs.getObject("student_id", Long.class)
                ),
                email
        ).stream().findFirst().orElseThrow(() ->
                new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Email or password is incorrect"));
    }

    private UserWithPassword findUserById(long id) {
        return jdbc.query(
                """
                SELECT id, email, password_hash, role, status, employee_id, student_id
                FROM app_users
                WHERE id = ?
                """,
                (rs, rowNum) -> new UserWithPassword(
                        rs.getLong("id"),
                        rs.getString("email"),
                        rs.getString("password_hash"),
                        rs.getString("role"),
                        rs.getString("status"),
                        rs.getObject("employee_id", Long.class),
                        rs.getObject("student_id", Long.class)
                ),
                id
        ).stream().findFirst().orElseThrow(() ->
                new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid refresh token"));
    }

    private AuthResponse issueTokens(CurrentUser user) {
        String accessToken = jwtService.createAccessToken(user);
        String refreshToken = createRefreshToken();
        jdbc.update(
                """
                INSERT INTO refresh_tokens (user_id, token_hash, expires_at)
                VALUES (?, ?, ?)
                """,
                user.id(),
                hash(refreshToken),
                LocalDateTime.now(ZoneOffset.UTC).plus(refreshTtl)
        );
        return new AuthResponse(
                accessToken,
                refreshToken,
                "Bearer",
                jwtService.accessTokenExpiresInSeconds(),
                me(user)
        );
    }

    private String createRefreshToken() {
        byte[] bytes = new byte[48];
        secureRandom.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    private String hash(String token) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            return Base64.getEncoder().encodeToString(digest.digest(token.getBytes(StandardCharsets.UTF_8)));
        } catch (Exception ex) {
            throw new IllegalStateException("Unable to hash refresh token", ex);
        }
    }

    public record UserWithPassword(
            Long id,
            String email,
            String passwordHash,
            String role,
            String status,
            Long employeeId,
            Long studentId
    ) {
        CurrentUser toCurrentUser() {
            return new CurrentUser(id, email, role, status, employeeId, studentId);
        }
    }

    private record RefreshRow(Long id, Long userId, LocalDateTime expiresAt, LocalDateTime revokedAt) {
    }
}
