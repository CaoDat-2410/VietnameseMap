package com.vnmap.auth.controller;

import com.vnmap.auth.dto.AuthResponse;
import com.vnmap.auth.dto.GoogleAuthRequest;
import com.vnmap.auth.service.GoogleAuthService;
import com.vnmap.common.model.ApiResponse;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/auth")
public class GoogleAuthController {

    private final GoogleAuthService googleAuthService;

    public GoogleAuthController(GoogleAuthService googleAuthService) {
        this.googleAuthService = googleAuthService;
    }

    /**
     * Exchange a Google ID token for app JWT tokens.
     *
     * POST /api/v1/auth/google
     * Body: { "idToken": "<google-id-token>" }
     * Returns: { "accessToken", "refreshToken", "tokenType", "expiresIn", "user" }
     *
     * Auto-provisions a STUDENT account if the Google user has not logged in before.
     */
    @PostMapping("/google")
    public ResponseEntity<ApiResponse <AuthResponse>> googleAuth(
            @Valid @RequestBody GoogleAuthRequest request
    ) {
        AuthResponse authResponse = googleAuthService.authenticateWithGoogle(request.idToken());
        return ResponseEntity.ok(ApiResponse.success(authResponse, "Google authentication successful"));
    }
}
