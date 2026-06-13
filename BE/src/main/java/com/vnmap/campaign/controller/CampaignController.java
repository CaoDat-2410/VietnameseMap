package com.vnmap.campaign.controller;

import com.vnmap.campaign.dto.*;
import com.vnmap.campaign.service.CampaignService;
import com.vnmap.common.model.ApiResponse;
import com.vnmap.common.model.PagedResponse;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@Validated
@RequestMapping("/api/v1")
public class CampaignController {

    private final CampaignService campaignService;

    public CampaignController(CampaignService campaignService) {
        this.campaignService = campaignService;
    }

    @GetMapping("/schools")
    public ResponseEntity<ApiResponse<PagedResponse<SchoolDto>>> getSchools(
            @RequestParam(defaultValue = "0") @Min(0) int page,
            @RequestParam(defaultValue = "50") @Min(1) @Max(200) int limit,
            @RequestParam(required = false) String provinceCode,
            @RequestParam(required = false) String communeCode,
            @RequestParam(required = false) String area,
            @RequestParam(required = false) String q
    ) {
        return ResponseEntity.ok(ApiResponse.success(
                campaignService.getSchools(page, limit, provinceCode, communeCode, area, q),
                "Schools retrieved successfully"
        ));
    }

    @GetMapping("/schools/{schoolUid}")
    public ResponseEntity<ApiResponse<SchoolDetailDto>> getSchool(@PathVariable String schoolUid) {
        return ResponseEntity.ok(ApiResponse.success(
                campaignService.getSchoolDetail(schoolUid),
                "School retrieved successfully"
        ));
    }

    @GetMapping("/campaigns")
    public ResponseEntity<ApiResponse<List<CampaignDto>>> getCampaigns() {
        return ResponseEntity.ok(ApiResponse.success(
                campaignService.getCampaigns(),
                "Campaigns retrieved successfully"
        ));
    }

    @PostMapping("/campaigns")
    public ResponseEntity<ApiResponse<CampaignDto>> createCampaign(@Valid @RequestBody CampaignRequest request) {
        return ResponseEntity.ok(ApiResponse.success(
                campaignService.createCampaign(request),
                "Campaign created successfully"
        ));
    }

    @GetMapping("/campaigns/{id}")
    public ResponseEntity<ApiResponse<CampaignDto>> getCampaign(@PathVariable long id) {
        return ResponseEntity.ok(ApiResponse.success(
                campaignService.getCampaign(id),
                "Campaign retrieved successfully"
        ));
    }

    @PutMapping("/campaigns/{id}")
    public ResponseEntity<ApiResponse<CampaignDto>> updateCampaign(
            @PathVariable long id,
            @Valid @RequestBody CampaignRequest request
    ) {
        return ResponseEntity.ok(ApiResponse.success(
                campaignService.updateCampaign(id, request),
                "Campaign updated successfully"
        ));
    }

    @GetMapping("/campaigns/{id}/dashboard")
    public ResponseEntity<ApiResponse<CampaignDashboardDto>> getDashboard(@PathVariable long id) {
        return ResponseEntity.ok(ApiResponse.success(
                campaignService.getDashboard(id),
                "Campaign dashboard retrieved successfully"
        ));
    }

    @GetMapping("/campaigns/{id}/events")
    public ResponseEntity<ApiResponse<List<CampaignEventDto>>> getEvents(@PathVariable long id) {
        return ResponseEntity.ok(ApiResponse.success(
                campaignService.getEvents(id),
                "Events retrieved successfully"
        ));
    }

    @PostMapping("/campaigns/{id}/events")
    public ResponseEntity<ApiResponse<CampaignEventDto>> createEvent(
            @PathVariable long id,
            @Valid @RequestBody CampaignEventRequest request
    ) {
        return ResponseEntity.ok(ApiResponse.success(
                campaignService.createEvent(id, request),
                "Event created successfully"
        ));
    }

    @GetMapping("/events/{eventId}")
    public ResponseEntity<ApiResponse<CampaignEventDto>> getEvent(@PathVariable long eventId) {
        return ResponseEntity.ok(ApiResponse.success(
                campaignService.getEvent(eventId),
                "Event retrieved successfully"
        ));
    }

    @PutMapping("/events/{eventId}")
    public ResponseEntity<ApiResponse<CampaignEventDto>> updateEvent(
            @PathVariable long eventId,
            @Valid @RequestBody CampaignEventRequest request
    ) {
        return ResponseEntity.ok(ApiResponse.success(
                campaignService.updateEvent(eventId, request),
                "Event updated successfully"
        ));
    }

    @PostMapping("/events/{eventId}/schools")
    public ResponseEntity<ApiResponse<Void>> assignSchool(
            @PathVariable long eventId,
            @Valid @RequestBody AssignSchoolRequest request
    ) {
        campaignService.assignSchool(eventId, request.schoolUid());
        return ResponseEntity.ok(ApiResponse.success(null, "School assigned successfully"));
    }

    @DeleteMapping("/events/{eventId}/schools/{schoolUid}")
    public ResponseEntity<ApiResponse<Void>> removeSchool(
            @PathVariable long eventId,
            @PathVariable String schoolUid
    ) {
        campaignService.removeSchool(eventId, schoolUid);
        return ResponseEntity.ok(ApiResponse.success(null, "School removed successfully"));
    }

    @PostMapping("/events/{eventId}/assignments")
    public ResponseEntity<ApiResponse<Void>> assignEmployee(
            @PathVariable long eventId,
            @Valid @RequestBody AssignEmployeeRequest request
    ) {
        campaignService.assignEmployee(eventId, request.employeeId());
        return ResponseEntity.ok(ApiResponse.success(null, "Employee assigned successfully"));
    }

    @DeleteMapping("/events/{eventId}/assignments/{employeeId}")
    public ResponseEntity<ApiResponse<Void>> removeEmployee(
            @PathVariable long eventId,
            @PathVariable long employeeId
    ) {
        campaignService.removeEmployee(eventId, employeeId);
        return ResponseEntity.ok(ApiResponse.success(null, "Employee removed successfully"));
    }

    @GetMapping("/events/{eventId}/interactions")
    public ResponseEntity<ApiResponse<List<InteractionDto>>> getInteractions(@PathVariable long eventId) {
        return ResponseEntity.ok(ApiResponse.success(
                campaignService.getInteractions(eventId),
                "Interactions retrieved successfully"
        ));
    }

    @PostMapping("/events/{eventId}/interactions")
    public ResponseEntity<ApiResponse<InteractionDto>> createInteraction(
            @PathVariable long eventId,
            @Valid @RequestBody CreateInteractionRequest request
    ) {
        return ResponseEntity.ok(ApiResponse.success(
                campaignService.createInteraction(eventId, request),
                "Interaction created successfully"
        ));
    }
}
