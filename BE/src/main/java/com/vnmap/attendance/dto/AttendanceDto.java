package com.vnmap.attendance.dto;

import java.time.Instant;

public record AttendanceDto(
        Long id,
        Long employeeId,
        String employeeName,
        Long campaignId,
        String campaignName,
        Long eventId,
        String eventName,
        Instant checkInAt,
        Instant checkOutAt,
        String checkInNote,
        String checkOutNote,
        Double checkInLat,
        Double checkInLng,
        Double checkOutLat,
        Double checkOutLng,
        String status,
        Long workedMinutes
) {
}
