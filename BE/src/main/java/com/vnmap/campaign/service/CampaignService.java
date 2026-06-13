package com.vnmap.campaign.service;

import com.vnmap.campaign.dto.*;
import com.vnmap.common.exception.ResourceNotFoundException;
import com.vnmap.common.model.PagedResponse;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.jdbc.support.KeyHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.Statement;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Service
public class CampaignService {

    private final JdbcTemplate jdbc;

    public CampaignService(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public PagedResponse<SchoolDto> getSchools(
            int page,
            int limit,
            String provinceCode,
            String communeCode,
            String area,
            String query
    ) {
        int safePage = Math.max(page, 0);
        int safeLimit = Math.min(Math.max(limit, 1), 200);
        List<Object> params = new ArrayList<>();
        String where = buildSchoolWhere(provinceCode, communeCode, area, query, params);

        Long total = jdbc.queryForObject("SELECT COUNT(*) FROM schools " + where, Long.class, params.toArray());
        params.add(safeLimit);
        params.add(safePage * safeLimit);

        List<SchoolDto> items = jdbc.query(
                """
                SELECT school_uid, province_code, province_name, commune_code, commune_name,
                       school_code, school_name, address, area_type
                FROM schools
                %s
                ORDER BY province_code, school_name
                LIMIT ? OFFSET ?
                """.formatted(where),
                this::mapSchool,
                params.toArray()
        );

        return PagedResponse.of(items, safePage, safeLimit, total == null ? 0 : total);
    }

    public SchoolDetailDto getSchoolDetail(String schoolUid) {
        SchoolDto school = getSchool(schoolUid);
        List<StudentDto> students = jdbc.query(
                "SELECT id, school_uid, full_name, grade, class_name FROM students WHERE school_uid = ? ORDER BY full_name",
                (rs, rowNum) -> new StudentDto(
                        rs.getLong("id"),
                        rs.getString("school_uid"),
                        rs.getString("full_name"),
                        rs.getString("grade"),
                        rs.getString("class_name")
                ),
                schoolUid
        );
        List<PersonDto> persons = jdbc.query(
                "SELECT id, school_uid, full_name, role FROM persons WHERE school_uid = ? ORDER BY full_name",
                (rs, rowNum) -> new PersonDto(
                        rs.getLong("id"),
                        rs.getString("school_uid"),
                        rs.getString("full_name"),
                        rs.getString("role")
                ),
                schoolUid
        );
        List<StudentRelativeDto> relatives = jdbc.query(
                """
                SELECT id, school_uid, full_name, student_id, relationship, phone
                FROM student_relatives
                WHERE school_uid = ?
                ORDER BY full_name
                """,
                (rs, rowNum) -> new StudentRelativeDto(
                        rs.getLong("id"),
                        rs.getString("school_uid"),
                        rs.getString("full_name"),
                        rs.getLong("student_id"),
                        rs.getString("relationship"),
                        rs.getString("phone")
                ),
                schoolUid
        );
        return new SchoolDetailDto(school, students, persons, relatives);
    }

    public List<CampaignDto> getCampaigns() {
        return jdbc.query(
                """
                SELECT id, name, status, objective, start_date, end_date, owner_employee_id
                FROM campaigns
                ORDER BY created_at DESC, id DESC
                """,
                this::mapCampaign
        );
    }

    public CampaignDto getCampaign(long id) {
        return jdbc.query(
                """
                SELECT id, name, status, objective, start_date, end_date, owner_employee_id
                FROM campaigns
                WHERE id = ?
                """,
                this::mapCampaign,
                id
        ).stream().findFirst().orElseThrow(() -> new ResourceNotFoundException("Campaign", "id", id));
    }

    @Transactional
    public CampaignDto createCampaign(CampaignRequest request) {
        KeyHolder keyHolder = new GeneratedKeyHolder();
        jdbc.update(connection -> {
            PreparedStatement ps = connection.prepareStatement(
                    """
                    INSERT INTO campaigns (
                        name, status, objective, start_date, end_date, owner_employee_id
                    ) VALUES (?, ?, ?, ?, ?, ?)
                    """,
                    Statement.RETURN_GENERATED_KEYS
            );
            ps.setString(1, request.name());
            ps.setString(2, request.status());
            ps.setString(3, request.objective());
            ps.setDate(4, request.startDate() == null ? null : Date.valueOf(request.startDate()));
            ps.setDate(5, request.endDate() == null ? null : Date.valueOf(request.endDate()));
            ps.setLong(6, request.ownerEmployeeId());
            return ps;
        }, keyHolder);
        return getCampaign(keyHolder.getKey().longValue());
    }

    @Transactional
    public CampaignDto updateCampaign(long id, CampaignRequest request) {
        int updated = jdbc.update(
                """
                UPDATE campaigns
                SET name = ?, status = ?, objective = ?, start_date = ?, end_date = ?,
                    owner_employee_id = ?, updated_at = CURRENT_TIMESTAMP
                WHERE id = ?
                """,
                request.name(),
                request.status(),
                request.objective(),
                request.startDate() == null ? null : Date.valueOf(request.startDate()),
                request.endDate() == null ? null : Date.valueOf(request.endDate()),
                request.ownerEmployeeId(),
                id
        );
        if (updated == 0) {
            throw new ResourceNotFoundException("Campaign", "id", id);
        }
        return getCampaign(id);
    }

    public CampaignDashboardDto getDashboard(long campaignId) {
        getCampaign(campaignId);

        Long totalEvents = jdbc.queryForObject(
                "SELECT COUNT(*) FROM campaign_events WHERE campaign_id = ?",
                Long.class,
                campaignId
        );
        Long totalTargetSchools = jdbc.queryForObject(
                """
                SELECT COUNT(DISTINCT es.school_uid)
                FROM event_schools es
                JOIN campaign_events e ON e.id = es.event_id
                WHERE e.campaign_id = ?
                """,
                Long.class,
                campaignId
        );
        Long totalAssignedEmployees = jdbc.queryForObject(
                """
                SELECT COUNT(DISTINCT ea.employee_id)
                FROM event_assignments ea
                JOIN campaign_events e ON e.id = ea.event_id
                WHERE e.campaign_id = ?
                """,
                Long.class,
                campaignId
        );
        Long totalInteractions = jdbc.queryForObject(
                "SELECT COUNT(*) FROM interactions WHERE campaign_id = ?",
                Long.class,
                campaignId
        );

        Map<String, Long> byOutcome = new LinkedHashMap<>();
        byOutcome.put("INTERESTED", 0L);
        byOutcome.put("NOT_INTERESTED", 0L);
        byOutcome.put("FOLLOW_UP", 0L);
        jdbc.queryForList(
                "SELECT outcome, COUNT(*) total FROM interactions WHERE campaign_id = ? GROUP BY outcome",
                campaignId
        ).forEach(row -> byOutcome.put(
                (String) row.get("outcome"),
                ((Number) row.get("total")).longValue()
        ));

        List<ProvinceInteractionDto> byProvince = jdbc.query(
                """
                SELECT s.province_code, s.province_name, COUNT(i.id) total
                FROM interactions i
                JOIN schools s ON s.school_uid = i.school_uid
                WHERE i.campaign_id = ?
                GROUP BY s.province_code, s.province_name
                ORDER BY total DESC, s.province_name
                """,
                (rs, rowNum) -> new ProvinceInteractionDto(
                        rs.getString("province_code"),
                        rs.getString("province_name"),
                        rs.getLong("total")
                ),
                campaignId
        );
        List<TopSchoolDto> topSchools = jdbc.query(
                """
                SELECT s.school_uid, s.school_name, COUNT(i.id) total
                FROM interactions i
                JOIN schools s ON s.school_uid = i.school_uid
                WHERE i.campaign_id = ?
                GROUP BY s.school_uid, s.school_name
                ORDER BY total DESC, s.school_name
                LIMIT 10
                """,
                (rs, rowNum) -> new TopSchoolDto(
                        rs.getString("school_uid"),
                        rs.getString("school_name"),
                        rs.getLong("total")
                ),
                campaignId
        );

        return new CampaignDashboardDto(
                campaignId,
                zero(totalEvents),
                zero(totalTargetSchools),
                zero(totalAssignedEmployees),
                zero(totalInteractions),
                byOutcome,
                byProvince,
                topSchools
        );
    }

    public List<CampaignEventDto> getEvents(long campaignId) {
        getCampaign(campaignId);
        return jdbc.query(
                """
                SELECT id, campaign_id, name, event_type, status, starts_at, ends_at, note
                FROM campaign_events
                WHERE campaign_id = ?
                ORDER BY starts_at NULLS LAST, id
                """,
                this::mapEvent,
                campaignId
        );
    }

    public CampaignEventDto getEvent(long eventId) {
        return jdbc.query(
                """
                SELECT id, campaign_id, name, event_type, status, starts_at, ends_at, note
                FROM campaign_events
                WHERE id = ?
                """,
                this::mapEvent,
                eventId
        ).stream().findFirst().orElseThrow(() -> new ResourceNotFoundException("CampaignEvent", "id", eventId));
    }

    @Transactional
    public CampaignEventDto createEvent(long campaignId, CampaignEventRequest request) {
        getCampaign(campaignId);
        KeyHolder keyHolder = new GeneratedKeyHolder();
        jdbc.update(connection -> {
            PreparedStatement ps = connection.prepareStatement(
                    """
                    INSERT INTO campaign_events (
                        campaign_id, name, event_type, status, starts_at, ends_at, note
                    ) VALUES (?, ?, ?, ?, ?, ?, ?)
                    """,
                    Statement.RETURN_GENERATED_KEYS
            );
            ps.setLong(1, campaignId);
            ps.setString(2, request.name());
            ps.setString(3, request.eventType());
            ps.setString(4, request.status());
            ps.setTimestamp(5, timestamp(request.startsAt()));
            ps.setTimestamp(6, timestamp(request.endsAt()));
            ps.setString(7, request.note());
            return ps;
        }, keyHolder);
        return getEvent(keyHolder.getKey().longValue());
    }

    @Transactional
    public CampaignEventDto updateEvent(long eventId, CampaignEventRequest request) {
        int updated = jdbc.update(
                """
                UPDATE campaign_events
                SET name = ?, event_type = ?, status = ?, starts_at = ?, ends_at = ?,
                    note = ?, updated_at = CURRENT_TIMESTAMP
                WHERE id = ?
                """,
                request.name(),
                request.eventType(),
                request.status(),
                timestamp(request.startsAt()),
                timestamp(request.endsAt()),
                request.note(),
                eventId
        );
        if (updated == 0) {
            throw new ResourceNotFoundException("CampaignEvent", "id", eventId);
        }
        return getEvent(eventId);
    }

    @Transactional
    public void assignSchool(long eventId, String schoolUid) {
        getEvent(eventId);
        getSchool(schoolUid);
        jdbc.update(
                "INSERT INTO event_schools (event_id, school_uid) VALUES (?, ?) ON CONFLICT DO NOTHING",
                eventId,
                schoolUid
        );
    }

    @Transactional
    public void removeSchool(long eventId, String schoolUid) {
        jdbc.update("DELETE FROM event_schools WHERE event_id = ? AND school_uid = ?", eventId, schoolUid);
    }

    @Transactional
    public void assignEmployee(long eventId, long employeeId) {
        getEvent(eventId);
        ensureEmployee(employeeId);
        jdbc.update(
                "INSERT INTO event_assignments (event_id, employee_id) VALUES (?, ?) ON CONFLICT DO NOTHING",
                eventId,
                employeeId
        );
    }

    @Transactional
    public void removeEmployee(long eventId, long employeeId) {
        jdbc.update("DELETE FROM event_assignments WHERE event_id = ? AND employee_id = ?", eventId, employeeId);
    }

    public List<InteractionDto> getInteractions(long eventId) {
        getEvent(eventId);
        return jdbc.query(
                """
                SELECT id, campaign_id, event_id, employee_id, school_uid, participant_type,
                       participant_id, channel, outcome, note, next_follow_up_at, created_at
                FROM interactions
                WHERE event_id = ?
                ORDER BY created_at DESC, id DESC
                """,
                this::mapInteraction,
                eventId
        );
    }

    @Transactional
    public InteractionDto createInteraction(long eventId, CreateInteractionRequest request) {
        CampaignEventDto event = getEvent(eventId);
        ensureEmployee(request.employeeId());
        getSchool(request.schoolUid());
        KeyHolder keyHolder = new GeneratedKeyHolder();
        jdbc.update(connection -> {
            PreparedStatement ps = connection.prepareStatement(
                    """
                    INSERT INTO interactions (
                        campaign_id, event_id, employee_id, school_uid, participant_type,
                        participant_id, channel, outcome, note, next_follow_up_at
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """,
                    Statement.RETURN_GENERATED_KEYS
            );
            ps.setLong(1, event.campaignId());
            ps.setLong(2, eventId);
            ps.setLong(3, request.employeeId());
            ps.setString(4, request.schoolUid());
            ps.setString(5, request.participantType());
            ps.setLong(6, request.participantId());
            ps.setString(7, request.channel());
            ps.setString(8, request.outcome());
            ps.setString(9, request.note());
            ps.setTimestamp(10, timestamp(request.nextFollowUpAt()));
            return ps;
        }, keyHolder);

        long id = keyHolder.getKey().longValue();
        return jdbc.query(
                """
                SELECT id, campaign_id, event_id, employee_id, school_uid, participant_type,
                       participant_id, channel, outcome, note, next_follow_up_at, created_at
                FROM interactions
                WHERE id = ?
                """,
                this::mapInteraction,
                id
        ).get(0);
    }

    private String buildSchoolWhere(
            String provinceCode,
            String communeCode,
            String area,
            String query,
            List<Object> params
    ) {
        List<String> filters = new ArrayList<>();
        if (provinceCode != null && !provinceCode.isBlank()) {
            filters.add("province_code = ?");
            params.add(provinceCode);
        }
        if (communeCode != null && !communeCode.isBlank()) {
            filters.add("commune_code = ?");
            params.add(communeCode);
        }
        if (area != null && !area.isBlank()) {
            filters.add("area_type = ?");
            params.add(area);
        }
        if (query != null && !query.isBlank()) {
            filters.add("(LOWER(school_name) LIKE LOWER(?) OR LOWER(address) LIKE LOWER(?))");
            String pattern = "%" + query.trim() + "%";
            params.add(pattern);
            params.add(pattern);
        }
        return filters.isEmpty() ? "" : "WHERE " + String.join(" AND ", filters);
    }

    private SchoolDto getSchool(String schoolUid) {
        return jdbc.query(
                """
                SELECT school_uid, province_code, province_name, commune_code, commune_name,
                       school_code, school_name, address, area_type
                FROM schools
                WHERE school_uid = ?
                """,
                this::mapSchool,
                schoolUid
        ).stream().findFirst().orElseThrow(() -> new ResourceNotFoundException("School", "schoolUid", schoolUid));
    }

    private void ensureEmployee(long employeeId) {
        Integer count = jdbc.queryForObject("SELECT COUNT(*) FROM employees WHERE id = ?", Integer.class, employeeId);
        if (count == null || count == 0) {
            throw new ResourceNotFoundException("Employee", "id", employeeId);
        }
    }

    private long zero(Long value) {
        return value == null ? 0 : value;
    }

    private Timestamp timestamp(LocalDateTime value) {
        return value == null ? null : Timestamp.valueOf(value);
    }

    private SchoolDto mapSchool(java.sql.ResultSet rs, int rowNum) throws java.sql.SQLException {
        return new SchoolDto(
                rs.getString("school_uid"),
                rs.getString("province_code"),
                rs.getString("province_name"),
                rs.getString("commune_code"),
                rs.getString("commune_name"),
                rs.getString("school_code"),
                rs.getString("school_name"),
                rs.getString("address"),
                rs.getString("area_type")
        );
    }

    private CampaignDto mapCampaign(java.sql.ResultSet rs, int rowNum) throws java.sql.SQLException {
        Date startDate = rs.getDate("start_date");
        Date endDate = rs.getDate("end_date");
        return new CampaignDto(
                rs.getLong("id"),
                rs.getString("name"),
                rs.getString("status"),
                rs.getString("objective"),
                startDate == null ? null : startDate.toLocalDate(),
                endDate == null ? null : endDate.toLocalDate(),
                rs.getObject("owner_employee_id", Long.class)
        );
    }

    private CampaignEventDto mapEvent(java.sql.ResultSet rs, int rowNum) throws java.sql.SQLException {
        Timestamp startsAt = rs.getTimestamp("starts_at");
        Timestamp endsAt = rs.getTimestamp("ends_at");
        return new CampaignEventDto(
                rs.getLong("id"),
                rs.getLong("campaign_id"),
                rs.getString("name"),
                rs.getString("event_type"),
                rs.getString("status"),
                startsAt == null ? null : startsAt.toLocalDateTime(),
                endsAt == null ? null : endsAt.toLocalDateTime(),
                rs.getString("note")
        );
    }

    private InteractionDto mapInteraction(java.sql.ResultSet rs, int rowNum) throws java.sql.SQLException {
        Timestamp nextFollowUpAt = rs.getTimestamp("next_follow_up_at");
        Timestamp createdAt = rs.getTimestamp("created_at");
        return new InteractionDto(
                rs.getLong("id"),
                rs.getLong("campaign_id"),
                rs.getLong("event_id"),
                rs.getLong("employee_id"),
                rs.getString("school_uid"),
                rs.getString("participant_type"),
                rs.getLong("participant_id"),
                rs.getString("channel"),
                rs.getString("outcome"),
                rs.getString("note"),
                nextFollowUpAt == null ? null : nextFollowUpAt.toLocalDateTime(),
                createdAt == null ? null : createdAt.toLocalDateTime()
        );
    }
}
