package com.vnmap.attendance.service;

import com.vnmap.attendance.dto.AttendanceDto;
import com.vnmap.attendance.dto.AttendanceTargetDto;
import com.vnmap.attendance.dto.CheckInRequest;
import com.vnmap.attendance.dto.CheckOutRequest;
import com.vnmap.attendance.dto.CreateAttendanceRequest;
import com.vnmap.attendance.dto.UpdateAttendanceRequest;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.vnmap.common.exception.ResourceNotFoundException;
import com.vnmap.common.model.PagedResponse;
import com.vnmap.notification.service.NotificationTriggerService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.jdbc.support.KeyHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;
import org.springframework.web.server.ResponseStatusException;

import java.sql.PreparedStatement;
import java.sql.Statement;
import java.sql.Timestamp;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;

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

    private static final Logger log = LoggerFactory.getLogger(AttendanceService.class);
    private static final String ACTIVE_CAMPAIGN_STATUS = "ACTIVE";
    private static final ZoneId BUSINESS_ZONE = ZoneId.of("Asia/Ho_Chi_Minh");
    private static final Set<String> VALID_STATUSES = Set.of("OPEN", "CLOSED");
    private static final RowMapper<AttendanceDto> ROW_MAPPER = AttendanceService::mapRow;
    private static final ObjectMapper OBJECT_MAPPER = new ObjectMapper().findAndRegisterModules();

    private final JdbcTemplate jdbc;
    private final NotificationTriggerService notificationTriggerService;

    public AttendanceService(JdbcTemplate jdbc, NotificationTriggerService notificationTriggerService) {
        this.jdbc = jdbc;
        this.notificationTriggerService = notificationTriggerService;
    }

    @Transactional
    public AttendanceDto checkIn(long employeeId, CheckInRequest request) {
        return checkIn(employeeId, request, null);
    }

    @Transactional
    public AttendanceDto checkIn(long employeeId, CheckInRequest request, String idempotencyKey) {
        ensureEmployee(employeeId);
        String normalizedKey = normalizeIdempotencyKey(idempotencyKey);
        AttendanceDto replay = findByRequestId(employeeId, "check_in_request_id", normalizedKey);
        if (replay != null) {
            return replay;
        }
        String campaignName = ensureCampaignOpenForCheckIn(employeeId, request.campaignId(), request.eventId());

        KeyHolder keyHolder = new GeneratedKeyHolder();
        int inserted = jdbc.update(connection -> {
            PreparedStatement ps = connection.prepareStatement("""
                    INSERT INTO staff_attendance
                        (employee_id, campaign_id, event_id, check_in_at, check_in_note,
                         check_in_lat, check_in_lng, check_in_request_id, status)
                    VALUES (?, ?, ?, CURRENT_TIMESTAMP, ?, ?, ?, ?, 'OPEN')
                    ON CONFLICT DO NOTHING
                    """, new String[]{"id"});
            ps.setLong(1, employeeId);
            ps.setLong(2, request.campaignId());
            setNullableLong(ps, 3, request.eventId());
            ps.setString(4, request.note());
            setNullableDouble(ps, 5, request.lat());
            setNullableDouble(ps, 6, request.lng());
            ps.setString(7, normalizedKey);
            return ps;
        }, keyHolder);

        if (inserted == 0) {
            replay = findByRequestId(employeeId, "check_in_request_id", normalizedKey);
            if (replay != null) {
                return replay;
            }
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Employee already has an open check-in session");
        }

        AttendanceDto created = getById(generatedId(keyHolder));
        runAfterCommit(() -> notificationTriggerService.staffCheckedIn(
                employeeId, request.campaignId(), campaignName));
        return created;
    }

    @Transactional
    public AttendanceDto checkOut(long employeeId, CheckOutRequest request) {
        return checkOut(employeeId, request, null);
    }

    @Transactional
    public AttendanceDto checkOut(long employeeId, CheckOutRequest request, String idempotencyKey) {
        ensureEmployee(employeeId);
        String normalizedKey = normalizeIdempotencyKey(idempotencyKey);
        AttendanceDto replay = findByRequestId(employeeId, "check_out_request_id", normalizedKey);
        if (replay != null) {
            return replay;
        }

        int updated = jdbc.update(connection -> {
            PreparedStatement ps = connection.prepareStatement("""
                    UPDATE staff_attendance
                    SET check_out_at = CURRENT_TIMESTAMP,
                        check_out_note = ?,
                        check_out_lat = ?,
                        check_out_lng = ?,
                        check_out_request_id = ?,
                        status = 'CLOSED',
                        updated_at = CURRENT_TIMESTAMP
                    WHERE employee_id = ?
                      AND status = 'OPEN'
                      AND deleted_at IS NULL
                    """);
            ps.setString(1, request == null ? null : request.note());
            setNullableDouble(ps, 2, request == null ? null : request.lat());
            setNullableDouble(ps, 3, request == null ? null : request.lng());
            ps.setString(4, normalizedKey);
            ps.setLong(5, employeeId);
            return ps;
        });

        if (updated == 0) {
            replay = findByRequestId(employeeId, "check_out_request_id", normalizedKey);
            if (replay != null) {
                return replay;
            }
            throw new ResponseStatusException(HttpStatus.CONFLICT, "No open check-in session found for this employee");
        }

        Long closedId = normalizedKey == null
                ? jdbc.query("""
                        SELECT id FROM staff_attendance
                        WHERE employee_id = ? AND status = 'CLOSED' AND deleted_at IS NULL
                        ORDER BY check_out_at DESC, id DESC LIMIT 1
                        """, rs -> rs.next() ? rs.getLong("id") : null, employeeId)
                : findAttendanceIdByRequest(employeeId, "check_out_request_id", normalizedKey);
        if (closedId == null) {
            throw new IllegalStateException("Closed attendance record could not be reloaded");
        }
        AttendanceDto closed = getById(closedId);
        if (closed.campaignId() != null) {
            runAfterCommit(() -> notificationTriggerService.staffCheckedOut(
                    employeeId, closed.campaignId(), closed.campaignName()));
        }
        return closed;
    }

    @Transactional
    public AttendanceDto create(CreateAttendanceRequest request) {
        return create(request, null);
    }

    @Transactional
    public AttendanceDto create(CreateAttendanceRequest request, Long actorUserId) {
        ensureEmployee(request.employeeId());
        ensureCampaignExists(request.campaignId());
        if (request.eventId() != null) {
            ensureEventBelongsToCampaign(request.eventId(), request.campaignId());
        }
        Instant checkInAt = request.checkInAt() != null ? request.checkInAt() : Instant.now();
        Instant checkOutAt = request.checkOutAt();
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
            ps.setTimestamp(4, Timestamp.from(checkInAt));
            if (checkOutAt == null) {
                ps.setNull(5, java.sql.Types.TIMESTAMP_WITH_TIMEZONE);
            } else {
                ps.setTimestamp(5, Timestamp.from(checkOutAt));
            }
            ps.setString(6, request.checkInNote());
            ps.setString(7, request.checkOutNote());
            ps.setString(8, status);
            return ps;
        }, keyHolder);

        AttendanceDto created = getById(generatedId(keyHolder));
        writeAudit(created.id(), "CREATE", actorUserId, request.correctionReason(), null, created);
        return created;
    }

    public PagedResponse<AttendanceDto> list(
            Long employeeId, String status, Instant from, Instant to, int page, int limit
    ) {
        return list(employeeId, null, status, from, to, page, limit);
    }

    public PagedResponse<AttendanceDto> list(
            Long employeeId, Long campaignId, String status, Instant from, Instant to, int page, int limit
    ) {
        if (from != null && to != null && from.isAfter(to)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "from must not be after to");
        }
        List<Object> params = new ArrayList<>();
        StringBuilder where = new StringBuilder(" WHERE a.deleted_at IS NULL");
        if (employeeId != null) {
            where.append(" AND a.employee_id = ?");
            params.add(employeeId);
        }
        if (campaignId != null) {
            where.append(" AND a.campaign_id = ?");
            params.add(campaignId);
        }
        if (status != null && !status.isBlank()) {
            String normalizedStatus = status.toUpperCase(Locale.ROOT);
            if (!VALID_STATUSES.contains(normalizedStatus)) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "status must be OPEN or CLOSED");
            }
            where.append(" AND a.status = ?");
            params.add(normalizedStatus);
        }
        if (from != null) {
            where.append(" AND a.check_in_at >= ?");
            params.add(Timestamp.from(from));
        }
        if (to != null) {
            where.append(" AND a.check_in_at <= ?");
            params.add(Timestamp.from(to));
        }

        Long total = jdbc.queryForObject(
                "SELECT COUNT(*) FROM staff_attendance a" + where,
                Long.class, params.toArray()
        );

        List<Object> pageParams = new ArrayList<>(params);
        pageParams.add(limit);
        pageParams.add(Math.multiplyExact((long) page, (long) limit));
        List<AttendanceDto> items = jdbc.query("""
                SELECT a.*, e.full_name AS employee_name, c.name AS campaign_name, ev.name AS event_name
                FROM staff_attendance a
                JOIN employees e ON e.id = a.employee_id
                LEFT JOIN campaigns c ON c.id = a.campaign_id
                LEFT JOIN campaign_events ev ON ev.id = a.event_id
                """ + where + """
                 ORDER BY a.check_in_at DESC, a.id DESC
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
                WHERE a.id = ? AND a.deleted_at IS NULL
                """, ROW_MAPPER, id
        ).stream().findFirst().orElseThrow(() -> new ResourceNotFoundException("Attendance", "id", id));
    }

    public List<AttendanceTargetDto> eligibleTargets(long employeeId) {
        ensureEmployee(employeeId);
        return jdbc.query("""
                SELECT c.id AS campaign_id, c.name AS campaign_name, c.start_date, c.end_date,
                       ev.id AS event_id, ev.name AS event_name, ev.starts_at, ev.ends_at
                FROM event_assignments ea
                JOIN campaign_events ev ON ev.id = ea.event_id
                JOIN campaigns c ON c.id = ev.campaign_id
                WHERE ea.employee_id = ?
                  AND c.status = 'ACTIVE'
                  AND (c.start_date IS NULL OR c.start_date <= CURRENT_DATE)
                  AND (c.end_date IS NULL OR c.end_date >= CURRENT_DATE)
                  AND ev.status <> 'ARCHIVED'
                ORDER BY c.name, ev.starts_at NULLS LAST, ev.name
                """, (rs, rowNum) -> new AttendanceTargetDto(
                rs.getLong("campaign_id"),
                rs.getString("campaign_name"),
                rs.getObject("start_date", LocalDate.class),
                rs.getObject("end_date", LocalDate.class),
                rs.getLong("event_id"),
                rs.getString("event_name"),
                toInstant(rs.getTimestamp("starts_at")),
                toInstant(rs.getTimestamp("ends_at"))
        ), employeeId);
    }

    @Transactional
    public AttendanceDto update(long id, UpdateAttendanceRequest request) {
        return update(id, request, null);
    }

    @Transactional
    public AttendanceDto update(long id, UpdateAttendanceRequest request, Long actorUserId) {
        AttendanceDto current = getById(id);

        Long campaignId = request.campaignId() != null ? request.campaignId() : current.campaignId();
        Long eventId = Boolean.TRUE.equals(request.clearEvent())
                ? null
                : request.eventId() != null ? request.eventId() : current.eventId();
        if (request.campaignId() != null) {
            ensureCampaignExists(campaignId);
        }
        if (eventId != null) {
            ensureEventBelongsToCampaign(eventId, campaignId);
        }

        Instant checkInAt = request.checkInAt() != null ? request.checkInAt() : current.checkInAt();
        Instant checkOutAt = Boolean.TRUE.equals(request.clearCheckOutAt())
                ? null
                : request.checkOutAt() != null ? request.checkOutAt() : current.checkOutAt();
        if (checkOutAt != null && checkOutAt.isBefore(checkInAt)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "checkOutAt must not be before checkInAt");
        }
        if (checkOutAt == null && current.checkOutAt() != null) {
            ensureNoOpenSession(current.employeeId(), id);
        }
        String status = checkOutAt != null ? "CLOSED" : "OPEN";
        String checkInNote = Boolean.TRUE.equals(request.clearCheckInNote())
                ? null
                : request.checkInNote() != null ? request.checkInNote() : current.checkInNote();
        String checkOutNote = Boolean.TRUE.equals(request.clearCheckOutNote())
                ? null
                : request.checkOutNote() != null ? request.checkOutNote() : current.checkOutNote();

        int updated = jdbc.update("""
                UPDATE staff_attendance
                SET campaign_id = ?,
                    event_id = ?,
                    check_in_at = ?,
                    check_out_at = ?,
                    check_in_note = ?,
                    check_out_note = ?,
                    status = ?,
                    updated_by_user_id = ?,
                    updated_at = CURRENT_TIMESTAMP
                WHERE id = ? AND deleted_at IS NULL
                """,
                campaignId,
                eventId,
                Timestamp.from(checkInAt),
                checkOutAt == null ? null : Timestamp.from(checkOutAt),
                checkInNote,
                checkOutNote,
                status,
                actorUserId,
                id
        );
        if (updated == 0) {
            throw new ResourceNotFoundException("Attendance", "id", id);
        }
        AttendanceDto corrected = getById(id);
        writeAudit(id, "UPDATE", actorUserId, request.correctionReason(), current, corrected);
        return corrected;
    }

    @Transactional
    public void delete(long id) {
        delete(id, null, "Attendance record removed");
    }

    @Transactional
    public void delete(long id, Long actorUserId, String reason) {
        AttendanceDto current = getById(id);
        int updated = jdbc.update("""
                UPDATE staff_attendance
                SET deleted_at = CURRENT_TIMESTAMP,
                    deleted_by_user_id = ?,
                    delete_reason = ?,
                    updated_at = CURRENT_TIMESTAMP
                WHERE id = ? AND deleted_at IS NULL
                """, actorUserId, reason, id);
        if (updated == 0) {
            throw new ResourceNotFoundException("Attendance", "id", id);
        }
        writeAudit(id, "DELETE", actorUserId, reason, current, null);
    }

    private void ensureNoOpenSession(long employeeId) {
        ensureNoOpenSession(employeeId, null);
    }

    private void ensureNoOpenSession(long employeeId, Long excludedId) {
        Long openId = jdbc.query(
                """
                SELECT id FROM staff_attendance
                WHERE employee_id = ?
                  AND status = 'OPEN'
                  AND deleted_at IS NULL
                  AND (? IS NULL OR id <> ?)
                """,
                rs -> rs.next() ? rs.getLong("id") : null,
                employeeId, excludedId, excludedId
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
    private String ensureCampaignOpenForCheckIn(long employeeId, long campaignId, Long eventId) {
        List<Map<String, Object>> rows = jdbc.queryForList(
                "SELECT name, status, start_date, end_date FROM campaigns WHERE id = ?", campaignId
        );
        if (rows.isEmpty()) {
            throw new ResourceNotFoundException("Campaign", "id", campaignId);
        }
        Map<String, Object> campaign = rows.get(0);
        String status = String.valueOf(campaign.get("status"));
        if (!ACTIVE_CAMPAIGN_STATUS.equals(status)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Campaign is not open for check-in");
        }
        LocalDate today = LocalDate.now(BUSINESS_ZONE);
        LocalDate startDate = toLocalDate(campaign.get("start_date"));
        LocalDate endDate = toLocalDate(campaign.get("end_date"));
        if ((startDate != null && today.isBefore(startDate)) || (endDate != null && today.isAfter(endDate))) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Campaign is outside its check-in date window");
        }

        Integer assigned = eventId == null
                ? jdbc.queryForObject("""
                        SELECT COUNT(*)
                        FROM event_assignments ea
                        JOIN campaign_events ev ON ev.id = ea.event_id
                        WHERE ea.employee_id = ? AND ev.campaign_id = ? AND ev.status <> 'ARCHIVED'
                        """, Integer.class, employeeId, campaignId)
                : jdbc.queryForObject("""
                        SELECT COUNT(*)
                        FROM event_assignments ea
                        JOIN campaign_events ev ON ev.id = ea.event_id
                        WHERE ea.employee_id = ? AND ea.event_id = ?
                          AND ev.campaign_id = ? AND ev.status <> 'ARCHIVED'
                        """, Integer.class, employeeId, eventId, campaignId);
        if (assigned == null || assigned == 0) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                    "Employee is not assigned to this campaign event");
        }
        return String.valueOf(campaign.get("name"));
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

    private AttendanceDto findByRequestId(long employeeId, String column, String requestId) {
        if (requestId == null) {
            return null;
        }
        String safeColumn = requestIdColumn(column);
        String sql = """
                SELECT a.*, e.full_name AS employee_name, c.name AS campaign_name, ev.name AS event_name
                FROM staff_attendance a
                JOIN employees e ON e.id = a.employee_id
                LEFT JOIN campaigns c ON c.id = a.campaign_id
                LEFT JOIN campaign_events ev ON ev.id = a.event_id
                WHERE a.employee_id = ? AND a.%s = ? AND a.deleted_at IS NULL
                """.formatted(safeColumn);
        return jdbc.query(sql, ROW_MAPPER, employeeId, requestId).stream().findFirst().orElse(null);
    }

    private Long findAttendanceIdByRequest(long employeeId, String column, String requestId) {
        String safeColumn = requestIdColumn(column);
        return jdbc.query(
                "SELECT id FROM staff_attendance WHERE employee_id = ? AND " + safeColumn
                        + " = ? AND deleted_at IS NULL",
                rs -> rs.next() ? rs.getLong("id") : null,
                employeeId, requestId
        );
    }

    private static String requestIdColumn(String column) {
        return switch (column) {
            case "check_in_request_id" -> "check_in_request_id";
            case "check_out_request_id" -> "check_out_request_id";
            default -> throw new IllegalArgumentException("Unsupported attendance request-id column");
        };
    }

    private static String normalizeIdempotencyKey(String key) {
        if (key == null || key.isBlank()) {
            return null;
        }
        String normalized = key.trim();
        if (normalized.length() > 100) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Idempotency-Key must not exceed 100 characters");
        }
        return normalized;
    }

    private void writeAudit(
            long attendanceId,
            String action,
            Long actorUserId,
            String reason,
            AttendanceDto before,
            AttendanceDto after
    ) {
        try {
            jdbc.update("""
                    INSERT INTO staff_attendance_audit
                        (attendance_id, action, actor_user_id, reason, before_data, after_data)
                    VALUES (?, ?, ?, ?, CAST(? AS jsonb), CAST(? AS jsonb))
                    """,
                    attendanceId,
                    action,
                    actorUserId,
                    reason,
                    before == null ? null : OBJECT_MAPPER.writeValueAsString(before),
                    after == null ? null : OBJECT_MAPPER.writeValueAsString(after)
            );
        } catch (JsonProcessingException ex) {
            throw new IllegalStateException("Failed to serialize attendance audit snapshot", ex);
        }
    }

    private void runAfterCommit(Runnable task) {
        Runnable safeTask = () -> {
            try {
                task.run();
            } catch (RuntimeException ex) {
                log.error("Attendance notification failed after database commit", ex);
            }
        };
        if (TransactionSynchronizationManager.isSynchronizationActive()) {
            TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
                @Override
                public void afterCommit() {
                    safeTask.run();
                }
            });
        } else {
            safeTask.run();
        }
    }

    private static LocalDate toLocalDate(Object value) {
        if (value instanceof LocalDate localDate) {
            return localDate;
        }
        if (value instanceof java.sql.Date sqlDate) {
            return sqlDate.toLocalDate();
        }
        return value == null ? null : LocalDate.parse(value.toString());
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
            workedMinutes = Duration.between(checkInAt.toInstant(), checkOutAt.toInstant()).toMinutes();
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
                toInstant(checkInAt),
                toInstant(checkOutAt),
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

    private static Instant toInstant(Timestamp timestamp) {
        return timestamp == null ? null : timestamp.toInstant();
    }
}
