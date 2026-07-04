package com.vnmap.report.dto;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

public record CampaignReportRequest(
        String reportType,
        Long campaignId,
        Long eventId,
        LocalDate fromDate,
        LocalDate toDate,
        String eventStatus,
        String eventType,
        String provinceCode,
        String schoolUid,
        Long employeeId,
        String registrationStatus,
        String interactionOutcome,
        Boolean includeArchived,
        List<String> sections,
        Map<String, String> chartImages
) {
    public static final String TYPE_CAMPAIGN = "CAMPAIGN";
    public static final String TYPE_EVENT = "EVENT";
    public static final String TYPE_SCHOOL = "SCHOOL";
    public static final String TYPE_REGION = "REGION";

    public static final List<String> ALLOWED_TYPES = List.of(
            TYPE_CAMPAIGN, TYPE_EVENT, TYPE_SCHOOL, TYPE_REGION
    );

    public String safeReportType() {
        if (reportType == null || reportType.isBlank()) return TYPE_CAMPAIGN;
        return ALLOWED_TYPES.contains(reportType.toUpperCase()) ? reportType.toUpperCase() : TYPE_CAMPAIGN;
    }

    public List<String> safeSections() {
        if (sections == null || sections.isEmpty()) {
            return switch (safeReportType()) {
                case TYPE_EVENT -> List.of("summary", "schools", "assignments", "interactions", "analytics");
                case TYPE_SCHOOL -> List.of("summary", "events", "interactions");
                case TYPE_REGION -> List.of("summary", "events", "schools", "interactions", "analytics");
                default -> List.of("summary", "events", "schools", "assignments", "registrations", "interactions", "analytics");
            };
        }
        return sections;
    }
}