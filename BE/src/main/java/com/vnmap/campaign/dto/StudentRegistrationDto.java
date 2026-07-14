package com.vnmap.campaign.dto;

import java.time.LocalDateTime;

public record StudentRegistrationDto(
        Long id,
        Long campaignId,
        Long studentId,
        String schoolUid,
        String status,
        String note,
        LocalDateTime createdAt,
        LocalDateTime updatedAt,
        StudentDto student,
        SchoolDto school
) {
}
