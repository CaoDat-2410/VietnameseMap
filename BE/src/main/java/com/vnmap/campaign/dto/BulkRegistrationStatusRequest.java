package com.vnmap.campaign.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.util.List;

public record BulkRegistrationStatusRequest(
        @NotBlank String status,
        @Size(min = 1, max = 200) List<Long> ids
) {
}