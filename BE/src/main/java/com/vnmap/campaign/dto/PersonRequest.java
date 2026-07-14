package com.vnmap.campaign.dto;

import jakarta.validation.constraints.NotBlank;

public record PersonRequest(
        @NotBlank String schoolUid,
        @NotBlank String fullName,
        @NotBlank String role
) {
}
