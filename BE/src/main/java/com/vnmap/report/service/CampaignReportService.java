package com.vnmap.report.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.vnmap.common.model.PagedResponse;
import com.vnmap.common.security.CurrentUser;
import com.vnmap.report.dto.CampaignReportRequest;
import com.vnmap.report.dto.ReportExportResponse;
import com.vnmap.storage.service.StorageService;
import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.sql.PreparedStatement;
import java.sql.Statement;
import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CompletableFuture;

/** Dynamic clauses are built only from internal constants; request data is always JDBC-bound. */
@SuppressWarnings("java:S2077")
@Service
public class CampaignReportService {

    private static final Logger log = LoggerFactory.getLogger(CampaignReportService.class);
    private static final String ADMIN_ROLE = "ADMIN";
    private static final String WHERE = "WHERE ";
    private static final String AND = " AND ";
    private static final String STORAGE_PATH = "storage_path";
    private static final String LABEL = "label";
    private static final String VALUE = "value";
    private static final String SUMMARY = "summary";
    private static final String EVENTS = "events";
    private static final String SCHOOLS = "schools";
    private static final String ASSIGNMENTS = "assignments";
    private static final String INTERACTIONS = "interactions";
    private static final String ANALYTICS = "analytics";
    private static final String STATUS = "status";
    private static final String REGISTRATIONS = "registrations";
    private static final String DONUT = "DONUT";
    private static final String PROVINCE_NAME = "province_name";
    private static final String REGIONAL_SUMMARY = "Regional summary";
    private static final String PROVINCE_FILTER = "s.province_code = ?";
    private static final String DATE_FUNCTION = "DATE(";
    private static final String OBJECT_KEY_SEPARATOR = "/";
    private static final String UNSUPPORTED_SECTION_MESSAGE = "Ignoring unsupported report section: {}";
    private static final ZoneId VIETNAM_ZONE = ZoneId.of("Asia/Ho_Chi_Minh");
    private static final Duration DOWNLOAD_URL_TTL = Duration.ofMinutes(5);
    private static final DateTimeFormatter PATH_DATE = DateTimeFormatter.ofPattern("yyyy/MM");
    private static final DateTimeFormatter FILE_DATE = DateTimeFormatter.ofPattern("yyyyMMdd-HHmmss");

    private final JdbcTemplate jdbc;
    private final ObjectMapper objectMapper;
    private final StorageService storageService;
    private final PdfReportRenderer renderer;

    public CampaignReportService(
            JdbcTemplate jdbc,
            ObjectMapper objectMapper,
            StorageService storageService,
            PdfReportRenderer renderer
    ) {
        this.jdbc = jdbc;
        this.objectMapper = objectMapper;
        this.storageService = storageService;
        this.renderer = renderer;
    }

    @PostConstruct
    void ensureSchema() {
        jdbc.execute("""
                CREATE TABLE IF NOT EXISTS report_exports (
                  id BIGSERIAL PRIMARY KEY,
                  created_by_user_id BIGINT NOT NULL REFERENCES app_users(id),
                  report_type VARCHAR(50) NOT NULL,
                  status VARCHAR(30) NOT NULL DEFAULT 'PENDING',
                  file_name VARCHAR(255),
                  storage_path TEXT,
                  filters_json TEXT NOT NULL,
                  sections_json TEXT NOT NULL,
                  error_message TEXT,
                  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                  completed_at TIMESTAMP
                )
                """);
    }

    @Transactional
    public ReportExportResponse createCampaignReport(CampaignReportRequest request, CurrentUser user) {
        requireManagerOrAdmin(user);
        validateRange(request, user);
        Long pendingId = findPendingReport(user.id());
        if (pendingId != null) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "You already have a campaign report generating");
        }

        String filtersJson = toJson(request);
        String sectionsJson = toJson(request.safeSections());
        GeneratedKeyHolder keyHolder = new GeneratedKeyHolder();
        jdbc.update(connection -> {
            PreparedStatement ps = connection.prepareStatement(
                    """
                    INSERT INTO report_exports (created_by_user_id, report_type, status, filters_json, sections_json)
                    VALUES (?, ?, 'PENDING', ?, ?)
                    """,
                    Statement.RETURN_GENERATED_KEYS
            );
            ps.setLong(1, user.id());
            ps.setString(2, request.safeReportType());
            ps.setString(3, filtersJson);
            ps.setString(4, sectionsJson);
            return ps;
        }, keyHolder);
        Long reportId;
        var keys = keyHolder.getKeyList();
        if (keys.isEmpty()) {
            throw new IllegalStateException("Failed to retrieve generated key for report");
        }
        reportId = ((Number) keys.get(0).get("id")).longValue();
        CompletableFuture.runAsync(() -> generateReport(reportId, request));
        return getReport(reportId, user, false);
    }

    public ReportExportResponse getReport(long reportId, CurrentUser user, boolean includeDownloadUrl) {
        requireManagerOrAdmin(user);
        Map<String, Object> row = jdbc.queryForMap("SELECT * FROM report_exports WHERE id = ?", reportId);
        authorizeReport(row, user);
        String downloadUrl = null;
        String status = (String) row.get(STATUS);
        String path = (String) row.get(STORAGE_PATH);
        if (includeDownloadUrl) {
            if (!"READY".equals(status)) {
                throw new ResponseStatusException(HttpStatus.CONFLICT, "Report is not ready for download");
            }
            downloadUrl = storageService.generateDownloadUrl(path, DOWNLOAD_URL_TTL);
        }
        return map(row, downloadUrl);
    }

    public PagedResponse<ReportExportResponse> listReports(
            CurrentUser user, int page, int limit, String status, String reportType
    ) {
        requireManagerOrAdmin(user);
        int safePage = Math.max(page, 0);
        int safeLimit = Math.clamp(limit, 1, 100);
        List<Object> params = new ArrayList<>();
        List<String> filters = new ArrayList<>();
        // ADMIN sees all reports; MANAGER sees only their own.
        if (!ADMIN_ROLE.equals(user.role())) {
            filters.add("created_by_user_id = ?");
            params.add(user.id());
        }
        if (status != null && !status.isBlank()) {
            filters.add("status = ?");
            params.add(status);
        }
        if (reportType != null && !reportType.isBlank()) {
            filters.add("report_type = ?");
            params.add(reportType);
        }
        String where = filters.isEmpty() ? "" : WHERE + String.join(AND, filters);
        long total = count("SELECT COUNT(*) FROM report_exports " + where, params);
        params.add(safeLimit);
        params.add(safePage * safeLimit);
        List<Map<String, Object>> rows = jdbc.queryForList(
                "SELECT * FROM report_exports " + where + " ORDER BY created_at DESC LIMIT ? OFFSET ?",
                params.toArray()
        );
        List<ReportExportResponse> items = rows.stream()
                .map(r -> map(r, null))
                .toList();
        return PagedResponse.of(items, safePage, safeLimit, total);
    }

    private void generateReport(long reportId, CampaignReportRequest request) {
        try {
            Map<String, List<Map<String, Object>>> sections = collectSections(request);
            List<Map<String, Object>> kpis = computeKpis(request);
            String title = titleFor(request);
            String subtitle = "Report #" + reportId + " - generated " + LocalDateTime.now(VIETNAM_ZONE);
            List<ReportChart> charts = buildCharts(request, sections);
            byte[] pdf = renderer.render(title, subtitle, kpis, sections, charts, request.safeDisplayMode());
            if (pdf.length < 4 || pdf[0] != '%' || pdf[1] != 'P' || pdf[2] != 'D' || pdf[3] != 'F') {
                throw new IllegalStateException("Generated report is not a valid PDF");
            }
            LocalDateTime now = LocalDateTime.now(VIETNAM_ZONE);
            String fileName = request.safeReportType().toLowerCase() + "-report-" + now.format(FILE_DATE) + "-" + reportId + ".pdf";
            String storagePath = String.join(OBJECT_KEY_SEPARATOR, "reports", now.format(PATH_DATE), fileName);
            storageService.uploadGeneratedObject(storagePath, pdf, "application/pdf");
            jdbc.update(
                    """
                    UPDATE report_exports
                    SET status = 'READY', file_name = ?, storage_path = ?, completed_at = CURRENT_TIMESTAMP, error_message = NULL
                    WHERE id = ?
                    """,
                    fileName,
                    storagePath,
                    reportId
            );
        } catch (Exception e) {
            log.error("Report generation failed for reportId={}: {}", reportId, e.getMessage(), e);
            jdbc.update(
                    "UPDATE report_exports SET status = 'FAILED', error_message = ?, completed_at = CURRENT_TIMESTAMP WHERE id = ?",
                    e.getMessage(),
                    reportId
            );
        }
    }

    private List<ReportChart> buildCharts(CampaignReportRequest request, Map<String, List<Map<String, Object>>> sections) {
        Map<String, List<Map<String, Object>>> data = new LinkedHashMap<>(sections);
        data.putIfAbsent(REGISTRATIONS, queryRegistrations(request));
        data.putIfAbsent(ANALYTICS, queryAnalytics(request));
        List<ReportChart> charts = new ArrayList<>();
        for (String id : request.safeChartIds()) {
            ReportChart chart = switch (id) {
                case "campaign_status" -> chart(id, "Campaign status distribution", "Distribution of selected campaigns by current status.", DONUT, grouped(data.get(SUMMARY), STATUS, null), request, "Campaign summary");
                case "events_by_campaign" -> chart(id, "Events per campaign", "Number of selected events grouped by campaign.", "BAR", grouped(data.get(EVENTS), "campaign_id", null), request, "Event records");
                case "interaction_trend", "school_interaction_trend", "region_trend" -> chart(id, "Interaction trend", "Daily interaction volume in the selected reporting period.", "LINE", groupedDates(data.get(INTERACTIONS)), request, "Interaction records");
                case "schools_by_province" -> chart(id, "Participating schools by province", "Distinct selected schools grouped by province.", "BAR", grouped(data.get(SCHOOLS), PROVINCE_NAME, null), request, "School records");
                case "registration_status" -> chart(id, "Registration status", "Selected registrations grouped by status.", DONUT, grouped(data.get(REGISTRATIONS), STATUS, null), request, "Registration records");
                case "interaction_channel" -> chart(id, "Interactions by channel", "Selected interactions grouped by channel.", DONUT, grouped(data.get(INTERACTIONS), "channel", null), request, "Interaction records");
                case "event_status" -> chart(id, "Event status", "Selected events grouped by operational status.", "BAR", grouped(data.get(SUMMARY), STATUS, null), request, "Event summary");
                case "school_activity" -> chart(id, "School activity", "Interactions recorded for each selected school.", "BAR", values(data.get(SUMMARY), "school_name", INTERACTIONS), request, "School summary");
                case "school_event_types" -> chart(id, "Events by type", "Selected school events grouped by event type.", DONUT, grouped(data.get(EVENTS), "event_type", null), request, "Event records");
                case "school_outcomes" -> chart(id, "Interaction outcomes", "Selected school interactions grouped by outcome.", DONUT, grouped(data.get(ANALYTICS), "outcome", "total"), request, "Interaction analytics");
                case "region_interactions" -> chart(id, "Interactions by province", "Selected provinces ranked by interaction volume.", "BAR", values(data.get(SUMMARY), PROVINCE_NAME, INTERACTIONS), request, REGIONAL_SUMMARY);
                case "region_schools" -> chart(id, "Schools by province", "Selected provinces ranked by participating schools.", "BAR", values(data.get(SUMMARY), PROVINCE_NAME, SCHOOLS), request, REGIONAL_SUMMARY);
                case "region_events" -> chart(id, "Events by province", "Selected provinces ranked by event count.", "BAR", values(data.get(SUMMARY), PROVINCE_NAME, EVENTS), request, REGIONAL_SUMMARY);
                default -> null;
            };
            if (chart != null) charts.add(chart);
        }
        return charts;
    }

    private ReportChart chart(String id, String title, String description, String type, List<ReportChart.Datum> data, CampaignReportRequest request, String source) {
        List<ReportChart.Datum> limited = data.stream().limit(10).toList();
        String period = (request.fromDate() == null ? "All available dates" : request.fromDate()) + " to " + (request.toDate() == null ? "today" : request.toDate());
        String insight = limited.isEmpty() ? "No matching records were found for the selected filters." : "Highest value: " + limited.get(0).label() + " (" + limited.get(0).value() + ").";
        return new ReportChart(id, title, description, type, "count", period, source, insight, limited);
    }

    private List<ReportChart.Datum> grouped(List<Map<String, Object>> rows, String labelKey, String valueKey) {
        Map<String, Long> aggregate = new LinkedHashMap<>();
        if (rows != null) for (Map<String, Object> row : rows) {
            String label = String.valueOf(row.getOrDefault(labelKey, "Unknown"));
            long value = valueKey == null ? 1L : number(row.get(valueKey));
            aggregate.merge(label, value, Long::sum);
        }
        return aggregate.entrySet().stream().map(e -> new ReportChart.Datum(e.getKey(), e.getValue())).sorted((a, b) -> Long.compare(b.value(), a.value())).toList();
    }

    private List<ReportChart.Datum> values(List<Map<String, Object>> rows, String labelKey, String valueKey) {
        return grouped(rows, labelKey, valueKey);
    }

    private List<ReportChart.Datum> groupedDates(List<Map<String, Object>> rows) {
        Map<String, Long> aggregate = new LinkedHashMap<>();
        if (rows != null) for (Map<String, Object> row : rows) {
            Object raw = row.get("created_at");
            String label = raw == null ? "Unknown" : raw.toString().substring(0, Math.min(10, raw.toString().length()));
            aggregate.merge(label, 1L, Long::sum);
        }
        return aggregate.entrySet().stream().map(e -> new ReportChart.Datum(e.getKey(), e.getValue())).sorted(java.util.Comparator.comparing(ReportChart.Datum::label)).toList();
    }

    private long number(Object value) {
        if (value instanceof Number number) return number.longValue();
        try { return Long.parseLong(String.valueOf(value)); } catch (NumberFormatException ignored) { return 0; }
    }
    private String titleFor(CampaignReportRequest request) {
        return switch (request.safeReportType()) {
            case CampaignReportRequest.TYPE_EVENT -> "Event Report";
            case CampaignReportRequest.TYPE_SCHOOL -> "School Report";
            case CampaignReportRequest.TYPE_REGION -> "Region Report";
            default -> "Campaign Report";
        };
    }

    private List<Map<String, Object>> computeKpis(CampaignReportRequest request) {
        List<Object> eventParams = new ArrayList<>();
        List<String> eventFilters = eventFilters(request, eventParams, "e");
        String eventWhere = eventFilters.isEmpty() ? "" : WHERE + String.join(AND, eventFilters);

        List<Object> interParams = new ArrayList<>();
        List<String> interFilters = interactionFilters(request, interParams, "i");
        String interWhere = interFilters.isEmpty() ? "" : WHERE + String.join(AND, interFilters);

        long events = count("SELECT COUNT(*) FROM campaign_events e " + eventWhere, eventParams);
        long interactions = count("SELECT COUNT(*) FROM interactions i " + interWhere, interParams);

        List<Object> schoolParams = new ArrayList<>();
        List<String> schoolFilters = schoolFilters(request, schoolParams);
        String schoolWhere = schoolFilters.isEmpty() ? "" : WHERE + String.join(AND, schoolFilters);
        long schools = count("SELECT COUNT(DISTINCT s.school_uid) FROM event_schools es JOIN campaign_events e ON e.id = es.event_id JOIN schools s ON s.school_uid = es.school_uid " + schoolWhere, schoolParams);

        List<Object> regParams = new ArrayList<>();
        List<String> regFilters = registrationFilters(request, regParams);
        String regWhere = regFilters.isEmpty() ? "" : WHERE + String.join(AND, regFilters);
        long registrations = count("SELECT COUNT(*) FROM campaign_student_registrations r " + regWhere, regParams);

        List<Map<String, Object>> kpis = new ArrayList<>();
        kpis.add(Map.of(LABEL, "Events", VALUE, events));
        kpis.add(Map.of(LABEL, "Interactions", VALUE, interactions));
        kpis.add(Map.of(LABEL, "Schools", VALUE, schools));
        kpis.add(Map.of(LABEL, "Registrations", VALUE, registrations));
        return kpis;
    }

    /** SQL fragments are selected exclusively from internal constants; all external values remain bound parameters. */
    @SuppressWarnings("java:S2077")
    private long count(String sql, List<Object> params) {
        Long result = jdbc.queryForObject(sql, Long.class, params.toArray());
        return result == null ? 0L : result;
    }
    private Map<String, List<Map<String, Object>>> collectSections(CampaignReportRequest request) {
        return switch (request.safeReportType()) {
            case CampaignReportRequest.TYPE_EVENT -> collectEventSections(request);
            case CampaignReportRequest.TYPE_SCHOOL -> collectSchoolSections(request);
            case CampaignReportRequest.TYPE_REGION -> collectRegionSections(request);
            default -> collectCampaignSections(request);
        };
    }

    private Map<String, List<Map<String, Object>>> collectCampaignSections(CampaignReportRequest request) {
        Map<String, List<Map<String, Object>>> out = new LinkedHashMap<>();
        for (String section : request.safeSections()) {
            switch (section) {
                case SUMMARY -> out.put(SUMMARY, querySummary(request));
                case EVENTS -> out.put(EVENTS, queryEvents(request));
                case SCHOOLS -> out.put(SCHOOLS, querySchools(request));
                case ASSIGNMENTS -> out.put(ASSIGNMENTS, queryAssignments(request));
                case REGISTRATIONS -> out.put(REGISTRATIONS, queryRegistrations(request));
                case INTERACTIONS -> out.put(INTERACTIONS, queryInteractions(request));
                case ANALYTICS -> out.put(ANALYTICS, queryAnalytics(request));
                default -> log.debug(UNSUPPORTED_SECTION_MESSAGE, section);
            }
        }
        return out;
    }

    private Map<String, List<Map<String, Object>>> collectEventSections(CampaignReportRequest request) {
        Map<String, List<Map<String, Object>>> out = new LinkedHashMap<>();
        for (String section : request.safeSections()) {
            switch (section) {
                case SUMMARY -> out.put(SUMMARY, queryEventSummary(request));
                case SCHOOLS -> out.put(SCHOOLS, querySchools(request));
                case ASSIGNMENTS -> out.put(ASSIGNMENTS, queryAssignments(request));
                case INTERACTIONS -> out.put(INTERACTIONS, queryInteractions(request));
                case ANALYTICS -> out.put(ANALYTICS, queryAnalytics(request));
                default -> log.debug(UNSUPPORTED_SECTION_MESSAGE, section);
            }
        }
        return out;
    }

    private Map<String, List<Map<String, Object>>> collectSchoolSections(CampaignReportRequest request) {
        Map<String, List<Map<String, Object>>> out = new LinkedHashMap<>();
        for (String section : request.safeSections()) {
            switch (section) {
                case SUMMARY -> out.put(SUMMARY, querySchoolSummary(request));
                case EVENTS -> out.put(EVENTS, queryEvents(request));
                case INTERACTIONS -> out.put(INTERACTIONS, queryInteractions(request));
                default -> log.debug(UNSUPPORTED_SECTION_MESSAGE, section);
            }
        }
        return out;
    }

    private Map<String, List<Map<String, Object>>> collectRegionSections(CampaignReportRequest request) {
        Map<String, List<Map<String, Object>>> out = new LinkedHashMap<>();
        for (String section : request.safeSections()) {
            switch (section) {
                case SUMMARY -> out.put(SUMMARY, queryRegionSummary(request));
                case EVENTS -> out.put(EVENTS, queryEvents(request));
                case SCHOOLS -> out.put(SCHOOLS, querySchools(request));
                case INTERACTIONS -> out.put(INTERACTIONS, queryInteractions(request));
                case ANALYTICS -> out.put(ANALYTICS, queryAnalytics(request));
                default -> log.debug(UNSUPPORTED_SECTION_MESSAGE, section);
            }
        }
        return out;
    }

    private List<Map<String, Object>> queryEventSummary(CampaignReportRequest request) {
        List<Object> params = new ArrayList<>();
        List<String> filters = new ArrayList<>();
        if (request.eventId() != null) {
            filters.add("e.id = ?");
            params.add(request.eventId());
        }
        if (request.campaignId() != null) {
            filters.add("e.campaign_id = ?");
            params.add(request.campaignId());
        }
        if (hasText(request.eventType())) {
            filters.add("e.event_type = ?");
            params.add(request.eventType());
        }
        if (hasText(request.eventStatus())) {
            filters.add("e.status = ?");
            params.add(request.eventStatus());
        }
        String where = filters.isEmpty() ? "" : WHERE + String.join(AND, filters);
        return jdbc.queryForList(
                """
                SELECT e.id, e.name, e.event_type, e.status, e.starts_at, e.ends_at,
                       e.location_label, e.province_code,
                       COUNT(DISTINCT es.school_uid) schools,
                       COUNT(DISTINCT ea.employee_id) staff,
                       COUNT(DISTINCT i.id) interactions
                FROM campaign_events e
                LEFT JOIN event_schools es ON es.event_id = e.id
                LEFT JOIN event_assignments ea ON ea.event_id = e.id
                LEFT JOIN interactions i ON i.event_id = e.id
                %s
                GROUP BY e.id, e.name, e.event_type, e.status, e.starts_at, e.ends_at,
                         e.location_label, e.province_code
                ORDER BY e.starts_at NULLS LAST, e.id DESC
                """.formatted(where),
                params.toArray()
        );
    }

    private List<Map<String, Object>> querySchoolSummary(CampaignReportRequest request) {
        List<Object> params = new ArrayList<>();
        List<String> filters = new ArrayList<>();
        if (hasText(request.schoolUid())) {
            filters.add("s.school_uid = ?");
            params.add(request.schoolUid());
        }
        if (hasText(request.provinceCode())) {
            filters.add(PROVINCE_FILTER);
            params.add(request.provinceCode());
        }
        String where = filters.isEmpty() ? "" : WHERE + String.join(AND, filters);
        return jdbc.queryForList(
                """
                SELECT s.school_uid, s.school_name, s.province_name, s.commune_name,
                       COUNT(DISTINCT es.event_id) events,
                       COUNT(DISTINCT i.id) interactions
                FROM schools s
                LEFT JOIN event_schools es ON es.school_uid = s.school_uid
                LEFT JOIN interactions i ON i.school_uid = s.school_uid
                %s
                GROUP BY s.school_uid, s.school_name, s.province_name, s.commune_name
                ORDER BY events DESC, s.school_name
                """.formatted(where),
                params.toArray()
        );
    }

    private List<Map<String, Object>> queryRegionSummary(CampaignReportRequest request) {
        List<Object> params = new ArrayList<>();
        List<String> filters = new ArrayList<>();
        if (hasText(request.provinceCode())) {
            filters.add(PROVINCE_FILTER);
            params.add(request.provinceCode());
        }
        if (request.fromDate() != null) {
            filters.add("DATE(e.starts_at) >= ?");
            params.add(request.fromDate());
        }
        if (request.toDate() != null) {
            filters.add("DATE(e.starts_at) <= ?");
            params.add(request.toDate());
        }
        String where = filters.isEmpty() ? "" : WHERE + String.join(AND, filters);
        return jdbc.queryForList(
                """
                SELECT s.province_code, s.province_name,
                       COUNT(DISTINCT es.school_uid) schools,
                       COUNT(DISTINCT es.event_id) events,
                       COUNT(DISTINCT i.id) interactions
                FROM schools s
                LEFT JOIN event_schools es ON es.school_uid = s.school_uid
                LEFT JOIN campaign_events e ON e.id = es.event_id
                LEFT JOIN interactions i ON i.school_uid = s.school_uid
                %s
                GROUP BY s.province_code, s.province_name
                ORDER BY interactions DESC, schools DESC
                """.formatted(where),
                params.toArray()
        );
    }

    private List<Map<String, Object>> querySummary(CampaignReportRequest request) {
        List<Object> params = new ArrayList<>();
        String where = campaignWhere(request, params, "c", true);
        return jdbc.queryForList(
                """
                SELECT c.id, c.name, c.status, c.objective, c.start_date, c.end_date,
                       COUNT(DISTINCT e.id) events,
                       COUNT(DISTINCT r.id) registrations,
                       COUNT(DISTINCT i.id) interactions
                FROM campaigns c
                LEFT JOIN campaign_events e ON e.campaign_id = c.id
                LEFT JOIN campaign_student_registrations r ON r.campaign_id = c.id
                LEFT JOIN interactions i ON i.campaign_id = c.id
                %s
                GROUP BY c.id, c.name, c.status, c.objective, c.start_date, c.end_date
                ORDER BY c.id DESC
                """.formatted(where),
                params.toArray()
        );
    }

    private List<Map<String, Object>> queryEvents(CampaignReportRequest request) {
        List<Object> params = new ArrayList<>();
        List<String> filters = eventFilters(request, params, "e");
        String where = filters.isEmpty() ? "" : WHERE + String.join(AND, filters);
        return jdbc.queryForList(
                """
                SELECT e.id, e.campaign_id, e.name, e.event_type, e.status, e.starts_at, e.ends_at,
                       e.location_label, e.school_uid, e.province_code
                FROM campaign_events e
                %s
                ORDER BY e.starts_at NULLS LAST, e.id
                """.formatted(where),
                params.toArray()
        );
    }

    private List<Map<String, Object>> querySchools(CampaignReportRequest request) {
        List<Object> params = new ArrayList<>();
        List<String> filters = eventFilters(request, params, "e");
        if (hasText(request.schoolUid())) {
            filters.add("s.school_uid = ?");
            params.add(request.schoolUid());
        }
        if (hasText(request.provinceCode())) {
            filters.add(PROVINCE_FILTER);
            params.add(request.provinceCode());
        }
        String where = filters.isEmpty() ? "" : WHERE + String.join(AND, filters);
        return jdbc.queryForList(
                """
                SELECT DISTINCT s.school_uid, s.school_name, s.province_name, s.commune_name, s.address, s.area_type
                FROM event_schools es
                JOIN campaign_events e ON e.id = es.event_id
                JOIN schools s ON s.school_uid = es.school_uid
                %s
                ORDER BY s.province_name, s.school_name
                """.formatted(where),
                params.toArray()
        );
    }

    private List<Map<String, Object>> queryAssignments(CampaignReportRequest request) {
        List<Object> params = new ArrayList<>();
        List<String> filters = eventFilters(request, params, "e");
        if (request.employeeId() != null) {
            filters.add("emp.id = ?");
            params.add(request.employeeId());
        }
        String where = filters.isEmpty() ? "" : WHERE + String.join(AND, filters);
        return jdbc.queryForList(
                """
                SELECT e.id event_id, e.name event_name, emp.id employee_id, emp.full_name, emp.role
                FROM event_assignments ea
                JOIN campaign_events e ON e.id = ea.event_id
                JOIN employees emp ON emp.id = ea.employee_id
                %s
                ORDER BY e.starts_at NULLS LAST, emp.full_name
                """.formatted(where),
                params.toArray()
        );
    }

    private List<Map<String, Object>> queryRegistrations(CampaignReportRequest request) {
        List<Object> params = new ArrayList<>();
        List<String> filters = registrationFilters(request, params);
        String where = filters.isEmpty() ? "" : WHERE + String.join(AND, filters);
        return jdbc.queryForList(
                """
                SELECT r.id, r.campaign_id, r.status, r.created_at, st.full_name student_name,
                       st.email student_email, s.school_name, s.province_name
                FROM campaign_student_registrations r
                JOIN students st ON st.id = r.student_id
                JOIN schools s ON s.school_uid = r.school_uid
                %s
                ORDER BY r.created_at DESC, r.id DESC
                """.formatted(where),
                params.toArray()
        );
    }

    private List<Map<String, Object>> queryInteractions(CampaignReportRequest request) {
        List<Object> params = new ArrayList<>();
        List<String> filters = interactionFilters(request, params, "i");
        String where = filters.isEmpty() ? "" : WHERE + String.join(AND, filters);
        return jdbc.queryForList(
                """
                SELECT i.id, i.campaign_id, i.event_id, i.employee_id, i.school_uid, i.channel,
                       i.outcome, i.created_at, i.note
                FROM interactions i
                %s
                ORDER BY i.created_at DESC, i.id DESC
                """.formatted(where),
                params.toArray()
        );
    }

    private List<Map<String, Object>> queryAnalytics(CampaignReportRequest request) {
        List<Object> params = new ArrayList<>();
        List<String> filters = interactionFilters(request, params, "i");
        String where = filters.isEmpty() ? "" : WHERE + String.join(AND, filters);
        return jdbc.queryForList(
                """
                SELECT i.outcome, i.channel, COUNT(*) total
                FROM interactions i
                %s
                GROUP BY i.outcome, i.channel
                ORDER BY total DESC
                """.formatted(where),
                params.toArray()
        );
    }

    private String campaignWhere(CampaignReportRequest request, List<Object> params, String alias, boolean campaignTable) {
        List<String> filters = new ArrayList<>();
        if (request.campaignId() != null) {
            filters.add(alias + (campaignTable ? ".id = ?" : ".campaign_id = ?"));
            params.add(request.campaignId());
        }
        if (request.fromDate() != null) {
            filters.add(alias + ".start_date >= ?");
            params.add(request.fromDate());
        }
        if (request.toDate() != null) {
            filters.add(alias + ".end_date <= ?");
            params.add(request.toDate());
        }
        if (!Boolean.TRUE.equals(request.includeArchived())) {
            filters.add(alias + ".status <> 'ARCHIVED'");
        }
        return filters.isEmpty() ? "" : WHERE + String.join(AND, filters);
    }

    private List<String> eventFilters(CampaignReportRequest request, List<Object> params, String alias) {
        List<String> filters = new ArrayList<>();
        addCampaignFilter(filters, params, request.campaignId(), alias);
        if (request.eventId() != null) {
            filters.add(alias + ".id = ?");
            params.add(request.eventId());
        }
        if (hasText(request.eventStatus())) {
            filters.add(alias + ".status = ?");
            params.add(request.eventStatus());
        } else if (!Boolean.TRUE.equals(request.includeArchived())) {
            filters.add(alias + ".status <> 'ARCHIVED'");
        }
        if (hasText(request.eventType())) {
            filters.add(alias + ".event_type = ?");
            params.add(request.eventType());
        }
        if (hasText(request.provinceCode())) {
            filters.add(alias + ".province_code = ?");
            params.add(request.provinceCode());
        }
        if (hasText(request.schoolUid())) {
            filters.add(alias + ".school_uid = ?");
            params.add(request.schoolUid());
        }
        if (request.fromDate() != null) {
            filters.add(DATE_FUNCTION + alias + ".starts_at) >= ?");
            params.add(request.fromDate());
        }
        if (request.toDate() != null) {
            filters.add(DATE_FUNCTION + alias + ".starts_at) <= ?");
            params.add(request.toDate());
        }
        return filters;
    }

    private List<String> registrationFilters(CampaignReportRequest request, List<Object> params) {
        List<String> filters = new ArrayList<>();
        addCampaignFilter(filters, params, request.campaignId(), "r");
        if (hasText(request.schoolUid())) {
            filters.add("r.school_uid = ?");
            params.add(request.schoolUid());
        }
        if (hasText(request.registrationStatus())) {
            filters.add("r.status = ?");
            params.add(request.registrationStatus());
        }
        if (hasText(request.provinceCode())) {
            filters.add(PROVINCE_FILTER);
            params.add(request.provinceCode());
        }
        return filters;
    }

    private List<String> schoolFilters(CampaignReportRequest request, List<Object> params) {
        List<String> filters = new ArrayList<>();
        addCampaignFilter(filters, params, request.campaignId(), "e");
        if (hasText(request.schoolUid())) {
            filters.add("es.school_uid = ?");
            params.add(request.schoolUid());
        }
        if (hasText(request.provinceCode())) {
            filters.add(PROVINCE_FILTER);
            params.add(request.provinceCode());
        }
        if (request.fromDate() != null) {
            filters.add("DATE(e.starts_at) >= ?");
            params.add(request.fromDate());
        }
        if (request.toDate() != null) {
            filters.add("DATE(e.starts_at) <= ?");
            params.add(request.toDate());
        }
        return filters;
    }

    private List<String> interactionFilters(CampaignReportRequest request, List<Object> params, String alias) {
        List<String> filters = new ArrayList<>();
        addCampaignFilter(filters, params, request.campaignId(), alias);
        if (request.eventId() != null) {
            filters.add(alias + ".event_id = ?");
            params.add(request.eventId());
        }
        if (request.employeeId() != null) {
            filters.add(alias + ".employee_id = ?");
            params.add(request.employeeId());
        }
        if (hasText(request.schoolUid())) {
            filters.add(alias + ".school_uid = ?");
            params.add(request.schoolUid());
        }
        if (hasText(request.interactionOutcome())) {
            filters.add(alias + ".outcome = ?");
            params.add(request.interactionOutcome());
        }
        if (hasText(request.provinceCode())) {
            filters.add(alias + ".province_code = ?");
            params.add(request.provinceCode());
        }
        if (request.fromDate() != null) {
            filters.add(DATE_FUNCTION + alias + ".created_at) >= ?");
            params.add(request.fromDate());
        }
        if (request.toDate() != null) {
            filters.add(DATE_FUNCTION + alias + ".created_at) <= ?");
            params.add(request.toDate());
        }
        return filters;
    }

    private void addCampaignFilter(List<String> filters, List<Object> params, Long campaignId, String alias) {
        if (campaignId != null) {
            filters.add(alias + ".campaign_id = ?");
            params.add(campaignId);
        }
    }

    private void validateRange(CampaignReportRequest request, CurrentUser user) {
        LocalDate from = request.fromDate();
        LocalDate to = request.toDate();
        if (from != null && to != null && from.isAfter(to)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "fromDate must be before toDate");
        }
        if (from != null && to != null && from.plusMonths(6).isBefore(to) && !ADMIN_ROLE.equals(user.role())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Report date range cannot exceed 6 months");
        }
    }

    private Long findPendingReport(Long userId) {
        return jdbc.query(
                """
                SELECT id FROM report_exports
                WHERE created_by_user_id = ? AND status = 'PENDING'
                ORDER BY created_at DESC LIMIT 1
                """,
                (rs, rowNum) -> rs.getLong("id"),
                userId
        ).stream().findFirst().orElse(null);
    }

    private void requireManagerOrAdmin(CurrentUser user) {
        if (user == null || !("MANAGER".equals(user.role()) || ADMIN_ROLE.equals(user.role()))) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Manager or admin role required");
        }
    }

    private void authorizeReport(Map<String, Object> row, CurrentUser user) {
        if (ADMIN_ROLE.equals(user.role())) {
            return;
        }
        Long ownerId = ((Number) row.get("created_by_user_id")).longValue();
        if (!ownerId.equals(user.id())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "You can only access your own reports");
        }
    }

    private ReportExportResponse map(Map<String, Object> row, String downloadUrl) {
        return new ReportExportResponse(
                ((Number) row.get("id")).longValue(),
                (String) row.get("report_type"),
                (String) row.get(STATUS),
                (String) row.get("file_name"),
                (String) row.get(STORAGE_PATH),
                downloadUrl,
                (String) row.get("error_message"),
                toLocalDateTime(row.get("created_at")),
                toLocalDateTime(row.get("completed_at"))
        );
    }

    private LocalDateTime toLocalDateTime(Object value) {
        if (value == null) return null;
        if (value instanceof LocalDateTime ldt) return ldt;
        if (value instanceof java.sql.Timestamp ts) return ts.toLocalDateTime();
        return LocalDateTime.parse(value.toString());
    }

    private String toJson(Object value) {
        try {
            return objectMapper.writeValueAsString(value);
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("Unable to serialize report request", e);
        }
    }

    private boolean hasText(String value) {
        return value != null && !value.isBlank();
    }

    @Scheduled(fixedDelayString = "${reports.cleanup-delay-ms:3600000}")
    public void cleanupReports() {
        jdbc.update("UPDATE report_exports SET status = 'FAILED', error_message = 'Report generation timed out', completed_at = CURRENT_TIMESTAMP WHERE status = 'PENDING' AND created_at < CURRENT_TIMESTAMP - INTERVAL '10 minutes'");
        List<Map<String, Object>> expired = jdbc.queryForList("SELECT id, storage_path FROM report_exports WHERE created_at < CURRENT_TIMESTAMP - INTERVAL '90 days'");
        for (Map<String, Object> row : expired) {
            storageService.deleteObject((String) row.get(STORAGE_PATH));
            jdbc.update("DELETE FROM report_exports WHERE id = ?", row.get("id"));
        }
    }
}