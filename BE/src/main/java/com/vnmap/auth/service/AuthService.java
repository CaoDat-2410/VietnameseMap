package com.vnmap.auth.service;

import com.vnmap.auth.dto.AuthResponse;
import com.vnmap.auth.dto.AuthUserDto;
import com.vnmap.auth.dto.ChangePasswordRequest;
import com.vnmap.auth.dto.UpdateProfileRequest;
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
import java.util.Map;

@Service
public class AuthService {
    private static final String PASSWORD_HASH_COLUMN = "password_hash";
    private static final String EMAIL_COLUMN = "email";
    private static final String STATUS_COLUMN = "status";
    private static final String EMPLOYEE_ID_COLUMN = "employee_id";
    private static final String STUDENT_ID_COLUMN = "student_id";

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
        return loadUserDto(user.id());
    }

    @Transactional
    public AuthUserDto updateProfile(CurrentUser user, UpdateProfileRequest request) {
        updateAvatar(user, request.avatarObjectKey());
        updateFullName(user, request.fullName());
        updatePhone(user, request.phone());
        return loadUserDto(user.id());
    }

    private void updateAvatar(CurrentUser user, String avatarObjectKey) {
        if (avatarObjectKey == null) return;
        String avatar = avatarObjectKey.isBlank() ? null : avatarObjectKey;
        if (avatar != null && avatar.length() > 255) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "avatarObjectKey is too long");
        }
        jdbc.update("UPDATE app_users SET avatar_object_key = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?", avatar, user.id());
    }

    private void updateFullName(CurrentUser user, String fullName) {
        if (fullName == null) return;
        String name = fullName.trim();
        validateFullName(name);
        int updated = updateAssociatedName(user, name);
        if (updated == 0) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Associated employee/student record not found");
        }
        touchUser(user.id());
    }

    private void validateFullName(String name) {
        if (name.isEmpty()) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "fullName must not be blank");
        if (name.length() > 255) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "fullName is too long");
    }

    private int updateAssociatedName(CurrentUser user, String name) {
        if (user.employeeId() != null) return jdbc.update("UPDATE employees SET full_name = ? WHERE id = ?", name, user.employeeId());
        if (user.studentId() != null) return jdbc.update("UPDATE students SET full_name = ? WHERE id = ?", name, user.studentId());
        throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Cannot update fullName: user has no associated employee or student record");
    }

    private void updatePhone(CurrentUser user, String requestedPhone) {
        if (requestedPhone == null) return;
        if (user.studentId() == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Phone can only be updated for student accounts");
        }
        String phone = requestedPhone.trim();
        if (phone.length() > 50) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "phone is too long");
        jdbc.update("UPDATE students SET phone = ? WHERE id = ?", phone.isEmpty() ? null : phone, user.studentId());
        touchUser(user.id());
    }

    private void touchUser(long userId) {
        jdbc.update("UPDATE app_users SET updated_at = CURRENT_TIMESTAMP WHERE id = ?", userId);
    }
    @Transactional
    public void changePassword(CurrentUser user, ChangePasswordRequest request) {
        if (request.newPassword().equals(request.currentPassword())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "New password must be different from the current password");
        }
        Map<String, Object> row = jdbc.queryForMap(
                """
                SELECT password_hash, firebase_uid
                FROM app_users
                WHERE id = ?
                """,
                user.id()
        );
        String currentHash = (String) row.get(PASSWORD_HASH_COLUMN);
        Object firebaseUid = row.get("firebase_uid");
        if (firebaseUid != null || currentHash == null || currentHash.isBlank()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Password cannot be changed for accounts signed in with Google"
            );
        }
        if (!passwordEncoder.matches(request.currentPassword(), currentHash)) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Current password is incorrect");
        }
        jdbc.update(
                "UPDATE app_users SET password_hash = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?",
                passwordEncoder.encode(request.newPassword()),
                user.id()
        );
    }

    private AuthUserDto loadUserDto(long userId) {
        Map<String, Object> row = jdbc.queryForMap(
                """
                SELECT u.id, u.email, u.role, u.status, u.employee_id, u.student_id,
                       u.avatar_object_key, u.firebase_uid,
                       e.full_name AS employee_name,
                       s.full_name AS student_name,
                       s.phone AS student_phone
                FROM app_users u
                LEFT JOIN employees e ON e.id = u.employee_id
                LEFT JOIN students s ON s.id = u.student_id
                WHERE u.id = ?
                """,
                userId
        );
        String fullName = (String) row.get("employee_name");
        if (fullName == null || fullName.isBlank()) {
            fullName = (String) row.get("student_name");
        }
        Object firebaseUid = row.get("firebase_uid");
        return new AuthUserDto(
                ((Number) row.get("id")).longValue(),
                (String) row.get(EMAIL_COLUMN),
                (String) row.get("role"),
                (String) row.get(STATUS_COLUMN),
                row.get(EMPLOYEE_ID_COLUMN) == null ? null : ((Number) row.get(EMPLOYEE_ID_COLUMN)).longValue(),
                row.get(STUDENT_ID_COLUMN) == null ? null : ((Number) row.get(STUDENT_ID_COLUMN)).longValue(),
                (String) row.get("avatar_object_key"),
                fullName,
                (String) row.get("student_phone"),
                firebaseUid != null
        );
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
                        rs.getString(EMAIL_COLUMN),
                        rs.getString(PASSWORD_HASH_COLUMN),
                        rs.getString("role"),
                        rs.getString(STATUS_COLUMN),
                        rs.getObject(EMPLOYEE_ID_COLUMN, Long.class),
                        rs.getObject(STUDENT_ID_COLUMN, Long.class)
                ),
                email
        ).stream().findFirst().orElseThrow(() ->
                new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Email or password is incorrect"));
    }

    UserWithPassword findUserById(long id) {
        return jdbc.query(
                """
                SELECT id, email, password_hash, role, status, employee_id, student_id
                FROM app_users
                WHERE id = ?
                """,
                (rs, rowNum) -> new UserWithPassword(
                        rs.getLong("id"),
                        rs.getString(EMAIL_COLUMN),
                        rs.getString(PASSWORD_HASH_COLUMN),
                        rs.getString("role"),
                        rs.getString(STATUS_COLUMN),
                        rs.getObject(EMPLOYEE_ID_COLUMN, Long.class),
                        rs.getObject(STUDENT_ID_COLUMN, Long.class)
                ),
                id
        ).stream().findFirst().orElseThrow(() ->
                new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid refresh token"));
    }

    AuthResponse issueTokens(CurrentUser user) {
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
                loadUserDto(user.id())
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
