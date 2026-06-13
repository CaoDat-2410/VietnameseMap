package com.vnmap.campaign.dto;

public record SchoolDto(
        String schoolUid,
        String provinceCode,
        String provinceName,
        String communeCode,
        String communeName,
        String schoolCode,
        String schoolName,
        String address,
        String areaType
) {
}
