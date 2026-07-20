package com.vnmap.attendance.dto;

import java.time.Instant;
import java.time.LocalDate;

/** A campaign/event pair that the authenticated employee may check in to. */
public record AttendanceTargetDto(
        Long campaignId,
        String campaignName,
        LocalDate campaignStartDate,
        LocalDate campaignEndDate,
        Long eventId,
        String eventName,
        Instant eventStartsAt,
        Instant eventEndsAt
) {
}
