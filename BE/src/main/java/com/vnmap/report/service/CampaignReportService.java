package com.vnmap.report.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
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
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CompletableFuture;

@Service
public class CampaignReportService {

    private static final Logger log = LoggerFactory.getLogger(CampaignReportService.class);
    private static final String REPORT_TYPE = "CAMPAIGN";
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
            ps.setString(2, REPORT_TYPE);
            ps.setString(3, filtersJson);
            ps.setString(4, sectionsJson);
            return ps;
        }, keyHolder);
        Long reportId;
        var keys = keyHolder.getKeyList();
        if (keys == null || keys.isEmpty()) {
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
        String status = (String) row.get("status");
        String path = (String) row.get("storage_path");
        if (includeDownloadUrl) {
            if (!"READY".equals(status)) {
                throw new ResponseStatusException(HttpStatus.CONFLICT, "Report is not ready for download");
            }
            downloadUrl = storageService.generateDownloadUrl(path, DOWNLOAD_URL_TTL);
        }
        return map(row, downloadUrl);
    }

    private void generateReport(long reportId, CampaignReportRequest request) {
        try {
            Map<String, List<Map<String, Object>>> sections = collectSections(request);
            byte[] pdf = renderer.render("Campaign Report #" + reportId, sections);
            if (pdf.length < 4 || pdf[0] != '%' || pdf[1] != 'P' || pdf[2] != 'D' || pdf[3] != 'F') {
                throw new IllegalStateException("Generated report is not a valid PDF");
            }
            LocalDateTime now = LocalDateTime.now();
            String fileName = "campaign-report-" + now.format(FILE_DATE) + "-" + reportId + ".pdf";
            String storagePath = "reports/" + now.format(PATH_DATE) + "/" + fileName;
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

    private Map<String, List<Map<String, Object>>> collectSections(CampaignReportRequest request) {
        Map<String, List<Map<String, Object>>> out = new LinkedHashMap<>();
        for (String section : request.safeSections()) {
            switch (section) {
                case "summary" -> out.put("summary", querySummary(request));
                case "events" -> out.put("events", queryEvents(request));
                case "schools" -> out.put("schools", querySchools(request));
                case "assignments" -> out.put("assignments", queryAssignments(request));
                case "registrations" -> out.put("registrations", queryRegistrations(request));
                case "interactions" -> out.put("interactions", queryInteractions(request));
                case "analytics" -> out.put("analytics", queryAnalytics(request));
                default -> { }
            }
        }
        return out;
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
        String where = filters.isEmpty() ? "" : "WHERE " + String.join(" AND ", filters);
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
            filters.add("s.province_code = ?");
            params.add(request.provinceCode());
        }
        String where = filters.isEmpty() ? "" : "WHERE " + String.join(" AND ", filters);
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
        String where = filters.isEmpty() ? "" : "WHERE " + String.join(" AND ", filters);
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
            filters.add("s.province_code = ?");
            params.add(request.provinceCode());
        }
        String where = filters.isEmpty() ? "" : "WHERE " + String.join(" AND ", filters);
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
        List<String> filters = new ArrayList<>();
        addCampaignFilter(filters, params, request.campaignId(), "i");
        if (request.employeeId() != null) {
            filters.add("i.employee_id = ?");
            params.add(request.employeeId());
        }
        if (hasText(request.schoolUid())) {
            filters.add("i.school_uid = ?");
            params.add(request.schoolUid());
        }
        if (hasText(request.interactionOutcome())) {
            filters.add("i.outcome = ?");
            params.add(request.interactionOutcome());
        }
        if (request.fromDate() != null) {
            filters.add("DATE(i.created_at) >= ?");
            params.add(request.fromDate());
        }
        if (request.toDate() != null) {
            filters.add("DATE(i.created_at) <= ?");
            params.add(request.toDate());
        }
        String where = filters.isEmpty() ? "" : "WHERE " + String.join(" AND ", filters);
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
        List<String> filters = new ArrayList<>();
        addCampaignFilter(filters, params, request.campaignId(), "i");
        String where = filters.isEmpty() ? "" : "WHERE " + String.join(" AND ", filters);
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
        return filters.isEmpty() ? "" : "WHERE " + String.join(" AND ", filters);
    }

    private List<String> eventFilters(CampaignReportRequest request, List<Object> params, String alias) {
        List<String> filters = new ArrayList<>();
        addCampaignFilter(filters, params, request.campaignId(), alias);
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
            filters.add("DATE(" + alias + ".starts_at) >= ?");
            params.add(request.fromDate());
        }
        if (request.toDate() != null) {
            filters.add("DATE(" + alias + ".starts_at) <= ?");
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
        if (from != null && to != null && from.plusMonths(6).isBefore(to) && !"ADMIN".equals(user.role())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Report date range cannot exceed 6 months");
        }
    }

    private Long findPendingReport(Long userId) {
        return jdbc.query(
                """
                SELECT id FROM report_exports
                WHERE created_by_user_id = ? AND report_type = ? AND status = 'PENDING'
                ORDER BY created_at DESC LIMIT 1
                """,
                (rs, rowNum) -> rs.getLong("id"),
                userId,
                REPORT_TYPE
        ).stream().findFirst().orElse(null);
    }

    private void requireManagerOrAdmin(CurrentUser user) {
        if (user == null || !("MANAGER".equals(user.role()) || "ADMIN".equals(user.role()))) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Manager or admin role required");
        }
    }

    private void authorizeReport(Map<String, Object> row, CurrentUser user) {
        if ("ADMIN".equals(user.role())) {
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
                (String) row.get("status"),
                (String) row.get("file_name"),
                (String) row.get("storage_path"),
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
            storageService.deleteObject((String) row.get("storage_path"));
            jdbc.update("DELETE FROM report_exports WHERE id = ?", row.get("id"));
        }
    }
}

