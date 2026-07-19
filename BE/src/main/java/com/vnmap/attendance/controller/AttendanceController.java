package com.vnmap.attendance.controller;

import com.vnmap.attendance.dto.AttendanceDto;
import com.vnmap.attendance.dto.CheckInRequest;
import com.vnmap.attendance.dto.CheckOutRequest;
import com.vnmap.attendance.dto.CreateAttendanceRequest;
import com.vnmap.attendance.dto.UpdateAttendanceRequest;
import com.vnmap.attendance.service.AttendanceService;
import com.vnmap.common.model.ApiResponse;
import com.vnmap.common.model.PagedResponse;
import com.vnmap.common.security.CurrentUser;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDateTime;

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
            @Valid @RequestBody CheckInRequest request
    ) {
        long employeeId = requireEmployeeId(currentUser);
        return ResponseEntity.ok(ApiResponse.success(
                attendanceService.checkIn(employeeId, request), "Checked in successfully"
        ));
    }

    @PostMapping("/check-out")
    public ResponseEntity<ApiResponse<AttendanceDto>> checkOut(
            @AuthenticationPrincipal CurrentUser currentUser,
            @Valid @RequestBody(required = false) CheckOutRequest request
    ) {
        long employeeId = requireEmployeeId(currentUser);
        return ResponseEntity.ok(ApiResponse.success(
                attendanceService.checkOut(employeeId, request), "Checked out successfully"
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
            @Valid @RequestBody CreateAttendanceRequest request
    ) {
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.success(
                attendanceService.create(request), "Attendance record created successfully"
        ));
    }

    @GetMapping
    public ResponseEntity<ApiResponse<PagedResponse<AttendanceDto>>> listAttendance(
            @RequestParam(required = false) Long employeeId,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime to,
            @RequestParam(defaultValue = "0") @Min(0) int page,
            @RequestParam(defaultValue = "20") @Min(1) @Max(200) int limit
    ) {
        return ResponseEntity.ok(ApiResponse.success(
                attendanceService.list(employeeId, status, from, to, page, limit)
        ));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<AttendanceDto>> getAttendance(@PathVariable long id) {
        return ResponseEntity.ok(ApiResponse.success(attendanceService.getById(id)));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<AttendanceDto>> updateAttendance(
            @PathVariable long id,
            @Valid @RequestBody UpdateAttendanceRequest request
    ) {
        return ResponseEntity.ok(ApiResponse.success(
                attendanceService.update(id, request), "Attendance record updated successfully"
        ));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteAttendance(@PathVariable long id) {
        attendanceService.delete(id);
        return ResponseEntity.ok(ApiResponse.success(null, "Attendance record deleted successfully"));
    }

    private long requireEmployeeId(CurrentUser currentUser) {
        if (currentUser == null || currentUser.employeeId() == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Current user is not linked to an employee record");
        }
        return currentUser.employeeId();
    }
}
