package com.vnmap.campaign.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.time.LocalDate;

public record CampaignRequest(
        @NotBlank String name,
        @NotBlank String status,
        String objective,
        LocalDate startDate,
        LocalDate endDate,
        @NotNull Long ownerEmployeeId
) {
}
