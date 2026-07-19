package com.vnmap.campaign.dto;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;

import java.time.LocalDateTime;

public record CampaignEventRequest(
        @NotBlank String name,
        @NotBlank String eventType,
        @NotBlank String status,
        LocalDateTime startsAt,
        LocalDateTime endsAt,
        String note,
        String locationLabel,
        @DecimalMin(value = "8.0", message = "latitude must be within Vietnam bounds (8.0-23.5)")
        @DecimalMax(value = "23.5", message = "latitude must be within Vietnam bounds (8.0-23.5)")
        Double latitude,
        @DecimalMin(value = "102.0", message = "longitude must be within Vietnam bounds (102.0-109.5)")
        @DecimalMax(value = "109.5", message = "longitude must be within Vietnam bounds (102.0-109.5)")
        Double longitude,
        String schoolUid,
        String provinceCode
) {
}
