package com.vnmap.attendance.service;

import com.vnmap.attendance.dto.AttendanceDto;
import com.vnmap.attendance.dto.CheckInRequest;
import com.vnmap.attendance.dto.CheckOutRequest;
import com.vnmap.attendance.dto.CreateAttendanceRequest;
import com.vnmap.attendance.dto.UpdateAttendanceRequest;
import com.vnmap.common.exception.ResourceNotFoundException;
import com.vnmap.common.model.PagedResponse;
import com.vnmap.notification.service.NotificationTriggerService;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.jdbc.support.KeyHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.sql.PreparedStatement;
import java.sql.Statement;
import java.sql.Timestamp;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * Staff check-in / check-out (attendance) tracking, tied to an open campaign
 * (and optionally a specific campaign event).
 *
 * Self-service: STAFF/MANAGER check themselves in and out (one open session
 * at a time per employee, enforced by a partial unique index). Check-in
 * requires the target campaign to be ACTIVE; MANAGER/ADMIN are notified.
 *
 * Oversight: MANAGER and ADMIN can both list, manually create, correct, and
 * delete any employee's records (role gating lives in SecurityConfig).
 */
@Service
public class AttendanceService {

    private static final String ACTIVE_CAMPAIGN_STATUS = "ACTIVE";
    private static final RowMapper<AttendanceDto> ROW_MAPPER = AttendanceService::mapRow;

    private final JdbcTemplate jdbc;
    private final NotificationTriggerService notificationTriggerService;

    public AttendanceService(JdbcTemplate jdbc, NotificationTriggerService notificationTriggerService) {
        this.jdbc = jdbc;
        this.notificationTriggerService = notificationTriggerService;
    }

    @Transactional
    public AttendanceDto checkIn(long employeeId, CheckInRequest request) {
        ensureEmployee(employeeId);
        ensureNoOpenSession(employeeId);
        String campaignName = ensureCampaignOpenForCheckIn(request.campaignId());
        if (request.eventId() != null) {
            ensureEventBelongsToCampaign(request.eventId(), request.campaignId());
        }

        KeyHolder keyHolder = new GeneratedKeyHolder();
        jdbc.update(connection -> {
            PreparedStatement ps = connection.prepareStatement("""
                    INSERT INTO staff_attendance
                        (employee_id, campaign_id, event_id, check_in_at, check_in_note, check_in_lat, check_in_lng, status)
                    VALUES (?, ?, ?, CURRENT_TIMESTAMP, ?, ?, ?, 'OPEN')
                    """, new String[]{"id"});
            ps.setLong(1, employeeId);
            ps.setLong(2, request.campaignId());
            setNullableLong(ps, 3, request.eventId());
            ps.setString(4, request.note());
            setNullableDouble(ps, 5, request.lat());
            setNullableDouble(ps, 6, request.lng());
            return ps;
        }, keyHolder);

        AttendanceDto created = getById(generatedId(keyHolder));
        notificationTriggerService.staffCheckedIn(employeeId, request.campaignId(), campaignName);
        return created;
    }

    @Transactional
    public AttendanceDto checkOut(long employeeId, CheckOutRequest request) {
        ensureEmployee(employeeId);
        Long openId = jdbc.query(
                "SELECT id FROM staff_attendance WHERE employee_id = ? AND status = 'OPEN'",
                rs -> rs.next() ? rs.getLong("id") : null,
                employeeId
        );
        if (openId == null) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "No open check-in session found for this employee");
        }

        jdbc.update(connection -> {
            PreparedStatement ps = connection.prepareStatement("""
                    UPDATE staff_attendance
                    SET check_out_at = CURRENT_TIMESTAMP,
                        check_out_note = ?,
                        check_out_lat = ?,
                        check_out_lng = ?,
                        status = 'CLOSED',
                        updated_at = CURRENT_TIMESTAMP
                    WHERE id = ?
                    """);
            ps.setString(1, request == null ? null : request.note());
            setNullableDouble(ps, 2, request == null ? null : request.lat());
            setNullableDouble(ps, 3, request == null ? null : request.lng());
            ps.setLong(4, openId);
            return ps;
        });

        AttendanceDto closed = getById(openId);
        if (closed.campaignId() != null) {
            notificationTriggerService.staffCheckedOut(employeeId, closed.campaignId(), closed.campaignName());
        }
        return closed;
    }

    @Transactional
    public AttendanceDto create(CreateAttendanceRequest request) {
        ensureEmployee(request.employeeId());
        ensureCampaignExists(request.campaignId());
        if (request.eventId() != null) {
            ensureEventBelongsToCampaign(request.eventId(), request.campaignId());
        }
        LocalDateTime checkInAt = request.checkInAt() != null ? request.checkInAt() : LocalDateTime.now();
        LocalDateTime checkOutAt = request.checkOutAt();
        if (checkOutAt != null && checkOutAt.isBefore(checkInAt)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "checkOutAt must not be before checkInAt");
        }
        if (checkOutAt == null) {
            ensureNoOpenSession(request.employeeId());
        }
        String status = checkOutAt != null ? "CLOSED" : "OPEN";

        KeyHolder keyHolder = new GeneratedKeyHolder();
        jdbc.update(connection -> {
            PreparedStatement ps = connection.prepareStatement("""
                    INSERT INTO staff_attendance
                        (employee_id, campaign_id, event_id, check_in_at, check_out_at, check_in_note, check_out_note, status)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                    """, new String[]{"id"});
            ps.setLong(1, request.employeeId());
            ps.setLong(2, request.campaignId());
            setNullableLong(ps, 3, request.eventId());
            ps.setTimestamp(4, Timestamp.valueOf(checkInAt));
            if (checkOutAt == null) {
                ps.setNull(5, java.sql.Types.TIMESTAMP);
            } else {
                ps.setTimestamp(5, Timestamp.valueOf(checkOutAt));
            }
            ps.setString(6, request.checkInNote());
            ps.setString(7, request.checkOutNote());
            ps.setString(8, status);
            return ps;
        }, keyHolder);

        return getById(generatedId(keyHolder));
    }

    public PagedResponse<AttendanceDto> list(
            Long employeeId, String status, LocalDateTime from, LocalDateTime to, int page, int limit
    ) {
        List<Object> params = new ArrayList<>();
        StringBuilder where = new StringBuilder(" WHERE 1=1");
        if (employeeId != null) {
            where.append(" AND a.employee_id = ?");
            params.add(employeeId);
        }
        if (status != null && !status.isBlank()) {
            where.append(" AND a.status = ?");
            params.add(status.toUpperCase());
        }
        if (from != null) {
            where.append(" AND a.check_in_at >= ?");
            params.add(Timestamp.valueOf(from));
        }
        if (to != null) {
            where.append(" AND a.check_in_at <= ?");
            params.add(Timestamp.valueOf(to));
        }

        Long total = jdbc.queryForObject(
                "SELECT COUNT(*) FROM staff_attendance a" + where,
                Long.class, params.toArray()
        );

        List<Object> pageParams = new ArrayList<>(params);
        pageParams.add(limit);
        pageParams.add(page * limit);
        List<AttendanceDto> items = jdbc.query("""
                SELECT a.*, e.full_name AS employee_name, c.name AS campaign_name, ev.name AS event_name
                FROM staff_attendance a
                JOIN employees e ON e.id = a.employee_id
                LEFT JOIN campaigns c ON c.id = a.campaign_id
                LEFT JOIN campaign_events ev ON ev.id = a.event_id
                """ + where + """
                 ORDER BY a.check_in_at DESC
                 LIMIT ? OFFSET ?
                """, ROW_MAPPER, pageParams.toArray());

        return PagedResponse.of(items, page, limit, total == null ? 0 : total);
    }

    public AttendanceDto getById(long id) {
        return jdbc.query("""
                SELECT a.*, e.full_name AS employee_name, c.name AS campaign_name, ev.name AS event_name
                FROM staff_attendance a
                JOIN employees e ON e.id = a.employee_id
                LEFT JOIN campaigns c ON c.id = a.campaign_id
                LEFT JOIN campaign_events ev ON ev.id = a.event_id
                WHERE a.id = ?
                """, ROW_MAPPER, id
        ).stream().findFirst().orElseThrow(() -> new ResourceNotFoundException("Attendance", "id", id));
    }

    @Transactional
    public AttendanceDto update(long id, UpdateAttendanceRequest request) {
        AttendanceDto current = getById(id);

        Long campaignId = request.campaignId() != null ? request.campaignId() : current.campaignId();
        Long eventId = request.eventId() != null ? request.eventId() : current.eventId();
        if (request.campaignId() != null) {
            ensureCampaignExists(campaignId);
        }
        if (eventId != null) {
            ensureEventBelongsToCampaign(eventId, campaignId);
        }

        LocalDateTime checkInAt = request.checkInAt() != null ? request.checkInAt() : current.checkInAt();
        LocalDateTime checkOutAt = request.checkOutAt() != null ? request.checkOutAt() : current.checkOutAt();
        if (checkOutAt != null && checkOutAt.isBefore(checkInAt)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "checkOutAt must not be before checkInAt");
        }
        String status = checkOutAt != null ? "CLOSED" : "OPEN";

        int updated = jdbc.update("""
                UPDATE staff_attendance
                SET campaign_id = ?,
                    event_id = ?,
                    check_in_at = ?,
                    check_out_at = ?,
                    check_in_note = ?,
                    check_out_note = ?,
                    status = ?,
                    updated_at = CURRENT_TIMESTAMP
                WHERE id = ?
                """,
                campaignId,
                eventId,
                Timestamp.valueOf(checkInAt),
                checkOutAt == null ? null : Timestamp.valueOf(checkOutAt),
                request.checkInNote() != null ? request.checkInNote() : current.checkInNote(),
                request.checkOutNote() != null ? request.checkOutNote() : current.checkOutNote(),
                status,
                id
        );
        if (updated == 0) {
            throw new ResourceNotFoundException("Attendance", "id", id);
        }
        return getById(id);
    }

    @Transactional
    public void delete(long id) {
        int updated = jdbc.update("DELETE FROM staff_attendance WHERE id = ?", id);
        if (updated == 0) {
            throw new ResourceNotFoundException("Attendance", "id", id);
        }
    }

    private void ensureNoOpenSession(long employeeId) {
        Long openId = jdbc.query(
                "SELECT id FROM staff_attendance WHERE employee_id = ? AND status = 'OPEN'",
                rs -> rs.next() ? rs.getLong("id") : null,
                employeeId
        );
        if (openId != null) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Employee already has an open check-in session");
        }
    }

    private void ensureEmployee(long employeeId) {
        Integer count = jdbc.queryForObject("SELECT COUNT(*) FROM employees WHERE id = ?", Integer.class, employeeId);
        if (count == null || count == 0) {
            throw new ResourceNotFoundException("Employee", "id", employeeId);
        }
    }

    /** Returns the campaign's name after confirming it exists and is currently ACTIVE. */
    private String ensureCampaignOpenForCheckIn(long campaignId) {
        List<Map<String, Object>> rows = jdbc.queryForList(
                "SELECT name, status FROM campaigns WHERE id = ?", campaignId
        );
        if (rows.isEmpty()) {
            throw new ResourceNotFoundException("Campaign", "id", campaignId);
        }
        String status = String.valueOf(rows.get(0).get("status"));
        if (!ACTIVE_CAMPAIGN_STATUS.equals(status)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Campaign is not open for check-in");
        }
        return String.valueOf(rows.get(0).get("name"));
    }

    private void ensureCampaignExists(long campaignId) {
        Integer count = jdbc.queryForObject("SELECT COUNT(*) FROM campaigns WHERE id = ?", Integer.class, campaignId);
        if (count == null || count == 0) {
            throw new ResourceNotFoundException("Campaign", "id", campaignId);
        }
    }

    private void ensureEventBelongsToCampaign(long eventId, long campaignId) {
        Integer count = jdbc.queryForObject(
                "SELECT COUNT(*) FROM campaign_events WHERE id = ? AND campaign_id = ?",
                Integer.class, eventId, campaignId
        );
        if (count == null || count == 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Event does not belong to the given campaign");
        }
    }

    private static void setNullableDouble(PreparedStatement ps, int index, Double value) throws java.sql.SQLException {
        if (value == null) {
            ps.setNull(index, java.sql.Types.DOUBLE);
        } else {
            ps.setDouble(index, value);
        }
    }

    private static void setNullableLong(PreparedStatement ps, int index, Long value) throws java.sql.SQLException {
        if (value == null) {
            ps.setNull(index, java.sql.Types.BIGINT);
        } else {
            ps.setLong(index, value);
        }
    }

    private static long generatedId(KeyHolder keyHolder) {
        Number key = keyHolder.getKey();
        if (key == null) {
            throw new IllegalStateException("Failed to retrieve generated attendance id");
        }
        return key.longValue();
    }

    private static AttendanceDto mapRow(java.sql.ResultSet rs, int rowNum) throws java.sql.SQLException {
        Timestamp checkInAt = rs.getTimestamp("check_in_at");
        Timestamp checkOutAt = rs.getTimestamp("check_out_at");
        Long workedMinutes = null;
        if (checkInAt != null && checkOutAt != null) {
            workedMinutes = Duration.between(checkInAt.toLocalDateTime(), checkOutAt.toLocalDateTime()).toMinutes();
        }
        long campaignId = rs.getLong("campaign_id");
        return new AttendanceDto(
                rs.getLong("id"),
                rs.getLong("employee_id"),
                rs.getString("employee_name"),
                rs.wasNull() || campaignId == 0 ? null : campaignId,
                rs.getString("campaign_name"),
                (Long) rs.getObject("event_id"),
                rs.getString("event_name"),
                checkInAt == null ? null : checkInAt.toLocalDateTime(),
                checkOutAt == null ? null : checkOutAt.toLocalDateTime(),
                rs.getString("check_in_note"),
                rs.getString("check_out_note"),
                (Double) rs.getObject("check_in_lat"),
                (Double) rs.getObject("check_in_lng"),
                (Double) rs.getObject("check_out_lat"),
                (Double) rs.getObject("check_out_lng"),
                rs.getString("status"),
                workedMinutes
        );
    }
}
