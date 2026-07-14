package com.vnmap.campaign.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record StudentRelativeRequest(
        @NotNull Long studentId,
        @NotBlank String schoolUid,
        @NotBlank String fullName,
        String relationship,
        String phone
) {
}
