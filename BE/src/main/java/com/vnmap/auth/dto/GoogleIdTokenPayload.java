package com.vnmap.auth.dto;

/**
 * Parsed payload from a Google ID Token JWT.
 * The sub (subject) claim is Google's unique user ID.
 */
public record GoogleIdTokenPayload(
        String sub,
        String email,
        String name,
        String picture,
        boolean emailVerified
) {}
