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
import java.time.Month;
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
        CurrentUser student = new CurrentUser(3L, "s", "STUDENT", "ACTIVE", null, null);
        assertThatThrownBy(() -> service.getReport(4L, student, false))
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
        CampaignReportRequest request = request("CAMPAIGN", 4L, 5L, LocalDate.of(2026, Month.JANUARY, 1), LocalDate.of(2026, Month.FEBRUARY, 1), "ACTIVE", "FAIR", "79", "school", 7L, "REGISTERED", "INTERESTED", false, List.of("events", "schools", "assignments", "registrations", "interactions"));
        when(jdbc.queryForList(anyString(), any(Object[].class))).thenReturn(List.of());
        ReflectionTestUtils.invokeMethod(service, "collectSections", request);
        verify(jdbc, atLeast(5)).queryForList(anyString(), any(Object[].class));
        CampaignReportRequest invalid = request("CAMPAIGN", null, null, LocalDate.of(2026, Month.FEBRUARY, 1), LocalDate.of(2026, Month.JANUARY, 1), null, null, null, null, null, null, null, false, null);
        assertThatThrownBy(() -> service.createCampaignReport(invalid, admin)).isInstanceOf(ResponseStatusException.class);
        CampaignReportRequest tooLong = request("CAMPAIGN", null, null, LocalDate.of(2025, Month.JANUARY, 1), LocalDate.of(2026, Month.JANUARY, 2), null, null, null, null, null, null, null, false, null);
        assertThatThrownBy(() -> service.createCampaignReport(tooLong, manager)).isInstanceOf(ResponseStatusException.class);
    }

    @Test
    void generatesReadyAndFailedReportsAndCleansExpiredRows() {
        CampaignReportRequest request = request("SCHOOL", null, null, null, null, null, null, null, null, null, null, null, false, List.of("summary"));
        when(jdbc.queryForList(anyString(), any(Object[].class))).thenReturn(List.of());
        when(jdbc.queryForObject(anyString(), eq(Long.class), any(Object[].class))).thenReturn(1L);
        when(renderer.render(anyString(), anyString(), anyList(), anyMap(), anyList(), anyString())).thenReturn(new byte[]{'%', 'P', 'D', 'F'});
        ReflectionTestUtils.invokeMethod(service, "generateReport", 8L, request);
        verify(storage).uploadGeneratedObject(startsWith("reports/"), any(), eq("application/pdf"));

        when(renderer.render(anyString(), anyString(), anyList(), anyMap(), anyList(), anyString())).thenReturn(new byte[]{1});
        ReflectionTestUtils.invokeMethod(service, "generateReport", 9L, request);
        verify(jdbc, atLeastOnce()).update(contains("status = 'FAILED'"), any(), eq(9L));

        when(jdbc.queryForList(startsWith("SELECT id, storage_path"))).thenReturn(List.of(Map.of("id", 3L, "storage_path", "reports/old.pdf")));
        service.cleanupReports();
        verify(storage).deleteObject("reports/old.pdf");
    }

    @Test
    void buildsEveryConfiguredDataDerivedChart() {
        List<Map<String, Object>> rows = List.of(Map.ofEntries(
                Map.entry("status", "ACTIVE"), Map.entry("campaign_id", 1L),
                Map.entry("province_name", "Ha Noi"), Map.entry("school_name", "School A"),
                Map.entry("interactions", 4L), Map.entry("schools", 2L), Map.entry("events", 3L),
                Map.entry("event_type", "FAIR"), Map.entry("channel", "PHONE"),
                Map.entry("outcome", "INTERESTED"), Map.entry("total", 5L),
                Map.entry("created_at", "2026-01-01T10:00:00")));
        when(jdbc.queryForList(anyString(), any(Object[].class))).thenReturn(rows);
        for (String type : List.of("CAMPAIGN", "EVENT", "SCHOOL", "REGION")) {
            CampaignReportRequest request = request(type, null, null, null, null, null, null, null, null, null, null, null, false, null);
            Map<String, List<Map<String, Object>>> sections = new java.util.LinkedHashMap<>();
            sections.put("summary", rows); sections.put("events", rows); sections.put("schools", rows); sections.put("interactions", rows); sections.put("analytics", rows);
            Object charts = ReflectionTestUtils.invokeMethod(service, "buildCharts", request, sections);
            assertThat((List<?>) charts).hasSize(4);
        }
    }
    @Test
    void coversAggregationDateConversionTitlesAndTextBranches() {
        CampaignReportRequest allDates = request("CAMPAIGN", null, null, null, null, null, null, null, null, null, null, null, true, null);
        CampaignReportRequest period = request(
                "EVENT", null, null,
                LocalDate.of(2026, Month.JANUARY, 1),
                LocalDate.of(2026, Month.JANUARY, 31),
                null, null, null, null, null, null, null, true, null
        );

        List<ReportChart.Datum> empty = ReflectionTestUtils.invokeMethod(service, "grouped", null, "label", null);
        assertThat(empty).isEmpty();
        List<Map<String, Object>> rows = List.of(
                Map.of("label", "A", "value", 3),
                Map.of("label", "A", "value", "2"),
                Map.of("value", "invalid")
        );
        List<ReportChart.Datum> grouped = ReflectionTestUtils.invokeMethod(service, "grouped", rows, "label", "value");
        assertThat(grouped).extracting(ReportChart.Datum::value).contains(5L, 0L);
        List<ReportChart.Datum> counted = ReflectionTestUtils.invokeMethod(service, "values", rows, "label", null);
        assertThat(counted).extracting(ReportChart.Datum::value).contains(2L, 1L);

        List<ReportChart.Datum> noDates = ReflectionTestUtils.invokeMethod(service, "groupedDates", (Object) null);
        assertThat(noDates).isEmpty();
        List<ReportChart.Datum> dates = ReflectionTestUtils.invokeMethod(
                service, "groupedDates", List.of(Map.of(), Map.of("created_at", "x"), Map.of("created_at", "2026-01-02T08:00:00"))
        );
        assertThat(dates).extracting(ReportChart.Datum::label).containsExactly("2026-01-02", "Unknown", "x");

        ReportChart emptyChart = ReflectionTestUtils.invokeMethod(
                service, "chart", "id", "Title", "Description", "BAR", List.of(), allDates, "source"
        );
        assertThat(emptyChart.insight()).contains("No matching records");
        ReportChart populatedChart = ReflectionTestUtils.invokeMethod(
                service, "chart", "id", "Title", "Description", "BAR", grouped, period, "source"
        );
        assertThat(populatedChart.insight()).contains("Highest value");
        assertThat(populatedChart.period()).contains("2026-01-01", "2026-01-31");

        for (String type : List.of("CAMPAIGN", "EVENT", "SCHOOL", "REGION")) {
            CampaignReportRequest typed = request(type, null, null, null, null, null, null, null, null, null, null, null, true, null);
            assertThat((String) ReflectionTestUtils.invokeMethod(service, "titleFor", typed)).endsWith("Report");
        }
        LocalDateTime dateTime = LocalDateTime.of(2026, Month.MARCH, 2, 3, 4);
        assertThat((LocalDateTime) ReflectionTestUtils.invokeMethod(service, "toLocalDateTime", (Object) null)).isNull();
        assertThat((LocalDateTime) ReflectionTestUtils.invokeMethod(service, "toLocalDateTime", dateTime)).isEqualTo(dateTime);
        assertThat((LocalDateTime) ReflectionTestUtils.invokeMethod(service, "toLocalDateTime", Timestamp.valueOf(dateTime))).isEqualTo(dateTime);
        assertThat((LocalDateTime) ReflectionTestUtils.invokeMethod(service, "toLocalDateTime", dateTime.toString())).isEqualTo(dateTime);
        assertThat((Boolean) ReflectionTestUtils.invokeMethod(service, "hasText", (Object) null)).isFalse();
        assertThat((Boolean) ReflectionTestUtils.invokeMethod(service, "hasText", " ")).isFalse();
        assertThat((Boolean) ReflectionTestUtils.invokeMethod(service, "hasText", "value")).isTrue();
    }

    @Test
    void coversEmptyAndFullySpecifiedFilterHelpers() {
        CampaignReportRequest full = request(
                "CAMPAIGN", 4L, 5L,
                LocalDate.of(2026, Month.JANUARY, 1),
                LocalDate.of(2026, Month.FEBRUARY, 1),
                "ACTIVE", "FAIR", "79", "school", 7L, "REGISTERED", "INTERESTED", false, null
        );
        List<Object> params = new java.util.ArrayList<>();
        assertThat((String) ReflectionTestUtils.invokeMethod(service, "campaignWhere", full, params, "c", true))
                .contains("c.id", "start_date", "end_date", "ARCHIVED");
        params.clear();
        assertThat((String) ReflectionTestUtils.invokeMethod(service, "campaignWhere", full, params, "c", false))
                .contains("c.campaign_id");
        params.clear();
        assertThat((List<?>) ReflectionTestUtils.invokeMethod(service, "eventFilters", full, params, "e")).hasSize(8);
        params.clear();
        assertThat((List<?>) ReflectionTestUtils.invokeMethod(service, "registrationFilters", full, params)).hasSize(4);
        params.clear();
        assertThat((List<?>) ReflectionTestUtils.invokeMethod(service, "schoolFilters", full, params)).hasSize(5);
        params.clear();
        assertThat((List<?>) ReflectionTestUtils.invokeMethod(service, "interactionFilters", full, params, "i")).hasSize(8);

        CampaignReportRequest emptyArchived = request("CAMPAIGN", null, null, null, null, null, null, null, null, null, null, null, true, null);
        params.clear();
        assertThat((String) ReflectionTestUtils.invokeMethod(service, "campaignWhere", emptyArchived, params, "c", true)).isEmpty();
        params.clear();
        assertThat((List<?>) ReflectionTestUtils.invokeMethod(service, "eventFilters", emptyArchived, params, "e")).isEmpty();
        params.clear();
        ReflectionTestUtils.invokeMethod(service, "addCampaignFilter", new java.util.ArrayList<>(), params, null, "e");
        assertThat(params).isEmpty();
    }

    @Test
    void coversPermissionsRangesSerializationAndAdminOwnership() throws Exception {
        CurrentUser student = new CurrentUser(3L, "s", "STUDENT", "ACTIVE", null, null);
        assertThatThrownBy(() -> ReflectionTestUtils.invokeMethod(service, "requireManagerOrAdmin", (Object) null))
                .isInstanceOf(ResponseStatusException.class);
        assertThatThrownBy(() -> ReflectionTestUtils.invokeMethod(service, "requireManagerOrAdmin", student))
                .isInstanceOf(ResponseStatusException.class);
        ReflectionTestUtils.invokeMethod(service, "requireManagerOrAdmin", manager);
        ReflectionTestUtils.invokeMethod(service, "requireManagerOrAdmin", admin);
        ReflectionTestUtils.invokeMethod(service, "authorizeReport", reportRow(99L, "READY", "x"), admin);
        ReflectionTestUtils.invokeMethod(service, "authorizeReport", reportRow(2L, "READY", "x"), manager);

        CampaignReportRequest noRange = request("CAMPAIGN", null, null, null, null, null, null, null, null, null, null, null, false, null);
        ReflectionTestUtils.invokeMethod(service, "validateRange", noRange, manager);
        CampaignReportRequest longRange = request(
                "CAMPAIGN", null, null,
                LocalDate.of(2025, Month.JANUARY, 1),
                LocalDate.of(2026, Month.JANUARY, 1),
                null, null, null, null, null, null, null, false, null
        );
        ReflectionTestUtils.invokeMethod(service, "validateRange", longRange, admin);

        ObjectMapper brokenMapper = mock(ObjectMapper.class);
        when(brokenMapper.writeValueAsString(any())).thenThrow(new com.fasterxml.jackson.core.JsonProcessingException("broken") {});
        CampaignReportService broken = new CampaignReportService(jdbc, brokenMapper, storage, renderer);
        Map<String, Integer> data = Map.of("a", 1);
        assertThatThrownBy(() -> ReflectionTestUtils.invokeMethod(broken, "toJson", data))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("serialize");
    }

    @Test
    void createsReportAndCoversPendingAndMissingKeyBranches() {
        JdbcTemplate createJdbc = mock(JdbcTemplate.class);
        StorageService createStorage = mock(StorageService.class);
        PdfReportRenderer createRenderer = mock(PdfReportRenderer.class);
        CampaignReportService createService = new CampaignReportService(createJdbc, new ObjectMapper(), createStorage, createRenderer);
        CampaignReportRequest request = request("CAMPAIGN", null, null, null, null, null, null, null, null, null, null, null, false, null);
        doReturn(List.of()).when(createJdbc).query(contains("status = 'PENDING'"), any(org.springframework.jdbc.core.RowMapper.class), eq(1L));
        doAnswer(invocation -> {
            org.springframework.jdbc.support.KeyHolder holder = invocation.getArgument(1);
            holder.getKeyList().add(new java.util.HashMap<>(Map.of("id", 4L)));
            return 1;
        }).when(createJdbc).update(any(org.springframework.jdbc.core.PreparedStatementCreator.class), any(org.springframework.jdbc.support.KeyHolder.class));
        when(createJdbc.queryForMap(anyString(), eq(4L))).thenReturn(reportRow(1L, "PENDING", ""));
        when(createJdbc.queryForList(anyString(), any(Object[].class))).thenReturn(List.of());
        when(createJdbc.queryForObject(anyString(), eq(Long.class), any(Object[].class))).thenReturn(0L);
        when(createRenderer.render(anyString(), anyString(), anyList(), anyMap(), anyList(), anyString()))
                .thenReturn(new byte[]{'%', 'P', 'D', 'F'});
        ReportExportResponse created = createService.createCampaignReport(request, admin);
        assertThat(created.reportId()).isEqualTo(4L);
        verify(createStorage, timeout(3000)).uploadGeneratedObject(startsWith("reports/"), any(), eq("application/pdf"));

        JdbcTemplate pendingJdbc = mock(JdbcTemplate.class);
        CampaignReportService pendingService = new CampaignReportService(pendingJdbc, new ObjectMapper(), storage, renderer);
        doReturn(List.of(7L)).when(pendingJdbc).query(contains("status = 'PENDING'"), any(org.springframework.jdbc.core.RowMapper.class), eq(1L));
        assertThatThrownBy(() -> pendingService.createCampaignReport(request, admin))
                .isInstanceOf(ResponseStatusException.class)
                .hasMessageContaining("already");

        JdbcTemplate missingKeyJdbc = mock(JdbcTemplate.class);
        CampaignReportService missingKeyService = new CampaignReportService(missingKeyJdbc, new ObjectMapper(), storage, renderer);
        doReturn(List.of()).when(missingKeyJdbc).query(contains("status = 'PENDING'"), any(org.springframework.jdbc.core.RowMapper.class), eq(1L));
        assertThatThrownBy(() -> missingKeyService.createCampaignReport(request, admin))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("generated key");
    }
    private static Map<String, Object> reportRow(long owner, String status, String path) {
        return Map.of("id", 4L, "created_by_user_id", owner, "report_type", "CAMPAIGN", "status", status,
                "file_name", "file.pdf", "storage_path", path == null ? "" : path, "error_message", "",
                "created_at", Timestamp.valueOf(LocalDateTime.of(2026, Month.JANUARY, 1, 0, 0)), "completed_at", Timestamp.valueOf(LocalDateTime.of(2026, Month.JANUARY, 2, 0, 0)));
    }

    private static CampaignReportRequest request(String type, Long campaign, Long event, LocalDate from, LocalDate to, String eventStatus, String eventType, String province, String school, Long employee, String registration, String outcome, Boolean archived, List<String> sections) {
        return new CampaignReportRequest(type, campaign, event, from, to, eventStatus, eventType, province, school, employee, registration, outcome, archived, sections, List.of(), "CHARTS_AND_TABLES", Map.of());
    }
}