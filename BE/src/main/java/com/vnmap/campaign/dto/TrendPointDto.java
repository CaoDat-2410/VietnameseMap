package com.vnmap.campaign.dto;

import java.time.LocalDate;

/**
 * One point in the interactions-over-time line chart.
 */
public record TrendPointDto(
        LocalDate date,
        long total
) {
}