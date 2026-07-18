package com.vnmap.attendance.dto;

import java.time.LocalDateTime;

/**
 * Manager correction of an attendance record.
 * Any null field is left unchanged.
 */
public record UpdateAttendanceRequest(
        LocalDateTime checkInAt,
        LocalDateTime checkOutAt,
        String checkInNote,
        String checkOutNote
) {
}
