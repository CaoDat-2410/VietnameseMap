package com.vnmap.campaign.dto;

public record UserDto(
        Long id,
        String email,
        String role,
        String status,
        Long employeeId,
        Long studentId
) {
}
