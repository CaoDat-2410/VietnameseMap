package com.vnmap.attendance.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record CheckInRequest(
        @NotNull Long campaignId,
        Long eventId,
        @Size(max = 500) String note,
        Double lat,
        Double lng
) {
}
