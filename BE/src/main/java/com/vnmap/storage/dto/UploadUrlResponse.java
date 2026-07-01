package com.vnmap.storage.dto;

/**
 * Response containing a pre-signed upload URL for Firebase Storage.
 */
public record UploadUrlResponse(
        String uploadUrl,
        String publicUrl,
        String storagePath,
        long expiresAtSeconds
) {}
