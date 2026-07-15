package com.vnmap.report.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.vnmap.common.model.PagedResponse;
import com.vnmap.common.security.CurrentUser;
import com.vnmap.report.dto.CampaignReportRequest;
import com.vnmap.report.dto.ReportExportResponse;
import com.vnmap.storage.service.StorageService;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.web.server.ResponseStatusException;

import java.sql.Timestamp;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

class CampaignReportServiceTest {
    private final JdbcTemplate jdbc = mock(JdbcTemplate.class);
    private final StorageService storage = mock(StorageService.class);
    private final PdfReportRenderer renderer = mock(PdfReportRenderer.class);
    private final CampaignReportService service = new CampaignReportService(jdbc, new ObjectMapper(), storage, renderer);
    private final CurrentUser admin = new CurrentUser(1L, "a@test", "ADMIN", "ACTIVE", null, null);
    private final CurrentUser manager = new CurrentUser(2L, "m@test", "MANAGER", "ACTIVE", null, null);

    @Test
    void getsReadyReportAndAppliesOwnershipAndDownloadRules() {
        Map<String, Object> row = reportRow(2L, "READY", "reports/a.pdf");
        when(jdbc.queryForMap(anyString(), eq(4L))).thenReturn(row);
        when(storage.generateDownloadUrl(eq("reports/a.pdf"), any())).thenReturn("signed-url");
        ReportExportResponse result = service.getReport(4L, manager, true);
        assertThat(result.reportId()).isEqualTo(4L);
        assertThat(result.downloadUrl()).isEqualTo("signed-url");

        when(jdbc.queryForMap(anyString(), eq(5L))).thenReturn(reportRow(99L, "READY", "a"));
        assertThatThrownBy(() -> service.getReport(5L, manager, false)).isInstanceOf(ResponseStatusException.class)
                .extracting(e -> ((ResponseStatusException) e).getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN);
        when(jdbc.queryForMap(anyString(), eq(6L))).thenReturn(reportRow(2L, "PENDING", null));
        assertThatThrownBy(() -> service.getReport(6L, manager, true)).isInstanceOf(ResponseStatusException.class)
                .extracting(e -> ((ResponseStatusException) e).getStatusCode()).isEqualTo(HttpStatus.CONFLICT);
        assertThatThrownBy(() -> service.getReport(4L, new CurrentUser(3L, "s", "STUDENT", "ACTIVE", null, null), false))
                .isInstanceOf(ResponseStatusException.class);
    }

    @Test
    void listsReportsWithCappedPaginationAndMapsRows() {
        when(jdbc.queryForObject(startsWith("SELECT COUNT"), eq(Long.class), any(Object[].class))).thenReturn(1L);
        when(jdbc.queryForList(startsWith("SELECT * FROM report_exports"), any(Object[].class))).thenReturn(List.of(reportRow(1L, "READY", "x")));
        PagedResponse<ReportExportResponse> result = service.listReports(manager, -1, 999, "READY", "CAMPAIGN");
        assertThat(result.page()).isZero();
        assertThat(result.limit()).isEqualTo(100);
        assertThat(result.items()).singleElement().extracting(ReportExportResponse::status).isEqualTo("READY");
    }

    @Test
    void collectsEverySupportedSectionAndKpisForReportTypes() {
        when(jdbc.queryForList(anyString(), any(Object[].class))).thenReturn(List.of());
        when(jdbc.queryForObject(anyString(), eq(Long.class), any(Object[].class))).thenReturn(1L);
        for (String type : List.of("CAMPAIGN", "EVENT", "SCHOOL", "REGION")) {
            CampaignReportRequest request = request(type, null, null, null, null, null, null, null, null, null, null, null, false, null);
            Object sections = ReflectionTestUtils.invokeMethod(service, "collectSections", request);
            assertThat((Map<?, ?>) sections).isNotEmpty();
            Object kpis = ReflectionTestUtils.invokeMethod(service, "computeKpis", request);
            assertThat((List<?>) kpis).hasSize(4);
        }
    }

    @Test
    void appliesAllFiltersAndValidatesDateRanges() {
        CampaignReportRequest request = request("CAMPAIGN", 4L, 5L, LocalDate.of(2026, 1, 1), LocalDate.of(2026, 2, 1), "ACTIVE", "FAIR", "79", "school", 7L, "REGISTERED", "INTERESTED", false, List.of("events", "schools", "assignments", "registrations", "interactions"));
        when(jdbc.queryForList(anyString(), any(Object[].class))).thenReturn(List.of());
        ReflectionTestUtils.invokeMethod(service, "collectSections", request);
        verify(jdbc, atLeast(5)).queryForList(anyString(), any(Object[].class));
        CampaignReportRequest invalid = request("CAMPAIGN", null, null, LocalDate.of(2026, 2, 1), LocalDate.of(2026, 1, 1), null, null, null, null, null, null, null, false, null);
        assertThatThrownBy(() -> service.createCampaignReport(invalid, admin)).isInstanceOf(ResponseStatusException.class);
        CampaignReportRequest tooLong = request("CAMPAIGN", null, null, LocalDate.of(2025, 1, 1), LocalDate.of(2026, 1, 2), null, null, null, null, null, null, null, false, null);
        assertThatThrownBy(() -> service.createCampaignReport(tooLong, manager)).isInstanceOf(ResponseStatusException.class);
    }

    @Test
    void generatesReadyAndFailedReportsAndCleansExpiredRows() {
        CampaignReportRequest request = request("SCHOOL", null, null, null, null, null, null, null, null, null, null, null, false, List.of("summary"));
        when(jdbc.queryForList(anyString(), any(Object[].class))).thenReturn(List.of());
        when(jdbc.queryForObject(anyString(), eq(Long.class), any(Object[].class))).thenReturn(1L);
        when(renderer.render(anyString(), anyString(), anyList(), anyMap(), anyMap())).thenReturn(new byte[]{'%', 'P', 'D', 'F'});
        ReflectionTestUtils.invokeMethod(service, "generateReport", 8L, request);
        verify(storage).uploadGeneratedObject(startsWith("reports/"), any(), eq("application/pdf"));

        when(renderer.render(anyString(), anyString(), anyList(), anyMap(), anyMap())).thenReturn(new byte[]{1});
        ReflectionTestUtils.invokeMethod(service, "generateReport", 9L, request);
        verify(jdbc, atLeastOnce()).update(contains("status = 'FAILED'"), any(), eq(9L));

        when(jdbc.queryForList(startsWith("SELECT id, storage_path"))).thenReturn(List.of(Map.of("id", 3L, "storage_path", "reports/old.pdf")));
        service.cleanupReports();
        verify(storage).deleteObject("reports/old.pdf");
    }

    private static Map<String, Object> reportRow(long owner, String status, String path) {
        return Map.of("id", 4L, "created_by_user_id", owner, "report_type", "CAMPAIGN", "status", status,
                "file_name", "file.pdf", "storage_path", path == null ? "" : path, "error_message", "",
                "created_at", Timestamp.valueOf(LocalDateTime.of(2026, 1, 1, 0, 0)), "completed_at", Timestamp.valueOf(LocalDateTime.of(2026, 1, 2, 0, 0)));
    }

    private static CampaignReportRequest request(String type, Long campaign, Long event, LocalDate from, LocalDate to, String eventStatus, String eventType, String province, String school, Long employee, String registration, String outcome, Boolean archived, List<String> sections) {
        return new CampaignReportRequest(type, campaign, event, from, to, eventStatus, eventType, province, school, employee, registration, outcome, archived, sections, Map.of());
    }
}