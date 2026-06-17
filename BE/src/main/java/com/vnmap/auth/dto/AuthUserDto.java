package com.vnmap.auth.dto;

public record AuthUserDto(
        Long id,
        String email,
        String role,
        String status,
        Long employeeId,
        Long studentId
) {
}
