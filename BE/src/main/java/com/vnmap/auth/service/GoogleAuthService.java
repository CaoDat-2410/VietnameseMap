package com.vnmap.auth.service;

import com.vnmap.auth.dto.AuthResponse;
import com.vnmap.auth.dto.GoogleIdTokenPayload;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseToken;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.server.ResponseStatusException;

import java.sql.PreparedStatement;
import java.util.Map;
import java.util.Optional;

/**
 * Handles Google ID Token verification and user provisioning.
 *
 * Flow:
 *  1. Verify Firebase ID token first, then fall back to Google tokeninfo
 *  2. Look up existing user by firebase_uid or email
 *  3. Auto-provision new user with role=STUDENT if not found
 *  4. Reuse existing token-issuing logic in AuthService
 */
@Service
public class GoogleAuthService {

    private static final Logger log = LoggerFactory.getLogger(GoogleAuthService.class);
    private static final String GOOGLE_TOKENINFO_URL =
            "https://oauth2.googleapis.com/tokeninfo";

    private final JdbcTemplate jdbc;
    private final AuthService authService;
    private final FirebaseAuth firebaseAuth;
    private final RestTemplate restTemplate;

    public GoogleAuthService(
            JdbcTemplate jdbc,
            AuthService authService,
            FirebaseAuth firebaseAuth,
            RestTemplate restTemplate
    ) {
        this.jdbc = jdbc;
        this.authService = authService;
        this.firebaseAuth = firebaseAuth;
        this.restTemplate = restTemplate;
    }

    /**
     * Verifies a Google ID token and returns an AuthResponse (same shape as password login).
     * Auto-provisions a new STUDENT account if the Google user has not logged in before.
     */
    @Transactional
    public AuthResponse authenticateWithGoogle(String idToken) {
        GoogleIdTokenPayload payload = verifyAndDecode(idToken);

        if (!payload.emailVerified()) {
            throw new ResponseStatusException(
                    org.springframework.http.HttpStatus.BAD_REQUEST,
                    "Google account email is not verified");
        }

        Long userId = findUserByFirebaseUid(payload.sub()).orElse(null);

        if (userId == null) {
            Optional<Long> existingUserId = findUserByEmail(payload.email());
            if (existingUserId.isPresent()) {
                userId = existingUserId.get();
                linkFirebaseUid(userId, payload.sub());
            } else {
                userId = provisionUser(payload);
                log.info("Auto-provisioned new Firebase user: {} (id={})", payload.email(), userId);
            }
        }

        jdbc.update("UPDATE app_users SET last_login_at = CURRENT_TIMESTAMP WHERE id = ?", userId);
        AuthService.UserWithPassword user = authService.findUserById(userId);
        return authService.issueTokens(user.toCurrentUser());
    }

    /**
     * Verifies the Google ID token via Google's tokeninfo endpoint.
     * This confirms the token was signed by Google and is not expired.
     */
    @SuppressWarnings("unchecked")
    private GoogleIdTokenPayload verifyAndDecode(String idToken) {
        GoogleIdTokenPayload firebasePayload = verifyFirebaseIdToken(idToken);
        if (firebasePayload != null) {
            return firebasePayload;
        }

        try {
            String tokenInfoUrl = GOOGLE_TOKENINFO_URL + "?id_token=" + idToken;
            Map<String, Object> tokenInfo = restTemplate.getForObject(tokenInfoUrl, Map.class);

            if (tokenInfo == null) {
                throw new ResponseStatusException(
                        org.springframework.http.HttpStatus.BAD_REQUEST,
                        "Invalid Google ID token");
            }

            String sub = (String) tokenInfo.get("sub");
            String email = (String) tokenInfo.get("email");
            String name = (String) tokenInfo.get("name");
            String picture = (String) tokenInfo.get("picture");
            String emailVerifiedRaw =
                    String.valueOf(tokenInfo.getOrDefault("email_verified", "false"));
            boolean emailVerified = "true".equalsIgnoreCase(emailVerifiedRaw);

            return new GoogleIdTokenPayload(sub, email, name, picture, emailVerified);
        } catch (ResponseStatusException e) {
            throw e;
        } catch (Exception e) {
            log.error("Failed to verify Google ID token: {}", e.getMessage());
            throw new ResponseStatusException(
                    org.springframework.http.HttpStatus.BAD_REQUEST,
                    "Invalid Google ID token");
        }
    }

    private GoogleIdTokenPayload verifyFirebaseIdToken(String idToken) {
        try {
            FirebaseToken token = firebaseAuth.verifyIdToken(idToken);
            String email = token.getEmail();
            if (email == null || email.isBlank()) {
                throw new ResponseStatusException(
                        org.springframework.http.HttpStatus.BAD_REQUEST,
                        "Firebase ID token does not contain an email");
            }
            String name = stringClaim(token, "name");
            String picture = stringClaim(token, "picture");
            boolean emailVerified = Boolean.TRUE.equals(token.isEmailVerified());

            return new GoogleIdTokenPayload(token.getUid(), email, name, picture, emailVerified);
        } catch (ResponseStatusException e) {
            throw e;
        } catch (Exception e) {
            log.debug("Token is not a Firebase ID token: {}", e.getMessage());
            return null;
        }
    }

    private String stringClaim(FirebaseToken token, String key) {
        Object value = token.getClaims().get(key);
        return value == null ? null : String.valueOf(value);
    }

    private Optional<Long> findUserByFirebaseUid(String uid) {
        return jdbc.query(
                "SELECT id FROM app_users WHERE firebase_uid = ?",
                (rs, rowNum) -> rs.getLong("id"),
                uid
        ).stream().findFirst();
    }

    private Optional<Long> findUserByEmail(String email) {
        return jdbc.query(
                "SELECT id FROM app_users WHERE LOWER(email) = LOWER(?)",
                (rs, rowNum) -> rs.getLong("id"),
                email
        ).stream().findFirst();
    }

    private void linkFirebaseUid(long userId, String uid) {
        jdbc.update(
                """
                UPDATE app_users
                SET firebase_uid = ?, updated_at = CURRENT_TIMESTAMP
                WHERE id = ? AND firebase_uid IS NULL
                """,
                uid,
                userId
        );
    }

    /**
     * Creates a new app_users row for a Firebase-authenticated user.
     * Role defaults to STUDENT - ADMIN can upgrade via the admin panel.
     */
    private long provisionUser(GoogleIdTokenPayload payload) {
        GeneratedKeyHolder keyHolder = new GeneratedKeyHolder();
        jdbc.update(connection -> {
            PreparedStatement ps = connection.prepareStatement(
                    """
                    INSERT INTO app_users (email, password_hash, firebase_uid, role, status)
                    VALUES (?, '', ?, 'STUDENT', 'ACTIVE')
                    """,
                    PreparedStatement.RETURN_GENERATED_KEYS
            );
            ps.setString(1, payload.email());
            ps.setString(2, payload.sub());
            return ps;
        }, keyHolder);
        Number key = keyHolder.getKey();
        if (key == null) {
            throw new IllegalStateException("Insert did not return generated key");
        }
        return key.longValue();
    }
}
