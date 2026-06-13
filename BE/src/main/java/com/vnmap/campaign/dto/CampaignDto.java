package com.vnmap.campaign.dto;

import java.time.LocalDate;

public record CampaignDto(
        Long id,
        String name,
        String status,
        String objective,
        LocalDate startDate,
        LocalDate endDate,
        Long ownerEmployeeId
) {
}
