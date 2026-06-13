package com.vnmap.campaign.dto;

public record ProvinceInteractionDto(
        String provinceCode,
        String provinceName,
        long totalInteractions
) {
}
