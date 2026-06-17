package com.vnmap.auth.service;

import com.vnmap.auth.dto.AuthResponse;
import com.vnmap.auth.dto.AuthUserDto;
import com.vnmap.common.security.CurrentUser;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.server.ResponseStatusException;

import java.sql.ResultSet;
import java.time.Duration;
import java.time.LocalDateTime;
import java.time.Month;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class AuthServiceTest {

    private static final LocalDateTime FUTURE_REFRESH_EXPIRY = LocalDateTime.of(2099, Month.JANUARY, 1, 0, 0);
    private static final LocalDateTime PAST_REFRESH_EXPIRY = LocalDateTime.of(2000, Month.JANUARY, 1, 0, 0);

    private JdbcTemplate jdbc;
    private PasswordEncoder passwordEncoder;
    private JwtService jwtService;
    private AuthService service;

    @BeforeEach
    void setUp() {
        jdbc = mock(JdbcTemplate.class);
        passwordEncoder = mock(PasswordEncoder.class);
        jwtService = mock(JwtService.class);
        service = new AuthService(jdbc, passwordEncoder, jwtService, Duration.ofDays(7));
    }

    @Test
    void loginIssuesTokensForActiveUserWithMatchingPassword() throws Exception {
        stubUserQuery(userResult(1L, "staff@vnmap.local", "hash", "STAFF", "ACTIVE", 10L, null));
        when(passwordEncoder.matches("staff123", "hash")).thenReturn(true);
        when(jwtService.createAccessToken(any(CurrentUser.class))).thenReturn("access-token");
        when(jwtService.accessTokenExpiresInSeconds()).thenReturn(3600L);

        AuthResponse response = service.login("staff@vnmap.local", "staff123");

        assertThat(response.accessToken()).isEqualTo("access-token");
        assertThat(response.refreshToken()).isNotBlank();
        assertThat(response.tokenType()).isEqualTo("Bearer");
        assertThat(response.expiresIn()).isEqualTo(3600L);
        assertThat(response.user().role()).isEqualTo("STAFF");
        verify(jdbc).update("UPDATE app_users SET last_login_at = CURRENT_TIMESTAMP WHERE id = ?", 1L);
    }

    @Test
    void loginRejectsWrongPassword() throws Exception {
        stubUserQuery(userResult(1L, "staff@vnmap.local", "hash", "STAFF", "ACTIVE", 10L, null));
        when(passwordEncoder.matches("bad", "hash")).thenReturn(false);

        assertThatThrownBy(() -> service.login("staff@vnmap.local", "bad"))
                .isInstanceOf(ResponseStatusException.class)
                .hasMessageContaining("Email or password is incorrect");
    }

    @Test
    void loginRejectsDisabledUser() throws Exception {
        stubUserQuery(userResult(1L, "staff@vnmap.local", "hash", "STAFF", "DISABLED", 10L, null));
        when(passwordEncoder.matches("staff123", "hash")).thenReturn(true);

        assertThatThrownBy(() -> service.login("staff@vnmap.local", "staff123"))
                .isInstanceOf(ResponseStatusException.class)
                .hasMessageContaining("Email or password is incorrect");
    }

    @Test
    void loginRejectsUnknownEmail() {
        stubUserQuery(List.of());

        assertThatThrownBy(() -> service.login("missing@vnmap.local", "staff123"))
                .isInstanceOf(ResponseStatusException.class)
                .hasMessageContaining("Email or password is incorrect");
    }

    @Test
    void refreshRotatesValidRefreshToken() throws Exception {
        stubRefreshQuery(5L, 1L, FUTURE_REFRESH_EXPIRY, null);
        stubUserByIdQuery(userResult(1L, "staff@vnmap.local", "hash", "STAFF", "ACTIVE", 10L, null));
        when(jwtService.createAccessToken(any(CurrentUser.class))).thenReturn("new-access");
        when(jwtService.accessTokenExpiresInSeconds()).thenReturn(3600L);

        AuthResponse response = service.refresh("refresh-token");

        assertThat(response.accessToken()).isEqualTo("new-access");
        assertThat(response.refreshToken()).isNotEqualTo("refresh-token");
        verify(jdbc).update("UPDATE refresh_tokens SET revoked_at = CURRENT_TIMESTAMP WHERE id = ?", 5L);
    }

    @Test
    void refreshRejectsMissingToken() {
        stubRefreshQuery(List.of());

        assertThatThrownBy(() -> service.refresh("missing"))
                .isInstanceOf(ResponseStatusException.class)
                .hasMessageContaining("Invalid refresh token");
    }

    @Test
    void refreshRejectsExpiredToken() throws Exception {
        stubRefreshQuery(5L, 1L, PAST_REFRESH_EXPIRY, null);

        assertThatThrownBy(() -> service.refresh("expired"))
                .isInstanceOf(ResponseStatusException.class)
                .hasMessageContaining("Invalid refresh token");
    }

    @Test
    void refreshRejectsRevokedToken() throws Exception {
        stubRefreshQuery(5L, 1L, FUTURE_REFRESH_EXPIRY, PAST_REFRESH_EXPIRY);

        assertThatThrownBy(() -> service.refresh("revoked"))
                .isInstanceOf(ResponseStatusException.class)
                .hasMessageContaining("Invalid refresh token");
    }

    @Test
    void logoutIgnoresBlankRefreshToken() {
        assertThatCode(() -> service.logout(" "))
                .doesNotThrowAnyException();
    }

    @Test
    void logoutRevokesRefreshTokenHash() {
        service.logout("refresh-token");

        verify(jdbc).update(
                org.mockito.ArgumentMatchers.eq("UPDATE refresh_tokens SET revoked_at = CURRENT_TIMESTAMP WHERE token_hash = ?"),
                anyString()
        );
    }

    @Test
    void meMapsCurrentUser() {
        AuthUserDto me = service.me(new CurrentUser(1L, "admin@vnmap.local", "ADMIN", "ACTIVE", 1L, null));

        assertThat(me.id()).isEqualTo(1L);
        assertThat(me.email()).isEqualTo("admin@vnmap.local");
        assertThat(me.role()).isEqualTo("ADMIN");
        assertThat(me.employeeId()).isEqualTo(1L);
        assertThat(me.studentId()).isNull();
    }

    @SuppressWarnings({"unchecked", "rawtypes"})
    private void stubUserQuery(List<AuthService.UserWithPassword> result) {
        when(jdbc.query(anyString(), any(RowMapper.class), any(Object[].class))).thenReturn((List) result);
    }

    @SuppressWarnings({"unchecked", "rawtypes"})
    private void stubUserByIdQuery(List<AuthService.UserWithPassword> result) {
        when(jdbc.query(anyString(), any(RowMapper.class), org.mockito.ArgumentMatchers.eq(1L)))
                .thenReturn((List) result);
    }

    @SuppressWarnings({"unchecked", "rawtypes"})
    private void stubRefreshQuery(List<?> result) {
        when(jdbc.query(anyString(), any(RowMapper.class), anyString())).thenReturn((List) result);
    }

    @SuppressWarnings({"unchecked", "rawtypes"})
    private void stubRefreshQuery(
            Long id,
            Long userId,
            LocalDateTime expiresAt,
            LocalDateTime revokedAt
    ) throws Exception {
        when(jdbc.query(anyString(), any(RowMapper.class), anyString())).thenAnswer(invocation -> {
            RowMapper mapper = invocation.getArgument(1);
            ResultSet rs = mock(ResultSet.class);
            when(rs.getLong("id")).thenReturn(id);
            when(rs.getLong("user_id")).thenReturn(userId);
            when(rs.getObject("expires_at", LocalDateTime.class)).thenReturn(expiresAt);
            when(rs.getObject("revoked_at", LocalDateTime.class)).thenReturn(revokedAt);
            return List.of(mapper.mapRow(rs, 0));
        });
    }

    private List<AuthService.UserWithPassword> userResult(
            Long id,
            String email,
            String passwordHash,
            String role,
            String status,
            Long employeeId,
            Long studentId
    ) throws Exception {
        ResultSet rs = mock(ResultSet.class);
        when(rs.getLong("id")).thenReturn(id);
        when(rs.getString("email")).thenReturn(email);
        when(rs.getString("password_hash")).thenReturn(passwordHash);
        when(rs.getString("role")).thenReturn(role);
        when(rs.getString("status")).thenReturn(status);
        when(rs.getObject("employee_id", Long.class)).thenReturn(employeeId);
        when(rs.getObject("student_id", Long.class)).thenReturn(studentId);
        RowMapper<AuthService.UserWithPassword> mapper = (row, rowNum) -> new AuthService.UserWithPassword(
                row.getLong("id"),
                row.getString("email"),
                row.getString("password_hash"),
                row.getString("role"),
                row.getString("status"),
                row.getObject("employee_id", Long.class),
                row.getObject("student_id", Long.class)
        );
        return List.of(mapper.mapRow(rs, 0));
    }

}
