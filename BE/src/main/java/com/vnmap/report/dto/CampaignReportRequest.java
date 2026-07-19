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
        List<String> chartIds,
        String displayMode,
        Map<String, String> chartImages
) {
    public static final String TYPE_CAMPAIGN = "CAMPAIGN";
    public static final String TYPE_EVENT = "EVENT";
    public static final String TYPE_SCHOOL = "SCHOOL";
    public static final String TYPE_REGION = "REGION";
    private static final String SUMMARY = "summary";
    private static final String SCHOOLS = "schools";
    private static final String EVENTS = "events";
    private static final String ASSIGNMENTS = "assignments";
    private static final String INTERACTIONS = "interactions";
    private static final String ANALYTICS = "analytics";
    private static final String CHARTS_AND_TABLES = "CHARTS_AND_TABLES";

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
                case TYPE_EVENT -> List.of(SUMMARY, SCHOOLS, ASSIGNMENTS, INTERACTIONS, ANALYTICS);
                case TYPE_SCHOOL -> List.of(SUMMARY, EVENTS, INTERACTIONS);
                case TYPE_REGION -> List.of(SUMMARY, EVENTS, SCHOOLS, INTERACTIONS, ANALYTICS);
                default -> List.of(SUMMARY, EVENTS, SCHOOLS, ASSIGNMENTS, "registrations", INTERACTIONS, ANALYTICS);
            };
        }
        return sections;
    }
    /** Keeps report chart selections truthful, bounded, and type-specific. */
    public List<String> safeChartIds() {
        List<String> defaults = switch (safeReportType()) {
            case TYPE_EVENT -> List.of("registration_status", "interaction_trend", "interaction_channel", "event_status");
            case TYPE_SCHOOL -> List.of("school_activity", "school_event_types", "school_interaction_trend", "school_outcomes");
            case TYPE_REGION -> List.of("region_interactions", "region_schools", "region_events", "region_trend");
            default -> List.of("campaign_status", "events_by_campaign", "interaction_trend", "schools_by_province");
        };
        if (chartIds == null || chartIds.isEmpty()) return defaults;
        return chartIds.stream().filter(defaults::contains).distinct().limit(6).toList();
    }

    public String safeDisplayMode() {
        if (displayMode == null) return CHARTS_AND_TABLES;
        return switch (displayMode.toUpperCase()) {
            case "CHARTS_ONLY", "TABLES_ONLY", CHARTS_AND_TABLES -> displayMode.toUpperCase();
            default -> CHARTS_AND_TABLES;
        };
    }
}
