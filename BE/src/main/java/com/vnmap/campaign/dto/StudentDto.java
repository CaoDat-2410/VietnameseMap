package com.vnmap.campaign.dto;

import java.time.LocalDate;

public record StudentDto(
        Long id,
        String schoolUid,
        String fullName,
        String email,
        String phone,
        LocalDate dateOfBirth,
        String address,
        String grade,
        String className
) {
}
