package com.vnmap.campaign.dto;

import jakarta.validation.constraints.NotBlank;

import java.time.LocalDateTime;

public record CampaignEventRequest(
        @NotBlank String name,
        @NotBlank String eventType,
        @NotBlank String status,
        LocalDateTime startsAt,
        LocalDateTime endsAt,
        String note
) {
}
