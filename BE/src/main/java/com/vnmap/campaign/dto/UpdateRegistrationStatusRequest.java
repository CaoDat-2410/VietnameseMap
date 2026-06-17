package com.vnmap.campaign.dto;

import jakarta.validation.constraints.NotBlank;

public record UpdateRegistrationStatusRequest(
        @NotBlank String status
) {
}
