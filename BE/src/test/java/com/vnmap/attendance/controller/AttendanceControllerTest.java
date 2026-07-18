package com.vnmap.attendance.controller;

import com.vnmap.attendance.dto.AttendanceDto;
import com.vnmap.attendance.dto.CheckInRequest;
import com.vnmap.attendance.dto.CheckOutRequest;
import com.vnmap.attendance.dto.UpdateAttendanceRequest;
import com.vnmap.attendance.service.AttendanceService;
import com.vnmap.common.model.PagedResponse;
import com.vnmap.common.security.CurrentUser;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDateTime;

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
            LocalDateTime.of(2026, 7, 18, 8, 0), null,
            "in", null, null, null, null, null, "OPEN", null
    );

    @Test
    void checkInDelegatesUsingCallerEmployeeId() {
        CheckInRequest request = new CheckInRequest("in", null, null);
        when(service.checkIn(5L, request)).thenReturn(SAMPLE);

        assertThat(controller.checkIn(staff, request).getBody().getData()).isEqualTo(SAMPLE);
        verify(service).checkIn(5L, request);
    }

    @Test
    void checkInRejectsUserWithoutLinkedEmployee() {
        assertThatThrownBy(() -> controller.checkIn(staffWithoutEmployee, null))
                .isInstanceOf(ResponseStatusException.class)
                .satisfies(ex -> assertThat(((ResponseStatusException) ex).getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST));

        verifyNoInteractions(service);
    }

    @Test
    void checkOutDelegatesUsingCallerEmployeeId() {
        CheckOutRequest request = new CheckOutRequest("out", null, null);
        when(service.checkOut(6L, request)).thenReturn(SAMPLE);

        assertThat(controller.checkOut(manager, request).getBody().getData()).isEqualTo(SAMPLE);
        verify(service).checkOut(6L, request);
    }

    @Test
    void myAttendanceListsForCallerEmployeeId() {
        PagedResponse<AttendanceDto> page = PagedResponse.of(java.util.List.of(SAMPLE), 0, 20, 1);
        when(service.list(5L, null, null, null, 0, 20)).thenReturn(page);

        assertThat(controller.myAttendance(staff, 0, 20).getBody().getData()).isEqualTo(page);
    }

    @Test
    void listAttendanceDelegatesAllFilters() {
        LocalDateTime from = LocalDateTime.of(2026, 7, 1, 0, 0);
        LocalDateTime to = LocalDateTime.of(2026, 7, 31, 23, 59);
        PagedResponse<AttendanceDto> page = PagedResponse.of(java.util.List.of(SAMPLE), 0, 20, 1);
        when(service.list(5L, "OPEN", from, to, 0, 20)).thenReturn(page);

        assertThat(controller.listAttendance(5L, "OPEN", from, to, 0, 20).getBody().getData()).isEqualTo(page);
    }

    @Test
    void getAttendanceDelegatesToService() {
        when(service.getById(10L)).thenReturn(SAMPLE);

        assertThat(controller.getAttendance(10L).getBody().getData()).isEqualTo(SAMPLE);
    }

    @Test
    void updateAttendanceDelegatesManagerCorrection() {
        UpdateAttendanceRequest request = new UpdateAttendanceRequest(null, LocalDateTime.now(), null, "fixed");
        when(service.update(10L, request)).thenReturn(SAMPLE);

        assertThat(controller.updateAttendance(10L, request).getBody().getMessage())
                .isEqualTo("Attendance record updated successfully");
        verify(service).update(10L, request);
    }

    @Test
    void deleteAttendanceDelegatesToService() {
        assertThat(controller.deleteAttendance(10L).getBody().getMessage())
                .isEqualTo("Attendance record deleted successfully");
        verify(service).delete(10L);
    }
}
