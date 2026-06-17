package com.vnmap.auth.controller;

import com.vnmap.auth.dto.AuthResponse;
import com.vnmap.auth.dto.AuthUserDto;
import com.vnmap.auth.dto.LoginRequest;
import com.vnmap.auth.dto.LogoutRequest;
import com.vnmap.auth.dto.RefreshRequest;
import com.vnmap.auth.service.AuthService;
import com.vnmap.common.model.ApiResponse;
import com.vnmap.common.security.CurrentUser;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/login")
    public ResponseEntity<ApiResponse<AuthResponse>> login(@Valid @RequestBody LoginRequest request) {
        return ResponseEntity.ok(ApiResponse.success(
                authService.login(request.email(), request.password()),
                "Login successful"
        ));
    }

    @PostMapping("/refresh")
    public ResponseEntity<ApiResponse<AuthResponse>> refresh(@Valid @RequestBody RefreshRequest request) {
        return ResponseEntity.ok(ApiResponse.success(
                authService.refresh(request.refreshToken()),
                "Token refreshed successfully"
        ));
    }

    @PostMapping("/logout")
    public ResponseEntity<ApiResponse<Void>> logout(@RequestBody(required = false) LogoutRequest request) {
        authService.logout(request == null ? null : request.refreshToken());
        return ResponseEntity.ok(ApiResponse.success(null, "Logout successful"));
    }

    @GetMapping("/me")
    public ResponseEntity<ApiResponse<AuthUserDto>> me(@AuthenticationPrincipal CurrentUser user) {
        return ResponseEntity.ok(ApiResponse.success(authService.me(user), "Current user retrieved successfully"));
    }
}
