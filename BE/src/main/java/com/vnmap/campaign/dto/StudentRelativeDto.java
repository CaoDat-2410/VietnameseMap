package com.vnmap.campaign.dto;

public record StudentRelativeDto(
        Long id,
        String schoolUid,
        String fullName,
        Long studentId,
        String relationship,
        String phone
) {
}
