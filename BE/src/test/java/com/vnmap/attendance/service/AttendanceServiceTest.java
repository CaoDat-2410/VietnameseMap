package com.vnmap.attendance.service;

import com.vnmap.attendance.dto.AttendanceDto;
import com.vnmap.attendance.dto.CheckInRequest;
import com.vnmap.attendance.dto.CheckOutRequest;
import com.vnmap.attendance.dto.CreateAttendanceRequest;
import com.vnmap.attendance.dto.UpdateAttendanceRequest;
import com.vnmap.common.exception.ResourceNotFoundException;
import com.vnmap.common.model.PagedResponse;
import com.vnmap.notification.service.NotificationTriggerService;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.PreparedStatementCreator;
import org.springframework.jdbc.core.ResultSetExtractor;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.jdbc.support.KeyHolder;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

class AttendanceServiceTest {

    private final JdbcTemplate jdbc = mock(JdbcTemplate.class);
    private final NotificationTriggerService notificationTriggerService = mock(NotificationTriggerService.class);
    private final AttendanceService service = new AttendanceService(jdbc, notificationTriggerService);

    private static final AttendanceDto SAMPLE = new AttendanceDto(
            10L, 5L, "Nguyen Van A",
            1L, "Spring Drive", null, null,
            Instant.parse("2026-07-18T01:00:00Z"), null,
            "in note", null,
            10.0, 20.0, null, null,
            "OPEN", null
    );

    private void stubActiveCampaign(long campaignId, String name) {
        when(jdbc.queryForList(anyString(), eq(campaignId)))
                .thenReturn(List.of(new HashMap<>(Map.of("name", name, "status", "ACTIVE"))));
        when(jdbc.queryForObject(contains("event_assignments"), eq(Integer.class), any(Object[].class)))
                .thenReturn(1);
    }

    @Test
    void checkInInsertsRowAndReturnsCreatedRecordWhenNoOpenSession() {
        when(jdbc.queryForObject(anyString(), eq(Integer.class), eq(5L))).thenReturn(1);
        when(jdbc.query(anyString(), any(ResultSetExtractor.class), eq(5L))).thenReturn(null);
        stubActiveCampaign(1L, "Spring Drive");
        doAnswer(invocation -> {
            KeyHolder keyHolder = invocation.getArgument(1);
            keyHolder.getKeyList().add(new HashMap<>(Map.of("id", 10L)));
            return 1;
        }).when(jdbc).update(any(PreparedStatementCreator.class), any(KeyHolder.class));
        when(jdbc.query(anyString(), any(RowMapper.class), eq(10L))).thenReturn(List.of(SAMPLE));

        AttendanceDto result = service.checkIn(5L, new CheckInRequest(1L, null, "in note", 10.0, 20.0));

        assertThat(result).isEqualTo(SAMPLE);
        verify(jdbc).update(any(PreparedStatementCreator.class), any(KeyHolder.class));
        verify(notificationTriggerService).staffCheckedIn(5L, 1L, "Spring Drive");
    }

    @Test
    void checkInThrowsWhenEmployeeDoesNotExist() {
        when(jdbc.queryForObject(anyString(), eq(Integer.class), eq(99L))).thenReturn(0);

        assertThatThrownBy(() -> service.checkIn(99L, new CheckInRequest(1L, null, null, null, null)))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    @Test
    void checkInThrowsConflictWhenEmployeeAlreadyHasOpenSession() {
        when(jdbc.queryForObject(anyString(), eq(Integer.class), eq(5L))).thenReturn(1);
        stubActiveCampaign(1L, "Spring Drive");
        when(jdbc.update(any(PreparedStatementCreator.class), any(KeyHolder.class)))
                .thenReturn(0);

        assertThatThrownBy(() -> service.checkIn(5L, new CheckInRequest(1L, null, null, null, null)))
                .isInstanceOf(ResponseStatusException.class)
                .satisfies(ex -> assertThat(((ResponseStatusException) ex).getStatusCode()).isEqualTo(HttpStatus.CONFLICT));

        verify(jdbc).update(any(PreparedStatementCreator.class), any(KeyHolder.class));
    }

    @Test
    void checkInThrowsWhenCampaignIsNotActive() {
        when(jdbc.queryForObject(anyString(), eq(Integer.class), eq(5L))).thenReturn(1);
        when(jdbc.query(anyString(), any(ResultSetExtractor.class), eq(5L))).thenReturn(null);
        when(jdbc.queryForList(anyString(), eq(1L)))
                .thenReturn(List.of(new HashMap<>(Map.of("name", "Old Drive", "status", "DRAFT"))));

        assertThatThrownBy(() -> service.checkIn(5L, new CheckInRequest(1L, null, null, null, null)))
                .isInstanceOf(ResponseStatusException.class)
                .satisfies(ex -> assertThat(((ResponseStatusException) ex).getStatusCode()).isEqualTo(HttpStatus.CONFLICT));

        verify(jdbc, never()).update(any(PreparedStatementCreator.class), any(KeyHolder.class));
        verifyNoInteractions(notificationTriggerService);
    }

    @Test
    void checkInThrowsWhenCampaignDoesNotExist() {
        when(jdbc.queryForObject(anyString(), eq(Integer.class), eq(5L))).thenReturn(1);
        when(jdbc.query(anyString(), any(ResultSetExtractor.class), eq(5L))).thenReturn(null);
        when(jdbc.queryForList(anyString(), eq(404L))).thenReturn(List.of());

        assertThatThrownBy(() -> service.checkIn(5L, new CheckInRequest(404L, null, null, null, null)))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    @Test
    void checkOutClosesTheOpenSessionForTheEmployee() {
        AttendanceDto closed = new AttendanceDto(
                11L, 5L, "Nguyen Van A",
                1L, "Spring Drive", null, null,
                Instant.parse("2026-07-18T01:00:00Z"), Instant.parse("2026-07-18T10:00:00Z"),
                "in note", "out note",
                10.0, 20.0, 11.0, 21.0,
                "CLOSED", 540L
        );
        when(jdbc.queryForObject(anyString(), eq(Integer.class), eq(5L))).thenReturn(1);
        when(jdbc.update(any(PreparedStatementCreator.class))).thenReturn(1);
        when(jdbc.query(anyString(), any(ResultSetExtractor.class), eq(5L))).thenReturn(11L);
        when(jdbc.query(anyString(), any(RowMapper.class), eq(11L))).thenReturn(List.of(closed));

        AttendanceDto result = service.checkOut(5L, new CheckOutRequest("out note", 11.0, 21.0));

        assertThat(result.status()).isEqualTo("CLOSED");
        assertThat(result.workedMinutes()).isEqualTo(540L);
        verify(jdbc).update(any(PreparedStatementCreator.class));
        verify(notificationTriggerService).staffCheckedOut(5L, 1L, "Spring Drive");
    }

    @Test
    void checkOutThrowsConflictWhenNoOpenSessionExists() {
        when(jdbc.queryForObject(anyString(), eq(Integer.class), eq(5L))).thenReturn(1);
        when(jdbc.query(anyString(), any(ResultSetExtractor.class), eq(5L))).thenReturn(null);

        assertThatThrownBy(() -> service.checkOut(5L, null))
                .isInstanceOf(ResponseStatusException.class)
                .satisfies(ex -> assertThat(((ResponseStatusException) ex).getStatusCode()).isEqualTo(HttpStatus.CONFLICT));
    }

    @Test
    void createInsertsManualClosedRecordForEmployee() {
        when(jdbc.queryForObject(anyString(), eq(Integer.class), eq(5L))).thenReturn(1);
        when(jdbc.queryForObject(anyString(), eq(Integer.class), eq(1L))).thenReturn(1);
        doAnswer(invocation -> {
            KeyHolder keyHolder = invocation.getArgument(1);
            keyHolder.getKeyList().add(new HashMap<>(Map.of("id", 10L)));
            return 1;
        }).when(jdbc).update(any(PreparedStatementCreator.class), any(KeyHolder.class));
        when(jdbc.query(anyString(), any(RowMapper.class), eq(10L))).thenReturn(List.of(SAMPLE));

        CreateAttendanceRequest request = new CreateAttendanceRequest(
                5L, 1L, null,
                Instant.parse("2026-07-18T01:00:00Z"), Instant.parse("2026-07-18T10:00:00Z"),
                "manual in", "manual out", "Forgotten check-in"
        );

        AttendanceDto result = service.create(request);

        assertThat(result).isEqualTo(SAMPLE);
        verify(jdbc).update(any(PreparedStatementCreator.class), any(KeyHolder.class));
        verifyNoInteractions(notificationTriggerService);
    }

    @Test
    void createRejectsCheckOutBeforeCheckIn() {
        when(jdbc.queryForObject(anyString(), eq(Integer.class), eq(5L))).thenReturn(1);
        when(jdbc.queryForObject(anyString(), eq(Integer.class), eq(1L))).thenReturn(1);

        CreateAttendanceRequest request = new CreateAttendanceRequest(
                5L, 1L, null,
                Instant.parse("2026-07-18T10:00:00Z"), Instant.parse("2026-07-18T01:00:00Z"),
                null, null, "Invalid correction"
        );

        assertThatThrownBy(() -> service.create(request))
                .isInstanceOf(ResponseStatusException.class)
                .satisfies(ex -> assertThat(((ResponseStatusException) ex).getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST));
    }

    @Test
    void listAppliesFiltersAndReturnsPagedResponse() {
        when(jdbc.queryForObject(anyString(), eq(Long.class), any(Object[].class))).thenReturn(1L);
        when(jdbc.query(anyString(), any(RowMapper.class), any(Object[].class))).thenReturn(List.of(SAMPLE));

        PagedResponse<AttendanceDto> page = service.list(
                5L, "OPEN",
                Instant.parse("2026-07-01T00:00:00Z"),
                Instant.parse("2026-07-31T23:59:00Z"),
                0, 20
        );

        assertThat(page.items()).containsExactly(SAMPLE);
        assertThat(page.totalItems()).isEqualTo(1L);
        assertThat(page.page()).isZero();
        assertThat(page.limit()).isEqualTo(20);
    }

    @Test
    void getByIdThrowsWhenRecordMissing() {
        when(jdbc.query(anyString(), any(RowMapper.class), eq(404L))).thenReturn(List.of());

        assertThatThrownBy(() -> service.getById(404L))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    @Test
    void updateRejectsCheckOutBeforeCheckIn() {
        when(jdbc.query(anyString(), any(RowMapper.class), eq(10L))).thenReturn(List.of(SAMPLE));

        UpdateAttendanceRequest badRequest = new UpdateAttendanceRequest(
                null, null, false,
                Instant.parse("2026-07-18T01:00:00Z"),
                Instant.parse("2026-07-18T00:00:00Z"),
                false, null, false, null, false,
                "Invalid time correction"
        );

        assertThatThrownBy(() -> service.update(10L, badRequest))
                .isInstanceOf(ResponseStatusException.class)
                .satisfies(ex -> assertThat(((ResponseStatusException) ex).getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST));
    }

    @Test
    void updateAppliesManagerCorrectionAndCloses() {
        when(jdbc.query(anyString(), any(RowMapper.class), eq(10L))).thenReturn(List.of(SAMPLE));
        when(jdbc.update(contains("UPDATE staff_attendance"), any(Object[].class))).thenReturn(1);

        UpdateAttendanceRequest request = new UpdateAttendanceRequest(
                null, null, false, null, Instant.parse("2026-07-18T10:00:00Z"),
                false, null, false, "corrected by manager", false, "Manager correction"
        );

        service.update(10L, request);

        verify(jdbc).update(contains("UPDATE staff_attendance"), any(Object[].class));
    }

    @Test
    void updateThrowsWhenRecordMissing() {
        when(jdbc.query(anyString(), any(RowMapper.class), eq(10L))).thenReturn(List.of(SAMPLE));
        when(jdbc.update(contains("UPDATE staff_attendance"), any(Object[].class))).thenReturn(0);

        assertThatThrownBy(() -> service.update(10L, new UpdateAttendanceRequest(
                null, null, false, null, null, false,
                "x", false, null, false, "Manager correction")))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    @Test
    void deleteSoftDeletesRecord() {
        when(jdbc.query(anyString(), any(RowMapper.class), eq(10L))).thenReturn(List.of(SAMPLE));
        when(jdbc.update(contains("UPDATE staff_attendance"), any(Object[].class))).thenReturn(1);

        service.delete(10L);

        verify(jdbc).update(contains("UPDATE staff_attendance"), any(Object[].class));
    }

    @Test
    void deleteThrowsWhenRecordMissing() {
        when(jdbc.update("DELETE FROM staff_attendance WHERE id = ?", 404L)).thenReturn(0);

        assertThatThrownBy(() -> service.delete(404L))
                .isInstanceOf(ResourceNotFoundException.class);
    }
}
