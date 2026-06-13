package com.vnmap.campaign.dto;

import java.util.List;
import java.util.Map;

public record CampaignDashboardDto(
        Long campaignId,
        long totalEvents,
        long totalTargetSchools,
        long totalAssignedEmployees,
        long totalInteractions,
        Map<String, Long> interactionsByOutcome,
        List<ProvinceInteractionDto> interactionsByProvince,
        List<TopSchoolDto> topSchools
) {
}
