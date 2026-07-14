package com.vnmap.auth.dto;

import jakarta.validation.constraints.Size;

public record UpdateProfileRequest(
        @Size(max = 255) String avatarObjectKey,
        @Size(max = 255) String fullName,
        @Size(max = 50) String phone
) {
}
