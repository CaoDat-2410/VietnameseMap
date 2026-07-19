package com.vnmap.storage.dto;

import jakarta.validation.constraints.NotBlank;

/**
 * Request to generate a signed upload URL for Firebase Storage.
 */
public record GenerateUploadUrlRequest(
        @NotBlank String fileName,
        @NotBlank String contentType,
        /** 'campaigns' | 'schools' | 'events' */
        @NotBlank String folder,
        /** Owner's user ID (for access control audit). */
        Long userId
) {}
