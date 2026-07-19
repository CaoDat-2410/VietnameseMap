package com.vnmap.campaign.controller;

import com.vnmap.campaign.dto.AggregateDashboardDto;
import com.vnmap.campaign.dto.ChannelBreakdownDto;
import com.vnmap.campaign.dto.EmployeeRankingDto;
import com.vnmap.campaign.dto.TrendPointDto;
import com.vnmap.campaign.service.AnalyticsService;
import com.vnmap.common.model.ApiResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/analytics")
public class AnalyticsController {

    private final AnalyticsService analyticsService;

    public AnalyticsController(AnalyticsService analyticsService) {
        this.analyticsService = analyticsService;
    }

    /**
     * Aggregate dashboard across all (or filtered) campaigns.
     *
     * @param campaignId optional — scope to a single campaign
     * @param schoolUid  optional — scope to a single school
     */
    @GetMapping("/aggregate")
    public ResponseEntity<ApiResponse<AggregateDashboardDto>> getAggregateDashboard(
            @RequestParam(required = false) Long campaignId,
            @RequestParam(required = false) String schoolUid
    ) {
        return ResponseEntity.ok(ApiResponse.success(
                analyticsService.getAggregateDashboard(campaignId, schoolUid),
                "Aggregate dashboard retrieved successfully"
        ));
    }

    /**
     * Daily interactions count for the last {@code days} days, scoped by the
     * same optional filters as {@code /aggregate}. Days with zero interactions
     * are returned as 0 so the line chart is continuous.
     */
    @GetMapping("/trend")
    public ResponseEntity<ApiResponse<List<TrendPointDto>>> getTrend(
            @RequestParam(defaultValue = "30") int days,
            @RequestParam(required = false) Long campaignId,
            @RequestParam(required = false) String schoolUid
    ) {
        return ResponseEntity.ok(ApiResponse.success(
                analyticsService.getInteractionsTrend(days, campaignId, schoolUid),
                "Trend retrieved"
        ));
    }

    /**
     * Interactions grouped by channel (PHONE / EMAIL / ZALO / VISIT / EVENT / …).
     */
    @GetMapping("/channels")
    public ResponseEntity<ApiResponse<List<ChannelBreakdownDto>>> getChannels(
            @RequestParam(required = false) Long campaignId,
            @RequestParam(required = false) String schoolUid
    ) {
        return ResponseEntity.ok(ApiResponse.success(
                analyticsService.getChannelBreakdown(campaignId, schoolUid),
                "Channels retrieved"
        ));
    }

    /**
     * Top {@code limit} employees by number of interactions in scope.
     */
    @GetMapping("/employees")
    public ResponseEntity<ApiResponse<List<EmployeeRankingDto>>> getTopEmployees(
            @RequestParam(defaultValue = "10") int limit,
            @RequestParam(required = false) Long campaignId,
            @RequestParam(required = false) String schoolUid
    ) {
        return ResponseEntity.ok(ApiResponse.success(
                analyticsService.getTopEmployees(limit, campaignId, schoolUid),
                "Top employees retrieved"
        ));
    }
}