package com.vnmap.campaign.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

import java.time.LocalDateTime;

public record CreateInteractionRequest(
        @NotNull Long employeeId,
        @NotBlank String schoolUid,
        @NotBlank String participantType,
        @NotNull @Positive Long participantId,
        @NotBlank String channel,
        @NotBlank String outcome,
        String note,
        LocalDateTime nextFollowUpAt
) {
}
