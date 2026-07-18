package com.vnmap.attendance.service;

import com.vnmap.attendance.dto.AttendanceDto;
import com.vnmap.attendance.dto.CheckInRequest;
import com.vnmap.attendance.dto.CheckOutRequest;
import com.vnmap.attendance.dto.UpdateAttendanceRequest;
import com.vnmap.common.exception.ResourceNotFoundException;
import com.vnmap.common.model.PagedResponse;
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

/**
 * Staff check-in / check-out (attendance) tracking.
 *
 * Self-service: STAFF/MANAGER check themselves in and out (one open session
 * at a time per employee, enforced by a partial unique index).
 *
 * Oversight: MANAGER can list, correct, and delete any employee's records;
 * ADMIN has read-only visibility (role gating lives in SecurityConfig).
 */
@Service
public class AttendanceService {

    private static final RowMapper<AttendanceDto> ROW_MAPPER = AttendanceService::mapRow;

    private final JdbcTemplate jdbc;

    public AttendanceService(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @Transactional
    public AttendanceDto checkIn(long employeeId, CheckInRequest request) {
        ensureEmployee(employeeId);
        ensureNoOpenSession(employeeId);

        KeyHolder keyHolder = new GeneratedKeyHolder();
        jdbc.update(connection -> {
            PreparedStatement ps = connection.prepareStatement("""
                    INSERT INTO staff_attendance
                        (employee_id, check_in_at, check_in_note, check_in_lat, check_in_lng, status)
                    VALUES (?, CURRENT_TIMESTAMP, ?, ?, ?, 'OPEN')
                    """, Statement.RETURN_GENERATED_KEYS);
            ps.setLong(1, employeeId);
            ps.setString(2, request == null ? null : request.note());
            setNullableDouble(ps, 3, request == null ? null : request.lat());
            setNullableDouble(ps, 4, request == null ? null : request.lng());
            return ps;
        }, keyHolder);

        return getById(generatedId(keyHolder));
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

        return getById(openId);
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
                SELECT a.*, e.full_name AS employee_name
                FROM staff_attendance a
                JOIN employees e ON e.id = a.employee_id
                """ + where + """
                 ORDER BY a.check_in_at DESC
                 LIMIT ? OFFSET ?
                """, ROW_MAPPER, pageParams.toArray());

        return PagedResponse.of(items, page, limit, total == null ? 0 : total);
    }

    public AttendanceDto getById(long id) {
        return jdbc.query("""
                SELECT a.*, e.full_name AS employee_name
                FROM staff_attendance a
                JOIN employees e ON e.id = a.employee_id
                WHERE a.id = ?
                """, ROW_MAPPER, id
        ).stream().findFirst().orElseThrow(() -> new ResourceNotFoundException("Attendance", "id", id));
    }

    @Transactional
    public AttendanceDto update(long id, UpdateAttendanceRequest request) {
        AttendanceDto current = getById(id);

        LocalDateTime checkInAt = request.checkInAt() != null ? request.checkInAt() : current.checkInAt();
        LocalDateTime checkOutAt = request.checkOutAt() != null ? request.checkOutAt() : current.checkOutAt();
        if (checkOutAt != null && checkOutAt.isBefore(checkInAt)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "checkOutAt must not be before checkInAt");
        }
        String status = checkOutAt != null ? "CLOSED" : "OPEN";

        int updated = jdbc.update("""
                UPDATE staff_attendance
                SET check_in_at = ?,
                    check_out_at = ?,
                    check_in_note = ?,
                    check_out_note = ?,
                    status = ?,
                    updated_at = CURRENT_TIMESTAMP
                WHERE id = ?
                """,
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

    private static void setNullableDouble(PreparedStatement ps, int index, Double value) throws java.sql.SQLException {
        if (value == null) {
            ps.setNull(index, java.sql.Types.DOUBLE);
        } else {
            ps.setDouble(index, value);
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
        return new AttendanceDto(
                rs.getLong("id"),
                rs.getLong("employee_id"),
                rs.getString("employee_name"),
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
