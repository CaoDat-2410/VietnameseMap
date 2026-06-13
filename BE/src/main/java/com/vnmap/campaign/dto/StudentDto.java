package com.vnmap.campaign.dto;

public record StudentDto(
        Long id,
        String schoolUid,
        String fullName,
        String grade,
        String className
) {
}
