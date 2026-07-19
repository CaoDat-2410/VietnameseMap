package com.vnmap.auth.controller;

import com.vnmap.auth.dto.AuthResponse;
import com.vnmap.auth.dto.AuthUserDto;
import com.vnmap.auth.dto.LoginRequest;
import com.vnmap.auth.dto.LogoutRequest;
import com.vnmap.auth.dto.RefreshRequest;
import com.vnmap.auth.service.AuthService;
import com.vnmap.common.security.CurrentUser;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class AuthControllerTest {

    private final AuthService authService = mock(AuthService.class);
    private final AuthController controller = new AuthController(authService);

    @Test
    void loginWrapsAuthResponse() {
        AuthResponse auth = authResponse();
        when(authService.login("staff@vnmap.local", "staff123")).thenReturn(auth);

        var response = controller.login(new LoginRequest("staff@vnmap.local", "staff123"));

        assertThat(response.getStatusCode().is2xxSuccessful()).isTrue();
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().isSuccess()).isTrue();
        assertThat(response.getBody().getMessage()).isEqualTo("Login successful");
        assertThat(response.getBody().getData()).isSameAs(auth);
    }

    @Test
    void refreshWrapsAuthResponse() {
        AuthResponse auth = authResponse();
        when(authService.refresh("refresh")).thenReturn(auth);

        var response = controller.refresh(new RefreshRequest("refresh"));

        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().getMessage()).isEqualTo("Token refreshed successfully");
        assertThat(response.getBody().getData()).isSameAs(auth);
    }

    @Test
    void logoutAcceptsNullBody() {
        var response = controller.logout(null);

        verify(authService).logout(null);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().getMessage()).isEqualTo("Logout successful");
    }

    @Test
    void logoutUsesRefreshTokenWhenProvided() {
        controller.logout(new LogoutRequest("refresh"));

        verify(authService).logout("refresh");
    }

    @Test
    void meWrapsCurrentUser() {
        CurrentUser currentUser = new CurrentUser(1L, "admin@vnmap.local", "ADMIN", "ACTIVE", 1L, null);
        AuthUserDto dto = new AuthUserDto(1L, "admin@vnmap.local", "ADMIN", "ACTIVE", 1L, null, null, "Admin User", null, false);
        when(authService.me(currentUser)).thenReturn(dto);

        var response = controller.me(currentUser);

        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().getMessage()).isEqualTo("Current user retrieved successfully");
        assertThat(response.getBody().getData()).isSameAs(dto);
    }

    private AuthResponse authResponse() {
        return new AuthResponse(
                "access",
                "refresh",
                "Bearer",
                3600,
                new AuthUserDto(1L, "staff@vnmap.local", "STAFF", "ACTIVE", 1L, null, null, "Staff User", null, false)
        );
    }
}
