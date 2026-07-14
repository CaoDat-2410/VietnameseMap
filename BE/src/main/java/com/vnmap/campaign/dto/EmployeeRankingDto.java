package com.vnmap.campaign.dto;

/**
 * One row in the top-employees horizontal bar chart.
 */
public record EmployeeRankingDto(
        long employeeId,
        String employeeName,
        long totalInteractions
) {
}