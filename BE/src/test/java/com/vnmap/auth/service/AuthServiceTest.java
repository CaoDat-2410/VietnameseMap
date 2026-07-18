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
import java.util.HashMap;
import java.util.Map;

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
        when(jdbc.queryForMap(anyString(), org.mockito.ArgumentMatchers.anyLong()))
                .thenReturn(userDtoRow(1L, "admin@vnmap.local", "ADMIN", "ACTIVE", 1L, null));
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

    @Test
    void updateProfileUpdatesEmployeeAvatarAndName() {
        CurrentUser employee = new CurrentUser(1L, "employee@vnmap.local", "STAFF", "ACTIVE", 11L, null);
        when(jdbc.update("UPDATE employees SET full_name = ? WHERE id = ?", "Nguyen Van A", 11L)).thenReturn(1);

        AuthUserDto result = service.updateProfile(employee, new com.vnmap.auth.dto.UpdateProfileRequest("avatars/a.png", "  Nguyen Van A  ", null));

        assertThat(result.email()).isEqualTo("admin@vnmap.local");
        verify(jdbc).update("UPDATE app_users SET avatar_object_key = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?", "avatars/a.png", 1L);
        verify(jdbc).update("UPDATE employees SET full_name = ? WHERE id = ?", "Nguyen Van A", 11L);
    }

    @Test
    void updateProfileUpdatesStudentPhoneAndClearsBlankValue() {
        CurrentUser student = new CurrentUser(2L, "student@vnmap.local", "STUDENT", "ACTIVE", null, 22L);

        service.updateProfile(student, new com.vnmap.auth.dto.UpdateProfileRequest(null, null, "  "));

        verify(jdbc).update("UPDATE students SET phone = ? WHERE id = ?", null, 22L);
        verify(jdbc).update("UPDATE app_users SET updated_at = CURRENT_TIMESTAMP WHERE id = ?", 2L);
    }

    @Test
    void updateProfileRejectsInvalidFieldsAndMissingAssociation() {
        CurrentUser employee = new CurrentUser(1L, "employee@vnmap.local", "STAFF", "ACTIVE", 11L, null);
        CurrentUser unlinked = new CurrentUser(1L, "unlinked@vnmap.local", "STAFF", "ACTIVE", null, null);

        assertThatThrownBy(() -> service.updateProfile(employee, new com.vnmap.auth.dto.UpdateProfileRequest("x".repeat(256), null, null))).hasMessageContaining("avatarObjectKey is too long");
        assertThatThrownBy(() -> service.updateProfile(employee, new com.vnmap.auth.dto.UpdateProfileRequest(null, " ", null))).hasMessageContaining("fullName must not be blank");
        assertThatThrownBy(() -> service.updateProfile(unlinked, new com.vnmap.auth.dto.UpdateProfileRequest(null, "Name", null))).hasMessageContaining("no associated");
        assertThatThrownBy(() -> service.updateProfile(employee, new com.vnmap.auth.dto.UpdateProfileRequest(null, null, "090"))).hasMessageContaining("Phone can only");
    }

    @Test
    void changePasswordValidatesProviderCurrentPasswordAndUpdatesLocalAccount() {
        CurrentUser user = new CurrentUser(1L, "admin@vnmap.local", "ADMIN", "ACTIVE", 1L, null);
        when(jdbc.queryForMap(anyString(), org.mockito.ArgumentMatchers.eq(1L))).thenReturn(Map.of("password_hash", "hash", "firebase_uid", ""));
        assertThatThrownBy(() -> service.changePassword(user, new com.vnmap.auth.dto.ChangePasswordRequest("same", "same"))).hasMessageContaining("must be different");
        assertThatThrownBy(() -> service.changePassword(user, new com.vnmap.auth.dto.ChangePasswordRequest("old", "new"))).hasMessageContaining("signed in with Google");

        when(jdbc.queryForMap(anyString(), org.mockito.ArgumentMatchers.eq(1L))).thenReturn(Map.of("password_hash", "hash"));
        when(passwordEncoder.matches("bad", "hash")).thenReturn(false);
        assertThatThrownBy(() -> service.changePassword(user, new com.vnmap.auth.dto.ChangePasswordRequest("bad", "new"))).hasMessageContaining("Current password is incorrect");

        when(passwordEncoder.matches("old", "hash")).thenReturn(true);
        when(passwordEncoder.encode("new-password")).thenReturn("encoded");
        service.changePassword(user, new com.vnmap.auth.dto.ChangePasswordRequest("old", "new-password"));
        verify(jdbc).update("UPDATE app_users SET password_hash = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?", "encoded", 1L);
    }
    @Test
    void findUserMethodsExecuteRowMappersAndRejectMissingRows() throws Exception {
        when(jdbc.query(anyString(), any(RowMapper.class), org.mockito.ArgumentMatchers.eq("mapped@test")))
                .thenAnswer(invocation -> {
                    RowMapper<?> mapper = invocation.getArgument(1);
                    ResultSet rs = mock(ResultSet.class);
                    when(rs.getLong("id")).thenReturn(77L);
                    when(rs.getString("email")).thenReturn("mapped@test");
                    when(rs.getString("password_hash")).thenReturn("hash");
                    when(rs.getString("role")).thenReturn("STUDENT");
                    when(rs.getString("status")).thenReturn("ACTIVE");
                    when(rs.getObject("employee_id", Long.class)).thenReturn(null);
                    when(rs.getObject("student_id", Long.class)).thenReturn(8L);
                    return List.of(mapper.mapRow(rs, 0));
                });
        AuthService.UserWithPassword byEmail = service.findUserByEmail("mapped@test");
        assertThat(byEmail.id()).isEqualTo(77L);
        assertThat(byEmail.studentId()).isEqualTo(8L);

        when(jdbc.query(anyString(), any(RowMapper.class), org.mockito.ArgumentMatchers.eq(77L)))
                .thenAnswer(invocation -> {
                    RowMapper<?> mapper = invocation.getArgument(1);
                    ResultSet rs = mock(ResultSet.class);
                    when(rs.getLong("id")).thenReturn(77L);
                    when(rs.getString("email")).thenReturn("mapped@test");
                    when(rs.getString("password_hash")).thenReturn("hash");
                    when(rs.getString("role")).thenReturn("STUDENT");
                    when(rs.getString("status")).thenReturn("ACTIVE");
                    when(rs.getObject("employee_id", Long.class)).thenReturn(null);
                    when(rs.getObject("student_id", Long.class)).thenReturn(8L);
                    return List.of(mapper.mapRow(rs, 0));
                });
        assertThat(service.findUserById(77L).toCurrentUser().studentId()).isEqualTo(8L);

        when(jdbc.query(anyString(), any(RowMapper.class), org.mockito.ArgumentMatchers.eq("missing@test")))
                .thenReturn(List.of());
        assertThatThrownBy(() -> service.findUserByEmail("missing@test"))
                .isInstanceOf(ResponseStatusException.class);
        when(jdbc.query(anyString(), any(RowMapper.class), org.mockito.ArgumentMatchers.eq(99L)))
                .thenReturn(List.of());
        assertThatThrownBy(() -> service.findUserById(99L))
                .isInstanceOf(ResponseStatusException.class);
    }

    @Test
    void mapsStudentProfileAndCoversProfileValidationBranches() {
        Map<String, Object> studentRow = userDtoRow(2L, "student@test", "STUDENT", "ACTIVE", null, 22L);
        studentRow.put("student_name", "Student Name");
        studentRow.put("student_phone", "090");
        studentRow.put("firebase_uid", "firebase-uid");
        when(jdbc.queryForMap(anyString(), org.mockito.ArgumentMatchers.eq(2L))).thenReturn(studentRow);
        AuthUserDto mapped = service.me(new CurrentUser(2L, "student@test", "STUDENT", "ACTIVE", null, 22L));
        assertThat(mapped.fullName()).isEqualTo("Student Name");
        assertThat(mapped.phone()).isEqualTo("090");
        assertThat(mapped.firebaseUser()).isTrue();

        when(jdbc.update("UPDATE students SET full_name = ? WHERE id = ?", "Updated Student", 22L)).thenReturn(1);
        service.updateProfile(
                new CurrentUser(2L, "student@test", "STUDENT", "ACTIVE", null, 22L),
                new com.vnmap.auth.dto.UpdateProfileRequest(null, " Updated Student ", null)
        );
        verify(jdbc).update("UPDATE students SET full_name = ? WHERE id = ?", "Updated Student", 22L);

        CurrentUser employee = new CurrentUser(1L, "employee@test", "STAFF", "ACTIVE", 11L, null);
        com.vnmap.auth.dto.UpdateProfileRequest longName = new com.vnmap.auth.dto.UpdateProfileRequest(null, "x".repeat(256), null);
        com.vnmap.auth.dto.UpdateProfileRequest longPhone = new com.vnmap.auth.dto.UpdateProfileRequest(null, null, "1".repeat(51));
        assertThatThrownBy(() -> service.updateProfile(employee, longName)).hasMessageContaining("fullName is too long");
        CurrentUser student = new CurrentUser(2L, "student@test", "STUDENT", "ACTIVE", null, 22L);
        assertThatThrownBy(() -> service.updateProfile(student, longPhone)).hasMessageContaining("phone is too long");

        when(jdbc.update("UPDATE employees SET full_name = ? WHERE id = ?", "Missing", 11L)).thenReturn(0);
        com.vnmap.auth.dto.UpdateProfileRequest missingName = new com.vnmap.auth.dto.UpdateProfileRequest(null, "Missing", null);
        assertThatThrownBy(() -> service.updateProfile(employee, missingName)).hasMessageContaining("not found");
        service.updateProfile(employee, new com.vnmap.auth.dto.UpdateProfileRequest(" ", null, null));
        verify(jdbc).update("UPDATE app_users SET avatar_object_key = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?", null, 1L);
    }

    @Test
    void logoutAcceptsNullAndChangePasswordRejectsMissingLocalHash() {
        assertThatCode(() -> service.logout(null)).doesNotThrowAnyException();
        CurrentUser user = new CurrentUser(1L, "admin@vnmap.local", "ADMIN", "ACTIVE", 1L, null);
        Map<String, Object> noHash = new HashMap<>();
        noHash.put("password_hash", null);
        noHash.put("firebase_uid", null);
        when(jdbc.queryForMap(anyString(), org.mockito.ArgumentMatchers.eq(1L))).thenReturn(noHash);
        com.vnmap.auth.dto.ChangePasswordRequest request = new com.vnmap.auth.dto.ChangePasswordRequest("old", "new-password");
        assertThatThrownBy(() -> service.changePassword(user, request)).hasMessageContaining("Google");
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
        when(jdbc.queryForMap(anyString(), org.mockito.ArgumentMatchers.eq(id)))
                .thenReturn(userDtoRow(id, email, role, status, employeeId, studentId));        return List.of(mapper.mapRow(rs, 0));
    }

    private Map<String, Object> userDtoRow(Long id, String email, String role, String status, Long employeeId, Long studentId) {
        Map<String, Object> row = new HashMap<>();
        row.put("id", id); row.put("email", email); row.put("role", role); row.put("status", status);
        row.put("employee_id", employeeId); row.put("student_id", studentId); row.put("avatar_object_key", null); row.put("firebase_uid", null);
        row.put("employee_name", employeeId == null ? null : "Employee"); row.put("student_name", studentId == null ? null : "Student"); row.put("student_phone", null);
        return row;
    }
}
