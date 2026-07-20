package com.vnmap.attendance.controller;

import com.vnmap.attendance.dto.AttendanceDto;
import com.vnmap.attendance.dto.CheckInRequest;
import com.vnmap.attendance.dto.CheckOutRequest;
import com.vnmap.attendance.dto.CreateAttendanceRequest;
import com.vnmap.attendance.dto.UpdateAttendanceRequest;
import com.vnmap.attendance.service.AttendanceService;
import com.vnmap.common.model.PagedResponse;
import com.vnmap.common.security.CurrentUser;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

class AttendanceControllerTest {

    private final AttendanceService service = mock(AttendanceService.class);
    private final AttendanceController controller = new AttendanceController(service);

    private final CurrentUser staff = new CurrentUser(1L, "staff@test", "STAFF", "ACTIVE", 5L, null);
    private final CurrentUser manager = new CurrentUser(2L, "manager@test", "MANAGER", "ACTIVE", 6L, null);
    private final CurrentUser staffWithoutEmployee = new CurrentUser(3L, "orphan@test", "STAFF", "ACTIVE", null, null);

    private static final AttendanceDto SAMPLE = new AttendanceDto(
            10L, 5L, "Nguyen Van A",
            1L, "Spring Drive", null, null,
            Instant.parse("2026-07-18T01:00:00Z"), null,
            "in", null, null, null, null, null, "OPEN", null
    );

    @Test
    void checkInDelegatesUsingCallerEmployeeId() {
        CheckInRequest request = new CheckInRequest(1L, null, "in", null, null);
        when(service.checkIn(5L, request, "check-in-1")).thenReturn(SAMPLE);

        assertThat(controller.checkIn(staff, "check-in-1", request).getBody().getData()).isEqualTo(SAMPLE);
        verify(service).checkIn(5L, request, "check-in-1");
    }

    @Test
    void checkInRejectsUserWithoutLinkedEmployee() {
        CheckInRequest request = new CheckInRequest(1L, null, null, null, null);

        assertThatThrownBy(() -> controller.checkIn(staffWithoutEmployee, null, request))
                .isInstanceOf(ResponseStatusException.class)
                .satisfies(ex -> assertThat(((ResponseStatusException) ex).getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST));

        verifyNoInteractions(service);
    }

    @Test
    void checkOutDelegatesUsingCallerEmployeeId() {
        CheckOutRequest request = new CheckOutRequest("out", null, null);
        when(service.checkOut(6L, request, "check-out-1")).thenReturn(SAMPLE);

        assertThat(controller.checkOut(manager, "check-out-1", request).getBody().getData()).isEqualTo(SAMPLE);
        verify(service).checkOut(6L, request, "check-out-1");
    }

    @Test
    void createAttendanceDelegatesManualEntry() {
        CreateAttendanceRequest request = new CreateAttendanceRequest(
                5L, 1L, null, Instant.parse("2026-07-18T01:00:00Z"), null, "manual", null, "Forgotten check-in"
        );
        when(service.create(request, manager.id())).thenReturn(SAMPLE);

        assertThat(controller.createAttendance(manager, request).getBody().getData()).isEqualTo(SAMPLE);
        verify(service).create(request, manager.id());
    }

    @Test
    void myAttendanceListsForCallerEmployeeId() {
        PagedResponse<AttendanceDto> page = PagedResponse.of(java.util.List.of(SAMPLE), 0, 20, 1);
        when(service.list(5L, null, null, null, 0, 20)).thenReturn(page);

        assertThat(controller.myAttendance(staff, 0, 20).getBody().getData()).isEqualTo(page);
    }

    @Test
    void listAttendanceDelegatesAllFilters() {
        Instant from = Instant.parse("2026-07-01T00:00:00Z");
        Instant to = Instant.parse("2026-07-31T23:59:00Z");
        PagedResponse<AttendanceDto> page = PagedResponse.of(java.util.List.of(SAMPLE), 0, 20, 1);
        when(service.list(5L, 1L, "OPEN", from, to, 0, 20)).thenReturn(page);

        assertThat(controller.listAttendance(5L, 1L, "OPEN", from, to, 0, 20).getBody().getData()).isEqualTo(page);
    }

    @Test
    void getAttendanceDelegatesToService() {
        when(service.getById(10L)).thenReturn(SAMPLE);

        assertThat(controller.getAttendance(10L).getBody().getData()).isEqualTo(SAMPLE);
    }

    @Test
    void updateAttendanceDelegatesManagerCorrection() {
        UpdateAttendanceRequest request = new UpdateAttendanceRequest(
                null, null, false, null, Instant.now(), false,
                null, false, "fixed", false, "Manager correction");
        when(service.update(10L, request, manager.id())).thenReturn(SAMPLE);

        assertThat(controller.updateAttendance(manager, 10L, request).getBody().getMessage())
                .isEqualTo("Attendance record updated successfully");
        verify(service).update(10L, request, manager.id());
    }

    @Test
    void deleteAttendanceDelegatesToService() {
        assertThat(controller.deleteAttendance(manager, 10L, "Duplicate record").getBody().getMessage())
                .isEqualTo("Attendance record deleted successfully");
        verify(service).delete(10L, manager.id(), "Duplicate record");
    }
}
