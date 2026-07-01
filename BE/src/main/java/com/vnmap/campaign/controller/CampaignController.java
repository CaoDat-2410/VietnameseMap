package com.vnmap.campaign.controller;

import com.vnmap.campaign.dto.*;
import com.vnmap.campaign.service.CampaignService;
import com.vnmap.campaign.service.OsmGeocodingService;
import com.vnmap.common.model.ApiResponse;
import com.vnmap.common.model.PagedResponse;
import com.vnmap.common.security.CurrentUser;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@RestController
@Validated
@RequestMapping("/api/v1")
public class CampaignController {

    private final CampaignService campaignService;
    private final OsmGeocodingService osmGeocodingService;

    public CampaignController(
            CampaignService campaignService,
            OsmGeocodingService osmGeocodingService
    ) {
        this.campaignService = campaignService;
        this.osmGeocodingService = osmGeocodingService;
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

    @GetMapping("/schools/coordinates")
    public ResponseEntity<ApiResponse<List<SchoolCoordinatesDto>>> getSchoolCoordinates(
            @RequestParam(required = false) String provinceCode,
            @RequestParam(required = false) String communeCode
    ) {
        return ResponseEntity.ok(ApiResponse.success(
                campaignService.getSchoolCoordinates(provinceCode, communeCode),
                "School coordinates retrieved successfully"
        ));
    }

    @GetMapping("/schools/{schoolUid}/coordinates")
    public ResponseEntity<ApiResponse<SchoolCoordinatesDto>> getSchoolCoordinate(@PathVariable String schoolUid) {
        return ResponseEntity.ok(ApiResponse.success(
                campaignService.getSchoolCoordinate(schoolUid),
                "School coordinate retrieved successfully"
        ));
    }

    @PutMapping("/schools/{schoolUid}/coordinates")
    public ResponseEntity<ApiResponse<SchoolCoordinatesDto>> updateSchoolCoordinates(
            @PathVariable String schoolUid,
            @RequestBody SchoolCoordinatesUpdateRequest request
    ) {
        return ResponseEntity.ok(ApiResponse.success(
                campaignService.updateSchoolCoordinates(schoolUid, request.latitude(), request.longitude()),
                "School coordinates updated successfully"
        ));
    }

    @PostMapping("/schools/coordinates/compute")
    public ResponseEntity<ApiResponse<List<SchoolCoordinatesDto>>> computeApproximateCoordinates() {
        return ResponseEntity.ok(ApiResponse.success(
                campaignService.computeApproximateCoordinates(),
                "Approximate coordinates computed successfully"
        ));
    }

    @PostMapping("/schools/geocode")
    public ResponseEntity<ApiResponse<List<SchoolGeocodeDto>>> geocodeSchools(
            @RequestBody List<String> schoolUids
    ) {
        return ResponseEntity.ok(ApiResponse.success(
                osmGeocodingService.geocodeSchools(schoolUids),
                "Schools geocoded successfully"
        ));
    }

    @GetMapping("/employees")
    public ResponseEntity<ApiResponse<List<EmployeeDto>>> getEmployees() {
        return ResponseEntity.ok(ApiResponse.success(
                campaignService.getEmployees(),
                "Employees retrieved successfully"
        ));
    }

    @PostMapping("/employees")
    public ResponseEntity<ApiResponse<EmployeeDto>> createEmployee(@Valid @RequestBody EmployeeDto request) {
        return ResponseEntity.ok(ApiResponse.success(
                campaignService.createEmployee(request),
                "Employee created successfully"
        ));
    }

    @PutMapping("/employees/{id}")
    public ResponseEntity<ApiResponse<EmployeeDto>> updateEmployee(
            @PathVariable long id,
            @Valid @RequestBody EmployeeDto request
    ) {
        return ResponseEntity.ok(ApiResponse.success(
                campaignService.updateEmployee(id, request),
                "Employee updated successfully"
        ));
    }

    @DeleteMapping("/employees/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteEmployee(@PathVariable long id) {
        campaignService.deleteEmployee(id);
        return ResponseEntity.ok(ApiResponse.success(null, "Employee deleted successfully"));
    }

    @GetMapping("/campaigns")
    public ResponseEntity<ApiResponse<List<CampaignDto>>> getCampaigns(
            @RequestParam(defaultValue = "false") boolean includeArchived,
            @AuthenticationPrincipal CurrentUser currentUser
    ) {
        ensureCanIncludeArchived(includeArchived, currentUser);
        return ResponseEntity.ok(ApiResponse.success(
                campaignService.getCampaigns(includeArchived),
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

    @DeleteMapping("/campaigns/{id}")
    public ResponseEntity<ApiResponse<Void>> archiveCampaign(@PathVariable long id) {
        campaignService.archiveCampaign(id);
        return ResponseEntity.ok(ApiResponse.success(null, "Campaign archived successfully"));
    }

    @GetMapping("/campaigns/{id}/dashboard")
    public ResponseEntity<ApiResponse<CampaignDashboardDto>> getDashboard(@PathVariable long id) {
        return ResponseEntity.ok(ApiResponse.success(
                campaignService.getDashboard(id),
                "Campaign dashboard retrieved successfully"
        ));
    }

    @GetMapping("/campaigns/{id}/events")
    public ResponseEntity<ApiResponse<List<CampaignEventDto>>> getEvents(
            @PathVariable long id,
            @RequestParam(defaultValue = "false") boolean includeArchived,
            @AuthenticationPrincipal CurrentUser currentUser
    ) {
        ensureCanIncludeArchived(includeArchived, currentUser);
        return ResponseEntity.ok(ApiResponse.success(
                campaignService.getEvents(id, includeArchived),
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

    @DeleteMapping("/events/{eventId}")
    public ResponseEntity<ApiResponse<Void>> archiveEvent(@PathVariable long eventId) {
        campaignService.archiveEvent(eventId);
        return ResponseEntity.ok(ApiResponse.success(null, "Event archived successfully"));
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

    @GetMapping("/events/{eventId}/schools")
    public ResponseEntity<ApiResponse<List<SchoolDto>>> getEventSchools(@PathVariable long eventId) {
        return ResponseEntity.ok(ApiResponse.success(
                campaignService.getEventSchools(eventId),
                "Event schools retrieved successfully"
        ));
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

    @GetMapping("/events/{eventId}/assignments")
    public ResponseEntity<ApiResponse<List<EmployeeDto>>> getEventAssignments(@PathVariable long eventId) {
        return ResponseEntity.ok(ApiResponse.success(
                campaignService.getEventAssignments(eventId),
                "Event assignments retrieved successfully"
        ));
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

    @PutMapping("/events/{eventId}/interactions/{interactionId}")
    public ResponseEntity<ApiResponse<InteractionDto>> updateInteraction(
            @PathVariable long eventId,
            @PathVariable long interactionId,
            @Valid @RequestBody CreateInteractionRequest request,
            @AuthenticationPrincipal CurrentUser user
    ) {
        return ResponseEntity.ok(ApiResponse.success(
                campaignService.updateInteraction(eventId, interactionId, request, user),
                "Interaction updated successfully"
        ));
    }

    @DeleteMapping("/events/{eventId}/interactions/{interactionId}")
    public ResponseEntity<ApiResponse<Void>> deleteInteraction(
            @PathVariable long eventId,
            @PathVariable long interactionId,
            @AuthenticationPrincipal CurrentUser user
    ) {
        campaignService.deleteInteraction(eventId, interactionId, user);
        return ResponseEntity.ok(ApiResponse.success(null, "Interaction deleted successfully"));
    }

    @PostMapping("/campaigns/{campaignId}/student-registrations")
    public ResponseEntity<ApiResponse<StudentRegistrationDto>> registerStudent(
            @PathVariable long campaignId,
            @Valid @RequestBody StudentRegistrationRequest request
    ) {
        return ResponseEntity.ok(ApiResponse.success(
                campaignService.registerStudent(campaignId, request),
                "Student registration submitted successfully"
        ));
    }

    @GetMapping("/campaigns/{campaignId}/student-registrations")
    public ResponseEntity<ApiResponse<List<StudentRegistrationDto>>> getCampaignRegistrations(
            @PathVariable long campaignId
    ) {
        return ResponseEntity.ok(ApiResponse.success(
                campaignService.getCampaignRegistrations(campaignId),
                "Student registrations retrieved successfully"
        ));
    }

    @GetMapping("/student-registrations/my")
    public ResponseEntity<ApiResponse<List<StudentRegistrationDto>>> getMyRegistrations(
            @AuthenticationPrincipal CurrentUser user
    ) {
        return ResponseEntity.ok(ApiResponse.success(
                campaignService.getMyRegistrations(user),
                "My registrations retrieved successfully"
        ));
    }

    @PutMapping("/student-registrations/{id}/status")
    public ResponseEntity<ApiResponse<StudentRegistrationDto>> updateRegistrationStatus(
            @PathVariable long id,
            @Valid @RequestBody UpdateRegistrationStatusRequest request
    ) {
        return ResponseEntity.ok(ApiResponse.success(
                campaignService.updateRegistrationStatus(id, request.status()),
                "Student registration status updated successfully"
        ));
    }

    @GetMapping("/students")
    public ResponseEntity<ApiResponse<PagedResponse<StudentDto>>> getStudents(
            @RequestParam(defaultValue = "0") @Min(0) int page,
            @RequestParam(defaultValue = "50") @Min(1) @Max(200) int limit,
            @RequestParam(required = false) String schoolUid,
            @RequestParam(required = false) String q
    ) {
        return ResponseEntity.ok(ApiResponse.success(
                campaignService.getStudents(page, limit, schoolUid, q),
                "Students retrieved successfully"
        ));
    }

    @PostMapping("/students")
    public ResponseEntity<ApiResponse<StudentDto>> createStudent(@Valid @RequestBody StudentRequest request) {
        return ResponseEntity.ok(ApiResponse.success(
                campaignService.createStudent(request),
                "Student created successfully"
        ));
    }

    @PutMapping("/students/{id}")
    public ResponseEntity<ApiResponse<StudentDto>> updateStudent(
            @PathVariable long id,
            @Valid @RequestBody StudentRequest request
    ) {
        return ResponseEntity.ok(ApiResponse.success(
                campaignService.updateStudent(id, request),
                "Student updated successfully"
        ));
    }

    @DeleteMapping("/students/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteStudent(@PathVariable long id) {
        campaignService.deleteStudent(id);
        return ResponseEntity.ok(ApiResponse.success(null, "Student deleted successfully"));
    }

    @GetMapping("/persons")
    public ResponseEntity<ApiResponse<List<PersonDto>>> getPersons(@RequestParam(required = false) String schoolUid) {
        return ResponseEntity.ok(ApiResponse.success(campaignService.getPersons(schoolUid), "Persons retrieved successfully"));
    }

    @PostMapping("/persons")
    public ResponseEntity<ApiResponse<PersonDto>> createPerson(@Valid @RequestBody PersonRequest request) {
        return ResponseEntity.ok(ApiResponse.success(campaignService.createPerson(request), "Person created successfully"));
    }

    @PutMapping("/persons/{id}")
    public ResponseEntity<ApiResponse<PersonDto>> updatePerson(
            @PathVariable long id,
            @Valid @RequestBody PersonRequest request
    ) {
        return ResponseEntity.ok(ApiResponse.success(campaignService.updatePerson(id, request), "Person updated successfully"));
    }

    @DeleteMapping("/persons/{id}")
    public ResponseEntity<ApiResponse<Void>> deletePerson(@PathVariable long id) {
        campaignService.deletePerson(id);
        return ResponseEntity.ok(ApiResponse.success(null, "Person deleted successfully"));
    }

    @GetMapping("/student-relatives")
    public ResponseEntity<ApiResponse<List<StudentRelativeDto>>> getRelatives(
            @RequestParam(required = false) String schoolUid,
            @RequestParam(required = false) Long studentId
    ) {
        return ResponseEntity.ok(ApiResponse.success(
                campaignService.getRelatives(schoolUid, studentId),
                "Student relatives retrieved successfully"
        ));
    }

    @PostMapping("/student-relatives")
    public ResponseEntity<ApiResponse<StudentRelativeDto>> createRelative(@Valid @RequestBody StudentRelativeRequest request) {
        return ResponseEntity.ok(ApiResponse.success(
                campaignService.createRelative(request),
                "Student relative created successfully"
        ));
    }

    @PutMapping("/student-relatives/{id}")
    public ResponseEntity<ApiResponse<StudentRelativeDto>> updateRelative(
            @PathVariable long id,
            @Valid @RequestBody StudentRelativeRequest request
    ) {
        return ResponseEntity.ok(ApiResponse.success(
                campaignService.updateRelative(id, request),
                "Student relative updated successfully"
        ));
    }

    @DeleteMapping("/student-relatives/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteRelative(@PathVariable long id) {
        campaignService.deleteRelative(id);
        return ResponseEntity.ok(ApiResponse.success(null, "Student relative deleted successfully"));
    }

    @GetMapping("/users")
    public ResponseEntity<ApiResponse<List<UserDto>>> getUsers() {
        return ResponseEntity.ok(ApiResponse.success(campaignService.getUsers(), "Users retrieved successfully"));
    }

    @PostMapping("/users")
    public ResponseEntity<ApiResponse<UserDto>> createUser(@Valid @RequestBody UserRequest request) {
        return ResponseEntity.ok(ApiResponse.success(campaignService.createUser(request), "User created successfully"));
    }

    @PutMapping("/users/{id}")
    public ResponseEntity<ApiResponse<UserDto>> updateUser(
            @PathVariable long id,
            @Valid @RequestBody UserRequest request
    ) {
        return ResponseEntity.ok(ApiResponse.success(campaignService.updateUser(id, request), "User updated successfully"));
    }

    @DeleteMapping("/users/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteUser(@PathVariable long id) {
        campaignService.deleteUser(id);
        return ResponseEntity.ok(ApiResponse.success(null, "User deleted successfully"));
    }

    @PutMapping("/users/{id}/role")
    public ResponseEntity<ApiResponse<UserDto>> updateUserRole(
            @PathVariable long id,
            @Valid @RequestBody UpdateRoleRequest request
    ) {
        return ResponseEntity.ok(ApiResponse.success(campaignService.updateUserRole(id, request.role()), "User role updated successfully"));
    }

    @PutMapping("/users/{id}/status")
    public ResponseEntity<ApiResponse<UserDto>> updateUserStatus(
            @PathVariable long id,
            @Valid @RequestBody UpdateStatusRequest request
    ) {
        return ResponseEntity.ok(ApiResponse.success(campaignService.updateUserStatus(id, request.status()), "User status updated successfully"));
    }

    private void ensureCanIncludeArchived(boolean includeArchived, CurrentUser currentUser) {
        if (!includeArchived) {
            return;
        }
        if (currentUser == null || (!"MANAGER".equals(currentUser.role()) && !"ADMIN".equals(currentUser.role()))) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Only managers and admins can include archived data");
        }
    }
}
