package com.vnmap.report.controller;

import com.vnmap.common.model.ApiResponse;
import com.vnmap.common.model.PagedResponse;
import com.vnmap.common.security.CurrentUser;
import com.vnmap.report.dto.CampaignReportRequest;
import com.vnmap.report.dto.ReportExportResponse;
import com.vnmap.report.service.CampaignReportService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/reports")
public class ReportController {

    private final CampaignReportService reportService;

    public ReportController(CampaignReportService reportService) {
        this.reportService = reportService;
    }

    @PostMapping("/campaigns/pdf")
    public ResponseEntity<ApiResponse<ReportExportResponse>> createCampaignPdf(
            @AuthenticationPrincipal CurrentUser user,
            @Valid @RequestBody CampaignReportRequest request
    ) {
        return ResponseEntity.ok(ApiResponse.success(
                reportService.createCampaignReport(request, user),
                "Report generation started"
        ));
    }

    @GetMapping
    public ResponseEntity<ApiResponse<PagedResponse<ReportExportResponse>>> listReports(
            @AuthenticationPrincipal CurrentUser user,
            @RequestParam(defaultValue = "0") @Min(0) int page,
            @RequestParam(defaultValue = "20") @Min(1) @Max(100) int limit,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String reportType
    ) {
        return ResponseEntity.ok(ApiResponse.success(
                reportService.listReports(user, page, limit, status, reportType),
                "Reports retrieved successfully"
        ));
    }

    @GetMapping("/{reportId}")
    public ResponseEntity<ApiResponse<ReportExportResponse>> getReport(
            @AuthenticationPrincipal CurrentUser user,
            @PathVariable long reportId
    ) {
        return ResponseEntity.ok(ApiResponse.success(reportService.getReport(reportId, user, false)));
    }

    @GetMapping("/{reportId}/download-url")
    public ResponseEntity<ApiResponse<ReportExportResponse>> getDownloadUrl(
            @AuthenticationPrincipal CurrentUser user,
            @PathVariable long reportId
    ) {
        return ResponseEntity.ok(ApiResponse.success(reportService.getReport(reportId, user, true)));
    }
}
