package com.vnmap.attendance.controller;

import com.vnmap.attendance.dto.AttendanceDto;
import com.vnmap.attendance.dto.AttendanceTargetDto;
import com.vnmap.attendance.dto.CheckInRequest;
import com.vnmap.attendance.dto.CheckOutRequest;
import com.vnmap.attendance.dto.CreateAttendanceRequest;
import com.vnmap.attendance.dto.UpdateAttendanceRequest;
import com.vnmap.attendance.service.AttendanceService;
import com.vnmap.common.model.ApiResponse;
import com.vnmap.common.model.PagedResponse;
import com.vnmap.common.security.CurrentUser;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Size;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.util.List;

/**
 * Staff check-in / check-out (attendance), tied to an open campaign.
 *
 * Role gating (mirrored in SecurityConfig):
 *  - STAFF/MANAGER: check themselves in/out, view their own history.
 *  - MANAGER/ADMIN: list, manually create, correct, and delete any employee's records.
 */
@RestController
@Validated
@RequestMapping("/api/v1/attendance")
public class AttendanceController {

    private final AttendanceService attendanceService;

    public AttendanceController(AttendanceService attendanceService) {
        this.attendanceService = attendanceService;
    }

    @PostMapping("/check-in")
    public ResponseEntity<ApiResponse<AttendanceDto>> checkIn(
            @AuthenticationPrincipal CurrentUser currentUser,
            @RequestHeader(value = "Idempotency-Key", required = false) @Size(max = 100) String idempotencyKey,
            @Valid @RequestBody CheckInRequest request
    ) {
        long employeeId = requireEmployeeId(currentUser);
        return ResponseEntity.ok(ApiResponse.success(
                attendanceService.checkIn(employeeId, request, idempotencyKey), "Checked in successfully"
        ));
    }

    @PostMapping("/check-out")
    public ResponseEntity<ApiResponse<AttendanceDto>> checkOut(
            @AuthenticationPrincipal CurrentUser currentUser,
            @RequestHeader(value = "Idempotency-Key", required = false) @Size(max = 100) String idempotencyKey,
            @Valid @RequestBody(required = false) CheckOutRequest request
    ) {
        long employeeId = requireEmployeeId(currentUser);
        return ResponseEntity.ok(ApiResponse.success(
                attendanceService.checkOut(employeeId, request, idempotencyKey), "Checked out successfully"
        ));
    }

    @GetMapping("/eligible-targets")
    public ResponseEntity<ApiResponse<List<AttendanceTargetDto>>> eligibleTargets(
            @AuthenticationPrincipal CurrentUser currentUser
    ) {
        return ResponseEntity.ok(ApiResponse.success(
                attendanceService.eligibleTargets(requireEmployeeId(currentUser))
        ));
    }

    @GetMapping("/me")
    public ResponseEntity<ApiResponse<PagedResponse<AttendanceDto>>> myAttendance(
            @AuthenticationPrincipal CurrentUser currentUser,
            @RequestParam(defaultValue = "0") @Min(0) int page,
            @RequestParam(defaultValue = "20") @Min(1) @Max(100) int limit
    ) {
        long employeeId = requireEmployeeId(currentUser);
        return ResponseEntity.ok(ApiResponse.success(
                attendanceService.list(employeeId, null, null, null, page, limit)
        ));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<AttendanceDto>> createAttendance(
            @AuthenticationPrincipal CurrentUser currentUser,
            @Valid @RequestBody CreateAttendanceRequest request
    ) {
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.success(
                attendanceService.create(request, currentUser.id()), "Attendance record created successfully"
        ));
    }

    @GetMapping
    public ResponseEntity<ApiResponse<PagedResponse<AttendanceDto>>> listAttendance(
            @RequestParam(required = false) Long employeeId,
            @RequestParam(required = false) Long campaignId,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant to,
            @RequestParam(defaultValue = "0") @Min(0) int page,
            @RequestParam(defaultValue = "20") @Min(1) @Max(200) int limit
    ) {
        return ResponseEntity.ok(ApiResponse.success(
                attendanceService.list(employeeId, campaignId, status, from, to, page, limit)
        ));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<AttendanceDto>> getAttendance(@PathVariable long id) {
        return ResponseEntity.ok(ApiResponse.success(attendanceService.getById(id)));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<AttendanceDto>> updateAttendance(
            @AuthenticationPrincipal CurrentUser currentUser,
            @PathVariable long id,
            @Valid @RequestBody UpdateAttendanceRequest request
    ) {
        return ResponseEntity.ok(ApiResponse.success(
                attendanceService.update(id, request, currentUser.id()), "Attendance record updated successfully"
        ));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteAttendance(
            @AuthenticationPrincipal CurrentUser currentUser,
            @PathVariable long id,
            @RequestParam @NotBlank @Size(max = 500) String reason
    ) {
        attendanceService.delete(id, currentUser.id(), reason);
        return ResponseEntity.ok(ApiResponse.success(null, "Attendance record deleted successfully"));
    }

    private long requireEmployeeId(CurrentUser currentUser) {
        if (currentUser == null || currentUser.employeeId() == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Current user is not linked to an employee record");
        }
        return currentUser.employeeId();
    }
}
