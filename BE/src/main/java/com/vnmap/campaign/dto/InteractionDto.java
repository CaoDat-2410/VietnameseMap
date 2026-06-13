package com.vnmap.campaign.dto;

import java.time.LocalDateTime;

public record InteractionDto(
        Long id,
        Long campaignId,
        Long eventId,
        Long employeeId,
        String schoolUid,
        String participantType,
        Long participantId,
        String channel,
        String outcome,
        String note,
        LocalDateTime nextFollowUpAt,
        LocalDateTime createdAt
) {
}
