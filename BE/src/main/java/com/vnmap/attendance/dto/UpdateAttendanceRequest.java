package com.vnmap.attendance.dto;

import java.time.LocalDateTime;

/**
 * Manager/admin correction of an attendance record.
 * Any null field is left unchanged.
 */
public record UpdateAttendanceRequest(
        Long campaignId,
        Long eventId,
        LocalDateTime checkInAt,
        LocalDateTime checkOutAt,
        String checkInNote,
        String checkOutNote
) {
}
