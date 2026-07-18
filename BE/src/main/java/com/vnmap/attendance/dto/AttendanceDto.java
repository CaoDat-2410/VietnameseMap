package com.vnmap.attendance.dto;

import java.time.LocalDateTime;

public record AttendanceDto(
        Long id,
        Long employeeId,
        String employeeName,
        LocalDateTime checkInAt,
        LocalDateTime checkOutAt,
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
