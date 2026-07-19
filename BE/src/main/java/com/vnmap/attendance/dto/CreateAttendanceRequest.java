package com.vnmap.attendance.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.LocalDateTime;

/**
 * Manual attendance entry created by a MANAGER/ADMIN on behalf of an employee
 * (e.g. correcting a forgotten check-in). checkInAt defaults to now when omitted;
 * providing checkOutAt creates an already-closed record.
 */
public record CreateAttendanceRequest(
        @NotNull Long employeeId,
        @NotNull Long campaignId,
        Long eventId,
        LocalDateTime checkInAt,
        LocalDateTime checkOutAt,
        @Size(max = 500) String checkInNote,
        @Size(max = 500) String checkOutNote
) {
}
