package com.vnmap.auth.service;

import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseToken;
import com.vnmap.auth.dto.AuthResponse;
import com.vnmap.auth.dto.AuthUserDto;
import com.vnmap.common.security.CurrentUser;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class GoogleAuthServiceTest {
    private JdbcTemplate jdbc;
    private AuthService authService;
    private FirebaseAuth firebaseAuth;
    private RestTemplate restTemplate;
    private GoogleAuthService service;

    @BeforeEach
    void setUp() {
        jdbc = mock(JdbcTemplate.class);
        authService = mock(AuthService.class);
        firebaseAuth = mock(FirebaseAuth.class);
        restTemplate = mock(RestTemplate.class);
        service = new GoogleAuthService(jdbc, authService, firebaseAuth, restTemplate);
    }

    @Test
    void authenticatesKnownFirebaseUserAndIssuesTokens() throws Exception {
        FirebaseToken token = verifiedToken("uid-1", "student@vnmap.local", true);
        when(firebaseAuth.verifyIdToken("firebase-token")).thenReturn(token);
        stubUserLookups(List.of(9L));
        AuthResponse expected = authResponse();
        when(authService.findUserById(9L)).thenReturn(user());
        when(authService.issueTokens(any(CurrentUser.class))).thenReturn(expected);

        AuthResponse actual = service.authenticateWithGoogle("firebase-token");

        assertThat(actual).isSameAs(expected);
        verify(jdbc).update("UPDATE app_users SET last_login_at = CURRENT_TIMESTAMP WHERE id = ?", 9L);
    }

    @Test
    void linksExistingEmailWhenFirebaseVerificationFallsBackToGoogle() throws Exception {
        when(firebaseAuth.verifyIdToken("google-token")).thenThrow(new IllegalArgumentException("not firebase"));
        when(restTemplate.getForObject(anyString(), eq(Map.class))).thenReturn(Map.of(
                "sub", "google-uid", "email", "student@vnmap.local", "name", "Student",
                "picture", "https://example.test/pic", "email_verified", "true"));
        stubUserLookups(List.of(), List.of(12L));
        when(authService.findUserById(12L)).thenReturn(user());
        when(authService.issueTokens(any(CurrentUser.class))).thenReturn(authResponse());

        service.authenticateWithGoogle("google-token");

        verify(jdbc).update(anyString(), eq("google-uid"), eq(12L));
        verify(jdbc).update("UPDATE app_users SET last_login_at = CURRENT_TIMESTAMP WHERE id = ?", 12L);
    }

    @Test
    void rejectsUnverifiedGoogleAccount() throws Exception {
        FirebaseToken token = verifiedToken("uid", "student@vnmap.local", false);
        when(firebaseAuth.verifyIdToken("token")).thenReturn(token);

        assertThatThrownBy(() -> service.authenticateWithGoogle("token"))
                .isInstanceOf(ResponseStatusException.class)
                .extracting(error -> ((ResponseStatusException) error).getStatusCode())
                .isEqualTo(HttpStatus.BAD_REQUEST);
    }

    @Test
    void rejectsInvalidGoogleTokenWhenBothVerifiersFail() throws Exception {
        when(firebaseAuth.verifyIdToken("bad")).thenThrow(new IllegalArgumentException("bad token"));
        when(restTemplate.getForObject(anyString(), eq(Map.class))).thenThrow(new IllegalArgumentException("bad token"));

        assertThatThrownBy(() -> service.authenticateWithGoogle("bad"))
                .isInstanceOf(ResponseStatusException.class)
                .hasMessageContaining("Invalid Google ID token");
    }

    private FirebaseToken verifiedToken(String uid, String email, boolean emailVerified) {
        FirebaseToken token = mock(FirebaseToken.class);
        when(token.getUid()).thenReturn(uid);
        when(token.getEmail()).thenReturn(email);
        when(token.isEmailVerified()).thenReturn(emailVerified);
        when(token.getClaims()).thenReturn(Map.of("name", "Student", "picture", "picture-url"));
        return token;
    }

    @SuppressWarnings({"unchecked", "rawtypes"})
    private void stubUserLookups(List<Long>... results) {
        java.util.concurrent.atomic.AtomicInteger index = new java.util.concurrent.atomic.AtomicInteger();
        when(jdbc.query(anyString(), any(RowMapper.class), any(Object[].class))).thenAnswer(invocation ->
                (List) results[Math.min(index.getAndIncrement(), results.length - 1)]);
    }

    private AuthService.UserWithPassword user() {
        return new AuthService.UserWithPassword(9L, "student@vnmap.local", "", "STUDENT", "ACTIVE", null, 1L);
    }

    private AuthResponse authResponse() {
        return new AuthResponse("access", "refresh", "Bearer", 3600,
                new AuthUserDto(9L, "student@vnmap.local", "STUDENT", "ACTIVE", null, 1L, null, "Student", null, true));
    }
}