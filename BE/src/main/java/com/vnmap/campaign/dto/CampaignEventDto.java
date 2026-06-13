package com.vnmap.campaign.dto;

import java.time.LocalDateTime;

public record CampaignEventDto(
        Long id,
        Long campaignId,
        String name,
        String eventType,
        String status,
        LocalDateTime startsAt,
        LocalDateTime endsAt,
        String note
) {
}
