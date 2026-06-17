package com.vnmap.auth.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.vnmap.common.security.CurrentUser;
import org.junit.jupiter.api.Test;

import java.time.Duration;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class JwtServiceTest {

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Test
    void createsAndParsesAccessTokenWithClaims() {
        JwtService service = new JwtService(objectMapper, "test-secret", Duration.ofHours(1));
        CurrentUser user = new CurrentUser(1L, "staff@vnmap.local", "STAFF", "ACTIVE", 10L, null);

        CurrentUser parsed = service.parseAccessToken(service.createAccessToken(user));

        assertThat(parsed.id()).isEqualTo(1L);
        assertThat(parsed.email()).isEqualTo("staff@vnmap.local");
        assertThat(parsed.role()).isEqualTo("STAFF");
        assertThat(parsed.status()).isEqualTo("ACTIVE");
        assertThat(parsed.employeeId()).isEqualTo(10L);
        assertThat(parsed.studentId()).isNull();
        assertThat(service.accessTokenExpiresInSeconds()).isEqualTo(3600);
    }

    @Test
    void preservesStudentClaimWhenPresent() {
        JwtService service = new JwtService(objectMapper, "test-secret", Duration.ofMinutes(5));
        CurrentUser user = new CurrentUser(2L, "student@vnmap.local", "STUDENT", "ACTIVE", null, 99L);

        CurrentUser parsed = service.parseAccessToken(service.createAccessToken(user));

        assertThat(parsed.employeeId()).isNull();
        assertThat(parsed.studentId()).isEqualTo(99L);
    }

    @Test
    void rejectsMalformedToken() {
        JwtService service = new JwtService(objectMapper, "test-secret", Duration.ofHours(1));

        assertThatThrownBy(() -> service.parseAccessToken("not-a-jwt"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("Invalid token");
    }

    @Test
    void rejectsTamperedSignature() {
        JwtService service = new JwtService(objectMapper, "test-secret", Duration.ofHours(1));
        String token = service.createAccessToken(
                new CurrentUser(1L, "staff@vnmap.local", "STAFF", "ACTIVE", 10L, null)
        );
        String tampered = token.substring(0, token.length() - 2) + "xx";

        assertThatThrownBy(() -> service.parseAccessToken(tampered))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("Invalid token");
    }

    @Test
    void rejectsExpiredToken() {
        JwtService service = new JwtService(objectMapper, "test-secret", Duration.ofSeconds(-1));
        String token = service.createAccessToken(
                new CurrentUser(1L, "staff@vnmap.local", "STAFF", "ACTIVE", 10L, null)
        );

        assertThatThrownBy(() -> service.parseAccessToken(token))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("Invalid token");
    }
}
