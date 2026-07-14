package com.vnmap.campaign.dto;

import java.util.List;
import java.util.Map;

public record AggregateDashboardDto(
        long totalCampaigns,
        long totalEvents,
        long totalSchools,
        long totalEmployees,
        long totalInteractions,
        Map<String, Long> interactionsByOutcome,
        List<ProvinceInteractionDto> interactionsByProvince,
        List<TopSchoolDto> topSchools
) {
}
