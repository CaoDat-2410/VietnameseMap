package com.vnmap.attendance.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.time.Instant;

/**
 * Manager/admin correction of an attendance record.
 * Explicit clear flags distinguish an omitted field from a deliberate clear.
 */
public record UpdateAttendanceRequest(
        Long campaignId,
        Long eventId,
        Boolean clearEvent,
        Instant checkInAt,
        Instant checkOutAt,
        Boolean clearCheckOutAt,
        @Size(max = 500) String checkInNote,
        Boolean clearCheckInNote,
        @Size(max = 500) String checkOutNote,
        Boolean clearCheckOutNote,
        @NotBlank @Size(max = 500) String correctionReason
) {
}
