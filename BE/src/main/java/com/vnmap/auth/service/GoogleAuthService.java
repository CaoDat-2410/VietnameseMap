package com.vnmap.auth.service;

import com.vnmap.auth.dto.AuthResponse;
import com.vnmap.auth.dto.GoogleIdTokenPayload;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.server.ResponseStatusException;

import java.sql.PreparedStatement;
import java.util.List;
import java.util.Map;
import java.util.Optional;

/**
 * Handles Google ID Token verification and user provisioning.
 *
 * Flow:
 *  1. Verify token via Google's tokeninfo endpoint
 *  2. Look up existing user by google_subject (sub) or email
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
    private final RestTemplate restTemplate;

    public GoogleAuthService(
            JdbcTemplate jdbc,
            AuthService authService,
            RestTemplate restTemplate
    ) {
        this.jdbc = jdbc;
        this.authService = authService;
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

        Long userId = findUserByGoogleSubject(payload.sub())
                .or(() -> findUserByEmail(payload.email()))
                .orElse(null);

        if (userId == null) {
            userId = provisionUser(payload);
            log.info("Auto-provisioned new Google user: {} (id={})", payload.email(), userId);
        }

        AuthService.UserWithPassword user = authService.findUserById(userId);
        return authService.issueTokens(user.toCurrentUser());
    }

    /**
     * Verifies the Google ID token via Google's tokeninfo endpoint.
     * This confirms the token was signed by Google and is not expired.
     */
    @SuppressWarnings("unchecked")
    private GoogleIdTokenPayload verifyAndDecode(String idToken) {
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

    private Optional<Long> findUserByGoogleSubject(String subject) {
        return jdbc.query(
                "SELECT id FROM app_users WHERE google_subject = ?",
                (rs, rowNum) -> rs.getLong("id"),
                subject
        ).stream().findFirst();
    }

    private Optional<Long> findUserByEmail(String email) {
        return jdbc.query(
                "SELECT id FROM app_users WHERE LOWER(email) = LOWER(?)",
                (rs, rowNum) -> rs.getLong("id"),
                email
        ).stream().findFirst();
    }

    /**
     * Creates a new app_users row for a Google-authenticated user.
     * Role defaults to STUDENT — ADMIN can upgrade via the admin panel.
     */
    private long provisionUser(GoogleIdTokenPayload payload) {
        GeneratedKeyHolder keyHolder = new GeneratedKeyHolder();
        jdbc.update(connection -> {
            PreparedStatement ps = connection.prepareStatement(
                    """
                    INSERT INTO app_users (email, google_subject, role, status)
                    VALUES (?, ?, 'STUDENT', 'ACTIVE')
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
