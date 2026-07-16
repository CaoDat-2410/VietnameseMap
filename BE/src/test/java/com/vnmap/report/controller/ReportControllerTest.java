package com.vnmap.report.controller;

import com.vnmap.common.model.PagedResponse;
import com.vnmap.common.security.CurrentUser;
import com.vnmap.report.dto.CampaignReportRequest;
import com.vnmap.report.dto.ReportExportResponse;
import com.vnmap.report.service.CampaignReportService;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

class ReportControllerTest {
    @Test
    void delegatesCreationListingAndBothReportLookups() {
        CampaignReportService service = mock(CampaignReportService.class);
        ReportController controller = new ReportController(service);
        CurrentUser user = new CurrentUser(1L, "admin@test", "ADMIN", "ACTIVE", null, null);
        CampaignReportRequest request = new CampaignReportRequest("CAMPAIGN", null, null, null, null, null, null, null, null, null, null, null, false, List.of(), List.of(), "CHARTS_AND_TABLES", Map.of());
        ReportExportResponse report = mock(ReportExportResponse.class);
        PagedResponse<ReportExportResponse> page = PagedResponse.of(List.of(report), 0, 20, 1);
        when(service.createCampaignReport(request, user)).thenReturn(report);
        when(service.listReports(user, 0, 20, "READY", "CAMPAIGN")).thenReturn(page);
        when(service.getReport(3L, user, false)).thenReturn(report);
        when(service.getReport(3L, user, true)).thenReturn(report);

        assertThat(controller.createCampaignPdf(user, request).getBody().getData()).isSameAs(report);
        assertThat(controller.listReports(user, 0, 20, "READY", "CAMPAIGN").getBody().getData()).isSameAs(page);
        assertThat(controller.getReport(user, 3L).getBody().getData()).isSameAs(report);
        assertThat(controller.getDownloadUrl(user, 3L).getBody().getData()).isSameAs(report);
    }
}
