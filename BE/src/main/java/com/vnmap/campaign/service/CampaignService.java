package com.vnmap.campaign.service;

import com.vnmap.campaign.dto.*;
import com.vnmap.common.exception.ResourceNotFoundException;
import com.vnmap.geo.repository.AdministrativeUnitRepository;
import com.vnmap.common.model.PagedResponse;
import com.vnmap.common.security.CurrentUser;
import com.vnmap.notification.service.NotificationTriggerService;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.jdbc.support.KeyHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.sql.PreparedStatement;
import java.sql.Statement;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** SQL clauses are assembled only from internal constants; request values are always JDBC-bound. */
@SuppressWarnings("java:S2077")
@Service
public class CampaignService {

    private static final String SCHOOL_UID_COLUMN = "school_uid";
    private static final String FULL_NAME_COLUMN = "full_name";
    private static final String TOTAL_COLUMN = "total";
    private static final String STUDENT_ID_COLUMN = "student_id";
    private static final String PHONE_COLUMN = "phone";
    private static final String PROVINCE_CODE_COLUMN = "province_code";
    private static final String PROVINCE_NAME_COLUMN = "province_name";
    private static final String SCHOOL_NAME_COLUMN = "school_name";
    private static final String CAMPAIGN_ID_COLUMN = "campaign_id";
    private static final String STATUS_COLUMN = "status";
    private static final String ACTIVE_STATUS = "ACTIVE";
    private static final String DISABLED_STATUS = "DISABLED";
    private static final String APPROVED_STATUS = "APPROVED";
    private static final String STAFF_ROLE = "STAFF";
    private static final String MANAGER_ROLE = "MANAGER";
    private static final String ADMIN_ROLE = "ADMIN";
    private static final String WHERE = "WHERE ";
    private static final String AND = " AND ";
    private static final String COMMUNE_CODE_COLUMN = "commune_code";
    private static final String COMMUNE_NAME_COLUMN = "commune_name";
    private static final String ADDRESS_COLUMN = "address";
    private static final ZoneId VIETNAM_ZONE = ZoneId.of("Asia/Ho_Chi_Minh");
    private static final String GEOCODE_STATUS_FULL = "FULL";
    private static final String GEOCODE_STATUS_APPROXIMATE = "APPROXIMATE";
    private static final String GEOCODE_STATUS_PENDING = "PENDING";
    private static final String KIND_COMMUNE = "commune";
    private static final String INSERT_INTERACTION_SQL = """
            INSERT INTO interactions (
                campaign_id, event_id, employee_id, school_uid, participant_type,
                participant_id, channel, outcome, note, next_follow_up_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """;
    private static final String INSERT_EVENT_SQL = """
            INSERT INTO campaign_events (
                campaign_id, name, event_type, status, starts_at, ends_at, note,
                location_label, latitude, longitude, school_uid, province_code
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """;
    private static final String REGISTRATION_SELECT_SQL = """
            SELECT r.id, r.campaign_id, r.student_id, r.school_uid, r.status, r.note,
                   r.created_at, r.updated_at,
                   st.full_name student_name, st.email student_email, st.phone student_phone,
                   st.date_of_birth student_date_of_birth, st.address student_address,
                   st.grade student_grade, st.class_name student_class_name,
                   sc.province_code, sc.province_name, sc.commune_code, sc.commune_name,
                   sc.school_code, sc.school_name, sc.address school_address, sc.area_type
            FROM campaign_student_registrations r
            JOIN students st ON st.id = r.student_id
            JOIN schools sc ON sc.school_uid = r.school_uid
            """;

    private final JdbcTemplate jdbc;
    private final PasswordEncoder passwordEncoder;
    private final AdministrativeUnitRepository unitRepository;
    private final ObjectProvider<NotificationTriggerService> notificationTriggers;

    public CampaignService(JdbcTemplate jdbc, PasswordEncoder passwordEncoder,
                          AdministrativeUnitRepository unitRepository) {
        this(jdbc, passwordEncoder, unitRepository, null);
    }

    @Autowired(required = false)
    public CampaignService(JdbcTemplate jdbc, PasswordEncoder passwordEncoder,
                          AdministrativeUnitRepository unitRepository,
                          ObjectProvider<NotificationTriggerService> notificationTriggers) {
        this.jdbc = jdbc;
        this.passwordEncoder = passwordEncoder;
        this.unitRepository = unitRepository;
        this.notificationTriggers = notificationTriggers;
    }

    private long generatedId(KeyHolder keyHolder) {
        var keys = keyHolder.getKeyList();
        if (!keys.isEmpty()) {
            Object idVal = keys.get(0).get("id");
            if (idVal instanceof Number n) return n.longValue();
            if (idVal instanceof Object[] arr) return ((Number) arr[0]).longValue();
        }
        throw new IllegalStateException("Insert did not return generated id");
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
        int safeLimit = Math.clamp(limit, 1, 200);
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

    public List<SchoolCoordinatesDto> getSchoolCoordinates(String provinceCode, String communeCode) {
        List<Object> params = new ArrayList<>();
        List<String> filters = new ArrayList<>();
        
        if (provinceCode != null && !provinceCode.isBlank()) {
            filters.add("province_code = ?");
            params.add(provinceCode);
        }
        if (communeCode != null && !communeCode.isBlank()) {
            filters.add("commune_code = ?");
            params.add(communeCode);
        }
        
        String where = filters.isEmpty() ? "" : WHERE + String.join(AND, filters);
        
        return jdbc.query(
                """
                SELECT school_uid, school_name, province_name, commune_name, address,
                       latitude, longitude, geocode_status, geocode_note
                FROM schools
                %s
                ORDER BY province_name, school_name
                """.formatted(where),
                (rs, rowNum) -> mapSchoolCoordinates(rs),
                params.toArray()
        );
    }

    public SchoolCoordinatesDto getSchoolCoordinate(String schoolUid) {
        return jdbc.query(
                """
                SELECT school_uid, school_name, province_name, commune_name, address,
                       latitude, longitude, geocode_status, geocode_note
                FROM schools
                WHERE school_uid = ?
                """,
                (rs, rowNum) -> mapSchoolCoordinates(rs),
                schoolUid
        ).stream().findFirst().orElseThrow(() -> new ResourceNotFoundException("School", "schoolUid", schoolUid));
    }

    @Transactional
    public SchoolCoordinatesDto updateSchoolCoordinates(String schoolUid, Double latitude, Double longitude) {
        getSchool(schoolUid);
        
        String geocodeStatus;
        String geocodeNote;
        
        if (latitude != null && longitude != null) {
            geocodeStatus = GEOCODE_STATUS_FULL;
            geocodeNote = null;
        } else {
            geocodeStatus = GEOCODE_STATUS_PENDING;
            geocodeNote = "Chưa có tọa độ";
        }
        
        jdbc.update(
                """
                UPDATE schools
                SET latitude = ?, longitude = ?, geocode_status = ?, geocode_note = ?,
                    updated_at = CURRENT_TIMESTAMP
                WHERE school_uid = ?
                """,
                latitude, longitude, geocodeStatus, geocodeNote, schoolUid
        );
        
        return getSchoolCoordinate(schoolUid);
    }

    @Transactional
    public List<SchoolCoordinatesDto> computeApproximateCoordinates() {
        List<SchoolCoordinatesDto> results = new ArrayList<>();
        
        List<Map<String, Object>> schoolsWithoutCoords = jdbc.queryForList(
                """
                SELECT school_uid, province_code, commune_code, school_name, province_name, commune_name, address
                FROM schools
                WHERE latitude IS NULL OR longitude IS NULL
                """
        );
        
        for (Map<String, Object> school : schoolsWithoutCoords) {
            String schoolUid = (String) school.get(SCHOOL_UID_COLUMN);
            String communeCode = (String) school.get(COMMUNE_CODE_COLUMN);
            String schoolName = (String) school.get(SCHOOL_NAME_COLUMN);
            String provinceName = (String) school.get(PROVINCE_NAME_COLUMN);
            String communeName = (String) school.get(COMMUNE_NAME_COLUMN);
            String address = (String) school.get(ADDRESS_COLUMN);
            
            String geocodeStatus;
            String geocodeNote;
            Double lat = null;
            Double lng = null;
            
            if (communeCode != null && !communeCode.isBlank()) {
                var centroid = unitRepository.findCentroidByCode(communeCode, KIND_COMMUNE);
                if (centroid.isPresent()) {
                    lat = (Double) centroid.get()[1];
                    lng = (Double) centroid.get()[0];
                    geocodeStatus = GEOCODE_STATUS_APPROXIMATE;
                    geocodeNote = "Tọa độ ước lượng từ cấp xã";
                } else {
                    geocodeStatus = GEOCODE_STATUS_PENDING;
                    geocodeNote = "Không tìm thấy centroid của xã";
                }
            } else {
                geocodeStatus = GEOCODE_STATUS_PENDING;
                geocodeNote = "Thiếu thông tin xã";
            }
            
            jdbc.update(
                    """
                    UPDATE schools
                    SET latitude = ?, longitude = ?, geocode_status = ?, geocode_note = ?,
                        updated_at = CURRENT_TIMESTAMP
                    WHERE school_uid = ?
                    """,
                    lat, lng, geocodeStatus, geocodeNote, schoolUid
            );
            
            results.add(new SchoolCoordinatesDto(
                    schoolUid, schoolName, provinceName, communeName, address,
                    lat, lng, geocodeStatus, geocodeNote
            ));
        }
        
        return results;
    }

    private SchoolCoordinatesDto mapSchoolCoordinates(java.sql.ResultSet rs) throws java.sql.SQLException {
        String geocodeStatus = rs.getString("geocode_status");
        String geocodeNote = rs.getString("geocode_note");
        
        return new SchoolCoordinatesDto(
                rs.getString(SCHOOL_UID_COLUMN),
                rs.getString(SCHOOL_NAME_COLUMN),
                rs.getString(PROVINCE_NAME_COLUMN),
                rs.getString(COMMUNE_NAME_COLUMN),
                rs.getString(ADDRESS_COLUMN),
                rs.getObject("latitude", Double.class),
                rs.getObject("longitude", Double.class),
                geocodeStatus != null ? geocodeStatus : GEOCODE_STATUS_PENDING,
                geocodeNote
        );
    }

    public SchoolDetailDto getSchoolDetail(String schoolUid) {
        SchoolDto school = getSchool(schoolUid);
        List<StudentDto> students = jdbc.query(
                """
                SELECT id, school_uid, full_name, email, phone, date_of_birth, address, grade, class_name
                FROM students
                WHERE school_uid = ?
                ORDER BY full_name
                """,
                this::mapStudent,
                schoolUid
        );
        List<PersonDto> persons = jdbc.query(
                "SELECT id, school_uid, full_name, role FROM persons WHERE school_uid = ? ORDER BY full_name",
                (rs, rowNum) -> new PersonDto(
                        rs.getLong("id"),
                        rs.getString(SCHOOL_UID_COLUMN),
                        rs.getString(FULL_NAME_COLUMN),
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
                        rs.getString(SCHOOL_UID_COLUMN),
                        rs.getString(FULL_NAME_COLUMN),
                        rs.getLong(STUDENT_ID_COLUMN),
                        rs.getString("relationship"),
                        rs.getString(PHONE_COLUMN)
                ),
                schoolUid
        );
        return new SchoolDetailDto(school, students, persons, relatives);
    }

    public List<EmployeeDto> getEmployees() {
        return jdbc.query(
                """
                SELECT id, full_name, role
                FROM employees
                ORDER BY id
                """,
                this::mapEmployee
        );
    }

    public List<CampaignDto> getCampaigns(boolean includeArchived) {
        String where = includeArchived ? "" : "WHERE status <> 'ARCHIVED'";
        return jdbc.query(
                ("""
                SELECT id, name, status, objective, start_date, end_date, owner_employee_id
                FROM campaigns
                %s
                ORDER BY created_at DESC, id DESC
                """).formatted(where),
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
        validateCampaignRequest(request);
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
            ps.setObject(4, request.startDate());
            ps.setObject(5, request.endDate());
            ps.setLong(6, request.ownerEmployeeId());
            return ps;
        }, keyHolder);
        long campaignId = generatedId(keyHolder);
        CampaignDto created = getCampaign(campaignId);
        if (notificationTriggers != null) {
            notificationTriggers.ifAvailable(service -> service.campaignCreated(campaignId, created.name()));
        }
        return created;
    }

    @Transactional
    public CampaignDto updateCampaign(long id, CampaignRequest request) {
        validateCampaignRequest(request);
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
                request.startDate(),
                request.endDate(),
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
        byOutcome.put("SUCCESSFUL", 0L);
        byOutcome.put("FOLLOW_UP", 0L);
        byOutcome.put("NO_RESPONSE", 0L);
        byOutcome.put("INTERESTED", 0L);
        byOutcome.put("NOT_INTERESTED", 0L);
        jdbc.queryForList(
                "SELECT outcome, COUNT(*) as total FROM interactions WHERE campaign_id = ? GROUP BY outcome",
                campaignId
        ).forEach(row -> byOutcome.put(
                (String) row.get("outcome"),
                ((Number) row.get(TOTAL_COLUMN)).longValue()
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
                        rs.getString(PROVINCE_CODE_COLUMN),
                        rs.getString(PROVINCE_NAME_COLUMN),
                        rs.getLong(TOTAL_COLUMN)
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
                        rs.getString(SCHOOL_UID_COLUMN),
                        rs.getString(SCHOOL_NAME_COLUMN),
                        rs.getLong(TOTAL_COLUMN)
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

    public List<CampaignEventDto> getEvents(long campaignId, boolean includeArchived) {
        getCampaign(campaignId);
        String archivedFilter = includeArchived ? "" : "AND status <> 'ARCHIVED'";
        return jdbc.query(
                ("""
                SELECT id, campaign_id, name, event_type, status, starts_at, ends_at, note,
                       location_label, latitude, longitude, school_uid, province_code
                FROM campaign_events
                WHERE campaign_id = ?
                %s
                ORDER BY starts_at NULLS LAST, id
                """).formatted(archivedFilter),
                this::mapEvent,
                campaignId
        );
    }

    public CampaignEventDto getEvent(long eventId) {
        return jdbc.query(
                """
                SELECT id, campaign_id, name, event_type, status, starts_at, ends_at, note,
                       location_label, latitude, longitude, school_uid, province_code
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
        ensureSchoolIfPresent(request.schoolUid());
        KeyHolder keyHolder = new GeneratedKeyHolder();
        jdbc.update(connection -> {
            PreparedStatement ps = connection.prepareStatement(INSERT_EVENT_SQL, Statement.RETURN_GENERATED_KEYS);
            ps.setLong(1, campaignId);
            ps.setString(2, request.name());
            ps.setString(3, request.eventType());
            ps.setString(4, request.status());
            ps.setObject(5, request.startsAt());
            ps.setObject(6, request.endsAt());
            ps.setString(7, request.note());
            ps.setString(8, blankToNull(request.locationLabel()));
            ps.setObject(9, request.latitude());
            ps.setObject(10, request.longitude());
            ps.setString(11, blankToNull(request.schoolUid()));
            ps.setString(12, blankToNull(request.provinceCode()));
            return ps;
        }, keyHolder);
        long eventId = generatedId(keyHolder);
        CampaignEventDto created = getEvent(eventId);
        if (notificationTriggers != null) {
            notificationTriggers.ifAvailable(service -> service.eventCreated(eventId, created.name()));
        }
        return created;
    }

    @Transactional
    public CampaignEventDto updateEvent(long eventId, CampaignEventRequest request) {
        ensureSchoolIfPresent(request.schoolUid());
        int updated = jdbc.update(
                """
                UPDATE campaign_events
                SET name = ?, event_type = ?, status = ?, starts_at = ?, ends_at = ?,
                    note = ?, location_label = ?, latitude = ?, longitude = ?,
                    school_uid = ?, province_code = ?, updated_at = CURRENT_TIMESTAMP
                WHERE id = ?
                """,
                request.name(),
                request.eventType(),
                request.status(),
                request.startsAt(),
                request.endsAt(),
                request.note(),
                blankToNull(request.locationLabel()),
                request.latitude(),
                request.longitude(),
                blankToNull(request.schoolUid()),
                blankToNull(request.provinceCode()),
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

    public List<SchoolDto> getEventSchools(long eventId) {
        getEvent(eventId);
        return jdbc.query(
                """
                SELECT s.school_uid, s.province_code, s.province_name, s.commune_code, s.commune_name,
                       s.school_code, s.school_name, s.address, s.area_type
                FROM event_schools es
                JOIN schools s ON s.school_uid = es.school_uid
                WHERE es.event_id = ?
                ORDER BY s.province_code, s.school_name
                """,
                this::mapSchool,
                eventId
        );
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
        if (notificationTriggers != null) {
            notificationTriggers.ifAvailable(service -> service.staffAssigned(eventId, employeeId));
        }
    }

    @Transactional
    public void removeEmployee(long eventId, long employeeId) {
        jdbc.update("DELETE FROM event_assignments WHERE event_id = ? AND employee_id = ?", eventId, employeeId);
    }

    public List<EmployeeDto> getEventAssignments(long eventId) {
        getEvent(eventId);
        return jdbc.query(
                """
                SELECT e.id, e.full_name, e.role
                FROM event_assignments ea
                JOIN employees e ON e.id = ea.employee_id
                WHERE ea.event_id = ?
                ORDER BY e.id
                """,
                this::mapEmployee,
                eventId
        );
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
                    INSERT_INTERACTION_SQL,
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
            ps.setObject(10, request.nextFollowUpAt());
            return ps;
        }, keyHolder);

        long id = generatedId(keyHolder);
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

    @Transactional
    public void archiveCampaign(long id) {
        int updated = jdbc.update(
                "UPDATE campaigns SET status = 'ARCHIVED', updated_at = CURRENT_TIMESTAMP WHERE id = ?",
                id
        );
        if (updated == 0) {
            throw new ResourceNotFoundException("Campaign", "id", id);
        }
    }

    @Transactional
    public void archiveEvent(long eventId) {
        int updated = jdbc.update(
                "UPDATE campaign_events SET status = 'ARCHIVED', updated_at = CURRENT_TIMESTAMP WHERE id = ?",
                eventId
        );
        if (updated == 0) {
            throw new ResourceNotFoundException("CampaignEvent", "id", eventId);
        }
    }

    @Transactional
    public InteractionDto updateInteraction(long eventId, long interactionId, CreateInteractionRequest request, CurrentUser user) {
        InteractionDto existing = getInteractionForEvent(eventId, interactionId);
        ensureInteractionOwnerOrManager(existing, user);
        ensureEmployee(request.employeeId());
        getSchool(request.schoolUid());
        jdbc.update(
                """
                UPDATE interactions
                SET employee_id = ?, school_uid = ?, participant_type = ?, participant_id = ?,
                    channel = ?, outcome = ?, note = ?, next_follow_up_at = ?
                WHERE id = ? AND event_id = ?
                """,
                request.employeeId(),
                request.schoolUid(),
                request.participantType(),
                request.participantId(),
                request.channel(),
                request.outcome(),
                request.note(),
                request.nextFollowUpAt(),
                interactionId,
                eventId
        );
        return getInteractionForEvent(eventId, interactionId);
    }

    @Transactional
    public void deleteInteraction(long eventId, long interactionId, CurrentUser user) {
        InteractionDto existing = getInteractionForEvent(eventId, interactionId);
        ensureInteractionOwnerOrManager(existing, user);
        jdbc.update("DELETE FROM interactions WHERE id = ? AND event_id = ?", interactionId, eventId);
    }

    @Transactional
    public StudentRegistrationDto registerStudent(long campaignId, StudentRegistrationRequest request, CurrentUser currentUser) {
        CampaignDto campaign = getCampaign(campaignId);
        ensureCampaignAcceptsStudentRegistrations(campaign);
        SchoolDto school = getSchool(request.schoolUid());
        boolean authenticatedAsStudent = currentUser != null
                && "STUDENT".equals(currentUser.role())
                && currentUser.studentId() != null;
        Long studentId = authenticatedAsStudent
                ? currentUser.studentId()
                : findStudentIdByEmail(request.email());
        if (studentId == null) {
            studentId = createStudentRecord(new StudentRequest(
                    request.schoolUid(),
                    request.fullName(),
                    request.email(),
                    request.phone(),
                    request.dateOfBirth(),
                    request.address(),
                    request.grade(),
                    request.className()
            )).id();
        } else if (!authenticatedAsStudent) {
            requireMatchingStudentPassword(request.email(), request.password());
            updateStudentRecord(studentId, new StudentRequest(
                    request.schoolUid(),
                    request.fullName(),
                    request.email(),
                    request.phone(),
                    request.dateOfBirth(),
                    request.address(),
                    request.grade(),
                    request.className()
            ));
        } else {
            updateStudentRecord(studentId, new StudentRequest(
                    request.schoolUid(),
                    request.fullName(),
                    request.email(),
                    request.phone(),
                    request.dateOfBirth(),
                    request.address(),
                    request.grade(),
                    request.className()
            ));
        }

        if (!authenticatedAsStudent) {
            Long userId = findUserIdByEmail(request.email());
            if (userId == null) {
                jdbc.update(
                        """
                        INSERT INTO app_users (email, password_hash, role, status, student_id)
                        VALUES (?, ?, 'STUDENT', 'ACTIVE', ?)
                        """,
                        request.email(),
                        passwordEncoder.encode(request.password()),
                        studentId
                );
            } else {
                jdbc.update(
                        "UPDATE app_users SET student_id = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ? AND student_id IS NULL",
                        studentId,
                        userId
                );
            }
        }

        Long registrationId = findRegistrationId(campaignId, studentId);
        if (registrationId == null) {
            KeyHolder keyHolder = new GeneratedKeyHolder();
            Long finalStudentId = studentId;
            jdbc.update(connection -> {
                PreparedStatement ps = connection.prepareStatement(
                        """
                        INSERT INTO campaign_student_registrations (
                            campaign_id, student_id, school_uid, status, note
                        ) VALUES (?, ?, ?, 'PENDING', ?)
                        """,
                        Statement.RETURN_GENERATED_KEYS
                );
                ps.setLong(1, campaignId);
                ps.setLong(2, finalStudentId);
                ps.setString(3, school.schoolUid());
                ps.setString(4, request.note());
                return ps;
            }, keyHolder);
            return getRegistration(generatedId(keyHolder));
        }

        StudentRegistrationDto existing = getRegistration(registrationId);
        if (GEOCODE_STATUS_PENDING.equals(existing.status()) || APPROVED_STATUS.equals(existing.status())) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Registration already exists");
        }
        jdbc.update(
                """
                UPDATE campaign_student_registrations
                SET status = 'PENDING', school_uid = ?, note = ?, updated_at = CURRENT_TIMESTAMP
                WHERE id = ?
                """,
                school.schoolUid(),
                request.note(),
                registrationId
        );
        return getRegistration(registrationId);
    }

    public List<StudentRegistrationDto> getCampaignRegistrations(long campaignId) {
        getCampaign(campaignId);
        return jdbc.query(
                REGISTRATION_SELECT_SQL + " WHERE r.campaign_id = ? ORDER BY r.created_at DESC, r.id DESC",
                this::mapRegistration,
                campaignId
        );
    }

    public List<StudentRegistrationDto> getMyRegistrations(CurrentUser user) {
        if (user.studentId() == null) {
            return List.of();
        }
        return jdbc.query(
                REGISTRATION_SELECT_SQL + " JOIN campaigns c ON c.id = r.campaign_id " +
                        "WHERE r.student_id = ? AND c.status = 'ACTIVE' " +
                        "AND (c.end_date IS NULL OR c.end_date >= CURRENT_DATE) " +
                        "ORDER BY r.created_at DESC, r.id DESC",
                this::mapRegistration,
                user.studentId()
        );
    }

    @Transactional
    public StudentRegistrationDto updateRegistrationStatus(long id, String status, CurrentUser user) {
        ensureRegistrationManagedByUser(id, user);
        validateIn(status, GEOCODE_STATUS_PENDING, APPROVED_STATUS, "REJECTED", "CANCELLED");
        int updated = jdbc.update(
                "UPDATE campaign_student_registrations SET status = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?",
                status,
                id
        );
        if (updated == 0) {
            throw new ResourceNotFoundException("StudentRegistration", "id", id);
        }
        StudentRegistrationDto registration = getRegistration(id);
        if (notificationTriggers != null) {
            notificationTriggers.ifAvailable(service -> service.registrationStatusChanged(id, status));
        }
        return registration;
    }

    public PagedResponse<StudentRegistrationDto> listRegistrationsForStaff(
            CurrentUser user,
            Long campaignId,
            String schoolUid,
            String status,
            String query,
            int page,
            int limit
    ) {
        int safePage = Math.max(page, 0);
        int safeLimit = Math.clamp(limit, 1, 200);
        List<Object> params = new ArrayList<>();
        List<String> filters = new ArrayList<>();
        if (campaignId != null) {
            filters.add("r.campaign_id = ?");
            params.add(campaignId);
        }
        if (schoolUid != null && !schoolUid.isBlank()) {
            filters.add("r.school_uid = ?");
            params.add(schoolUid);
        }
        if (status != null && !status.isBlank()) {
            filters.add("r.status = ?");
            params.add(status);
        }
        if (query != null && !query.isBlank()) {
            filters.add("(LOWER(st.full_name) LIKE LOWER(?) OR LOWER(st.email) LIKE LOWER(?) OR LOWER(st.phone) LIKE LOWER(?))");
            String pattern = "%" + query.trim() + "%";
            params.add(pattern);
            params.add(pattern);
            params.add(pattern);
        }
        if (STAFF_ROLE.equals(user.role()) && user.employeeId() != null) {
            filters.add("""
                    (r.campaign_id IN (
                       SELECT e.campaign_id FROM event_assignments ea
                       JOIN campaign_events e ON e.id = ea.event_id
                       WHERE ea.employee_id = ?
                    ) OR r.school_uid IN (
                       SELECT es.school_uid FROM event_assignments ea
                       JOIN campaign_events e ON e.id = ea.event_id
                       JOIN event_schools es ON es.event_id = e.id
                       WHERE ea.employee_id = ?
                    ))
                    """);
            params.add(user.employeeId());
            params.add(user.employeeId());
        }
        String where = filters.isEmpty() ? "" : WHERE + String.join(AND, filters);
        Long total = jdbc.queryForObject(
                "SELECT COUNT(*) FROM campaign_student_registrations r JOIN students st ON st.id = r.student_id " + where,
                Long.class,
                params.toArray()
        );
        params.add(safeLimit);
        params.add(safePage * safeLimit);
        List<StudentRegistrationDto> items = jdbc.query(
                REGISTRATION_SELECT_SQL + " " + where + " ORDER BY r.created_at DESC, r.id DESC LIMIT ? OFFSET ?",
                this::mapRegistration,
                params.toArray()
        );
        return PagedResponse.of(items, safePage, safeLimit, total == null ? 0 : total);
    }

    @Transactional
    public int bulkUpdateRegistrationStatus(BulkRegistrationStatusRequest request, CurrentUser user) {
        validateIn(request.status(), GEOCODE_STATUS_PENDING, APPROVED_STATUS, "REJECTED", "CANCELLED");
        if (request.ids() == null || request.ids().isEmpty()) {
            return 0;
        }
        for (Long id : request.ids()) {
            ensureRegistrationManagedByUser(id, user);
        }
        String placeholders = String.join(",", Collections.nCopies(request.ids().size(), "?"));
        int updated = jdbc.update(
                "UPDATE campaign_student_registrations SET status = ?, updated_at = CURRENT_TIMESTAMP WHERE id IN (" + placeholders + ")",
                concatArgs(request.status(), request.ids())
        );
        if (updated > 0 && notificationTriggers != null) {
            notificationTriggers.ifAvailable(service -> request.ids()
                    .forEach(id -> service.registrationStatusChanged(id, request.status())));
        }
        return updated;
    }

    private Object[] concatArgs(Object first, List<Long> rest) {
        Object[] arr = new Object[rest.size() + 1];
        arr[0] = first;
        for (int i = 0; i < rest.size(); i++) {
            arr[i + 1] = rest.get(i);
        }
        return arr;
    }

    public PagedResponse<StudentDto> getStudents(int page, int limit, String schoolUid, String query) {
        int safePage = Math.max(page, 0);
        int safeLimit = Math.clamp(limit, 1, 200);
        List<Object> params = new ArrayList<>();
        List<String> filters = new ArrayList<>();
        if (schoolUid != null && !schoolUid.isBlank()) {
            filters.add("school_uid = ?");
            params.add(schoolUid);
        }
        if (query != null && !query.isBlank()) {
            filters.add("(LOWER(full_name) LIKE LOWER(?) OR LOWER(email) LIKE LOWER(?))");
            String pattern = "%" + query.trim() + "%";
            params.add(pattern);
            params.add(pattern);
        }
        String where = filters.isEmpty() ? "" : WHERE + String.join(AND, filters);
        Long total = jdbc.queryForObject("SELECT COUNT(*) FROM students " + where, Long.class, params.toArray());
        params.add(safeLimit);
        params.add(safePage * safeLimit);
        List<StudentDto> items = jdbc.query(
                ("""
                SELECT id, school_uid, full_name, email, phone, date_of_birth, address, grade, class_name
                FROM students
                %s
                ORDER BY full_name
                LIMIT ? OFFSET ?
                """).formatted(where),
                this::mapStudent,
                params.toArray()
        );
        return PagedResponse.of(items, safePage, safeLimit, total == null ? 0 : total);
    }

    @Transactional
    public StudentDto createStudent(StudentRequest request) {
        return createStudentRecord(request);
    }

    private StudentDto createStudentRecord(StudentRequest request) {
        getSchool(request.schoolUid());
        KeyHolder keyHolder = new GeneratedKeyHolder();
        jdbc.update(connection -> {
            PreparedStatement ps = connection.prepareStatement(
                    """
                    INSERT INTO students (
                        school_uid, full_name, email, phone, date_of_birth, address, grade, class_name
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                    """,
                    Statement.RETURN_GENERATED_KEYS
            );
            setStudentRequest(ps, request);
            return ps;
        }, keyHolder);
        return getStudent(generatedId(keyHolder));
    }

    @Transactional
    public StudentDto updateStudent(long id, StudentRequest request) {
        return updateStudentRecord(id, request);
    }

    private StudentDto updateStudentRecord(long id, StudentRequest request) {
        getSchool(request.schoolUid());
        int updated = jdbc.update(
                """
                UPDATE students
                SET school_uid = ?, full_name = ?, email = ?, phone = ?, date_of_birth = ?,
                    address = ?, grade = ?, class_name = ?
                WHERE id = ?
                """,
                request.schoolUid(),
                request.fullName(),
                blankToNull(request.email()),
                request.phone(),
                request.dateOfBirth(),
                request.address(),
                request.grade(),
                request.className(),
                id
        );
        if (updated == 0) {
            throw new ResourceNotFoundException("Student", "id", id);
        }
        return getStudent(id);
    }

    @Transactional
    public void deleteStudent(long id) {
        int updated = jdbc.update("DELETE FROM students WHERE id = ?", id);
        if (updated == 0) {
            throw new ResourceNotFoundException("Student", "id", id);
        }
    }

    public List<PersonDto> getPersons(String schoolUid) {
        return jdbc.query(
                """
                SELECT id, school_uid, full_name, role
                FROM persons
                WHERE (? IS NULL OR school_uid = ?)
                ORDER BY full_name
                """,
                this::mapPerson,
                schoolUid,
                schoolUid
        );
    }

    @Transactional
    public PersonDto createPerson(PersonRequest request) {
        getSchool(request.schoolUid());
        KeyHolder keyHolder = new GeneratedKeyHolder();
        jdbc.update(connection -> {
            PreparedStatement ps = connection.prepareStatement(
                    "INSERT INTO persons (school_uid, full_name, role) VALUES (?, ?, ?)",
                    Statement.RETURN_GENERATED_KEYS
            );
            ps.setString(1, request.schoolUid());
            ps.setString(2, request.fullName());
            ps.setString(3, request.role());
            return ps;
        }, keyHolder);
        return getPerson(generatedId(keyHolder));
    }

    @Transactional
    public PersonDto updatePerson(long id, PersonRequest request) {
        getSchool(request.schoolUid());
        int updated = jdbc.update(
                "UPDATE persons SET school_uid = ?, full_name = ?, role = ? WHERE id = ?",
                request.schoolUid(),
                request.fullName(),
                request.role(),
                id
        );
        if (updated == 0) {
            throw new ResourceNotFoundException("Person", "id", id);
        }
        return getPerson(id);
    }

    @Transactional
    public void deletePerson(long id) {
        int updated = jdbc.update("DELETE FROM persons WHERE id = ?", id);
        if (updated == 0) {
            throw new ResourceNotFoundException("Person", "id", id);
        }
    }

    public List<StudentRelativeDto> getRelatives(String schoolUid, Long studentId) {
        return jdbc.query(
                """
                SELECT id, school_uid, full_name, student_id, relationship, phone
                FROM student_relatives
                WHERE (? IS NULL OR school_uid = ?) AND (? IS NULL OR student_id = ?)
                ORDER BY full_name
                """,
                this::mapRelative,
                schoolUid,
                schoolUid,
                studentId,
                studentId
        );
    }

    @Transactional
    public StudentRelativeDto createRelative(StudentRelativeRequest request) {
        getStudent(request.studentId());
        getSchool(request.schoolUid());
        KeyHolder keyHolder = new GeneratedKeyHolder();
        jdbc.update(connection -> {
            PreparedStatement ps = connection.prepareStatement(
                    """
                    INSERT INTO student_relatives (student_id, school_uid, full_name, relationship, phone)
                    VALUES (?, ?, ?, ?, ?)
                    """,
                    Statement.RETURN_GENERATED_KEYS
            );
            ps.setLong(1, request.studentId());
            ps.setString(2, request.schoolUid());
            ps.setString(3, request.fullName());
            ps.setString(4, request.relationship());
            ps.setString(5, request.phone());
            return ps;
        }, keyHolder);
        return getRelative(generatedId(keyHolder));
    }

    @Transactional
    public StudentRelativeDto updateRelative(long id, StudentRelativeRequest request) {
        getStudent(request.studentId());
        getSchool(request.schoolUid());
        int updated = jdbc.update(
                """
                UPDATE student_relatives
                SET student_id = ?, school_uid = ?, full_name = ?, relationship = ?, phone = ?
                WHERE id = ?
                """,
                request.studentId(),
                request.schoolUid(),
                request.fullName(),
                request.relationship(),
                request.phone(),
                id
        );
        if (updated == 0) {
            throw new ResourceNotFoundException("StudentRelative", "id", id);
        }
        return getRelative(id);
    }

    @Transactional
    public void deleteRelative(long id) {
        int updated = jdbc.update("DELETE FROM student_relatives WHERE id = ?", id);
        if (updated == 0) {
            throw new ResourceNotFoundException("StudentRelative", "id", id);
        }
    }

    public List<UserDto> getUsers() {
        return jdbc.query(
                "SELECT id, email, role, status, employee_id, student_id, firebase_uid FROM app_users ORDER BY id",
                this::mapUser
        );
    }

    @Transactional
    public UserDto createUser(UserRequest request) {
        validateRole(request.role());
        requirePasswordForCreate(request.password());
        KeyHolder keyHolder = new GeneratedKeyHolder();
        jdbc.update(connection -> {
            PreparedStatement ps = connection.prepareStatement(
                    """
                    INSERT INTO app_users (email, password_hash, role, status, employee_id, student_id)
                    VALUES (?, ?, ?, ?, ?, ?)
                    """,
                    Statement.RETURN_GENERATED_KEYS
            );
            ps.setString(1, request.email());
            ps.setString(2, passwordEncoder.encode(request.password()));
            ps.setString(3, request.role());
            ps.setString(4, normalizeUserStatus(request.status()));
            ps.setObject(5, request.employeeId());
            ps.setObject(6, request.studentId());
            return ps;
        }, keyHolder);
        return getUser(generatedId(keyHolder));
    }

    @Transactional
    public UserDto updateUser(long id, UserRequest request) {
        validateRole(request.role());
        int updated = jdbc.update(
                """
                UPDATE app_users
                SET email = ?, password_hash = COALESCE(?, password_hash), role = ?, status = ?, employee_id = ?,
                    student_id = ?, updated_at = CURRENT_TIMESTAMP
                WHERE id = ?
                """,
                request.email(),
                request.password() == null || request.password().isBlank()
                        ? null
                        : passwordEncoder.encode(request.password()),
                request.role(),
                normalizeUserStatus(request.status()),
                request.employeeId(),
                request.studentId(),
                id
        );
        if (updated == 0) {
            throw new ResourceNotFoundException("User", "id", id);
        }
        return getUser(id);
    }

    @Transactional
    public UserDto updateUserRole(long id, String role) {
        validateRole(role);
        return updateUserColumn(id, "role", role);
    }

    @Transactional
    public UserDto updateUserStatus(long id, String status) {
        validateIn(status, ACTIVE_STATUS, DISABLED_STATUS);
        UserDto updated = updateUserColumn(id, STATUS_COLUMN, status);
        if (DISABLED_STATUS.equals(status) && notificationTriggers != null) {
            notificationTriggers.ifAvailable(service -> service.accountDeactivated(id));
        }
        return updated;
    }

    @Transactional
    public void deleteUser(long id) {
        int updated = jdbc.update("DELETE FROM app_users WHERE id = ?", id);
        if (updated == 0) {
            throw new ResourceNotFoundException("User", "id", id);
        }
    }

    @Transactional
    public EmployeeDto createEmployee(EmployeeDto request) {
        KeyHolder keyHolder = new GeneratedKeyHolder();
        jdbc.update(connection -> {
            PreparedStatement ps = connection.prepareStatement(
                    "INSERT INTO employees (full_name, role) VALUES (?, ?)",
                    Statement.RETURN_GENERATED_KEYS
            );
            ps.setString(1, request.fullName());
            ps.setString(2, request.role());
            return ps;
        }, keyHolder);
        return getEmployee(generatedId(keyHolder));
    }

    @Transactional
    public EmployeeDto updateEmployee(long id, EmployeeDto request) {
        int updated = jdbc.update(
                "UPDATE employees SET full_name = ?, role = ? WHERE id = ?",
                request.fullName(),
                request.role(),
                id
        );
        if (updated == 0) {
            throw new ResourceNotFoundException("Employee", "id", id);
        }
        return getEmployee(id);
    }

    @Transactional
    public void deleteEmployee(long id) {
        int updated = jdbc.update("DELETE FROM employees WHERE id = ?", id);
        if (updated == 0) {
            throw new ResourceNotFoundException("Employee", "id", id);
        }
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
        return filters.isEmpty() ? "" : WHERE + String.join(AND, filters);
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

    private StudentDto getStudent(long id) {
        return jdbc.query(
                """
                SELECT id, school_uid, full_name, email, phone, date_of_birth, address, grade, class_name
                FROM students
                WHERE id = ?
                """,
                this::mapStudent,
                id
        ).stream().findFirst().orElseThrow(() -> new ResourceNotFoundException("Student", "id", id));
    }

    private PersonDto getPerson(long id) {
        return jdbc.query(
                "SELECT id, school_uid, full_name, role FROM persons WHERE id = ?",
                this::mapPerson,
                id
        ).stream().findFirst().orElseThrow(() -> new ResourceNotFoundException("Person", "id", id));
    }

    private StudentRelativeDto getRelative(long id) {
        return jdbc.query(
                "SELECT id, school_uid, full_name, student_id, relationship, phone FROM student_relatives WHERE id = ?",
                this::mapRelative,
                id
        ).stream().findFirst().orElseThrow(() -> new ResourceNotFoundException("StudentRelative", "id", id));
    }

    private EmployeeDto getEmployee(long id) {
        return jdbc.query(
                "SELECT id, full_name, role FROM employees WHERE id = ?",
                this::mapEmployee,
                id
        ).stream().findFirst().orElseThrow(() -> new ResourceNotFoundException("Employee", "id", id));
    }

    private UserDto getUser(long id) {
        return jdbc.query(
                "SELECT id, email, role, status, employee_id, student_id, firebase_uid FROM app_users WHERE id = ?",
                this::mapUser,
                id
        ).stream().findFirst().orElseThrow(() -> new ResourceNotFoundException("User", "id", id));
    }

    private StudentRegistrationDto getRegistration(long id) {
        return jdbc.query(
                REGISTRATION_SELECT_SQL + " WHERE r.id = ?",
                this::mapRegistration,
                id
        ).stream().findFirst().orElseThrow(() -> new ResourceNotFoundException("StudentRegistration", "id", id));
    }

    private InteractionDto getInteractionForEvent(long eventId, long interactionId) {
        return jdbc.query(
                """
                SELECT id, campaign_id, event_id, employee_id, school_uid, participant_type,
                       participant_id, channel, outcome, note, next_follow_up_at, created_at
                FROM interactions
                WHERE event_id = ? AND id = ?
                """,
                this::mapInteraction,
                eventId,
                interactionId
        ).stream().findFirst().orElseThrow(() -> new ResourceNotFoundException("Interaction", "id", interactionId));
    }

    private Long findStudentIdByEmail(String email) {
        return jdbc.query(
                "SELECT id FROM students WHERE LOWER(email) = LOWER(?)",
                (rs, rowNum) -> rs.getLong("id"),
                email
        ).stream().findFirst().orElse(null);
    }

    private Long findUserIdByEmail(String email) {
        return jdbc.query(
                "SELECT id FROM app_users WHERE LOWER(email) = LOWER(?)",
                (rs, rowNum) -> rs.getLong("id"),
                email
        ).stream().findFirst().orElse(null);
    }

    private Long findRegistrationId(long campaignId, long studentId) {
        return jdbc.query(
                "SELECT id FROM campaign_student_registrations WHERE campaign_id = ? AND student_id = ?",
                (rs, rowNum) -> rs.getLong("id"),
                campaignId,
                studentId
        ).stream().findFirst().orElse(null);
    }

    private void requireMatchingStudentPassword(String email, String password) {
        String hash = jdbc.query(
                "SELECT password_hash FROM app_users WHERE LOWER(email) = LOWER(?)",
                (rs, rowNum) -> rs.getString("password_hash"),
                email
        ).stream().findFirst().orElse(null);
        if (hash != null && !passwordEncoder.matches(password, hash)) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Email or password is incorrect");
        }
    }

    private void setStudentRequest(PreparedStatement ps, StudentRequest request) throws java.sql.SQLException {
        ps.setString(1, request.schoolUid());
        ps.setString(2, request.fullName());
        ps.setString(3, blankToNull(request.email()));
        ps.setString(4, request.phone());
        ps.setObject(5, request.dateOfBirth());
        ps.setString(6, request.address());
        ps.setString(7, request.grade());
        ps.setString(8, request.className());
    }

    private String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value;
    }

    private void ensureInteractionOwnerOrManager(InteractionDto interaction, CurrentUser user) {
        if (MANAGER_ROLE.equals(user.role()) || ADMIN_ROLE.equals(user.role())) {
            return;
        }
        if (user.employeeId() == null || !user.employeeId().equals(interaction.employeeId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Forbidden");
        }
    }

    private String normalizeUserStatus(String status) {
        String value = status == null || status.isBlank() ? ACTIVE_STATUS : status;
        validateIn(value, ACTIVE_STATUS, DISABLED_STATUS);
        return value;
    }

    private void requirePasswordForCreate(String password) {
        if (password == null || password.isBlank() || password.length() < 8) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Password must be at least 8 characters");
        }
    }
    private void validateCampaignRequest(CampaignRequest request) {
        validateIn(request.status(), "DRAFT", ACTIVE_STATUS, "COMPLETED", "ARCHIVED");
        if (request.startDate() != null && request.endDate() != null && request.endDate().isBefore(request.startDate())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Campaign end date must not be before start date");
        }
    }

    private void ensureCampaignAcceptsStudentRegistrations(CampaignDto campaign) {
        if (!ACTIVE_STATUS.equals(campaign.status())) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Campaign is not accepting registrations");
        }
        LocalDate today = LocalDate.now(VIETNAM_ZONE);
        if (campaign.startDate() != null && campaign.startDate().isAfter(today)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Campaign registration has not opened");
        }
        if (campaign.endDate() != null && campaign.endDate().isBefore(today)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Campaign registration has closed");
        }
    }

    private void ensureRegistrationManagedByUser(long registrationId, CurrentUser user) {
        if (user == null) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Forbidden");
        }
        if (MANAGER_ROLE.equals(user.role()) || ADMIN_ROLE.equals(user.role())) {
            return;
        }
        if (!STAFF_ROLE.equals(user.role()) || user.employeeId() == null) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Forbidden");
        }
        Integer count = jdbc.queryForObject("""
                SELECT COUNT(*)
                FROM campaign_student_registrations r
                WHERE r.id = ?
                  AND (r.campaign_id IN (
                         SELECT e.campaign_id FROM event_assignments ea
                         JOIN campaign_events e ON e.id = ea.event_id
                         WHERE ea.employee_id = ?
                      ) OR r.school_uid IN (
                         SELECT es.school_uid FROM event_assignments ea
                         JOIN campaign_events e ON e.id = ea.event_id
                         JOIN event_schools es ON es.event_id = e.id
                         WHERE ea.employee_id = ?
                      ))
                """, Integer.class, registrationId, user.employeeId(), user.employeeId());
        if (count == null || count == 0) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Forbidden");
        }
    }
    private void validateRole(String role) {
        validateIn(role, ADMIN_ROLE, MANAGER_ROLE, STAFF_ROLE, "STUDENT");
    }

    private void validateIn(String value, String... allowed) {
        for (String item : allowed) {
            if (item.equals(value)) {
                return;
            }
        }
        throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid value: " + value);
    }

    private UserDto updateUserColumn(long id, String column, String value) {
        int updated = jdbc.update(
                "UPDATE app_users SET " + column + " = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?",
                value,
                id
        );
        if (updated == 0) {
            throw new ResourceNotFoundException("User", "id", id);
        }
        return getUser(id);
    }

    private void ensureEmployee(long employeeId) {
        Integer count = jdbc.queryForObject("SELECT COUNT(*) FROM employees WHERE id = ?", Integer.class, employeeId);
        if (count == null || count == 0) {
            throw new ResourceNotFoundException("Employee", "id", employeeId);
        }
    }

    private void ensureSchoolIfPresent(String schoolUid) {
        if (schoolUid == null || schoolUid.isBlank()) {
            return;
        }
        getSchool(schoolUid);
    }

    private long zero(Long value) {
        return value == null ? 0 : value;
    }

    private SchoolDto mapSchool(java.sql.ResultSet rs, int rowNum) throws java.sql.SQLException {
        return new SchoolDto(
                rs.getString(SCHOOL_UID_COLUMN),
                rs.getString(PROVINCE_CODE_COLUMN),
                rs.getString(PROVINCE_NAME_COLUMN),
                rs.getString(COMMUNE_CODE_COLUMN),
                rs.getString(COMMUNE_NAME_COLUMN),
                rs.getString("school_code"),
                rs.getString(SCHOOL_NAME_COLUMN),
                rs.getString(ADDRESS_COLUMN),
                rs.getString("area_type")
        );
    }

    private StudentDto mapStudent(java.sql.ResultSet rs, int rowNum) throws java.sql.SQLException {
        return new StudentDto(
                rs.getLong("id"),
                rs.getString(SCHOOL_UID_COLUMN),
                rs.getString(FULL_NAME_COLUMN),
                rs.getString("email"),
                rs.getString(PHONE_COLUMN),
                rs.getObject("date_of_birth", LocalDate.class),
                rs.getString(ADDRESS_COLUMN),
                rs.getString("grade"),
                rs.getString("class_name")
        );
    }

    private PersonDto mapPerson(java.sql.ResultSet rs, int rowNum) throws java.sql.SQLException {
        return new PersonDto(
                rs.getLong("id"),
                rs.getString(SCHOOL_UID_COLUMN),
                rs.getString(FULL_NAME_COLUMN),
                rs.getString("role")
        );
    }

    private StudentRelativeDto mapRelative(java.sql.ResultSet rs, int rowNum) throws java.sql.SQLException {
        return new StudentRelativeDto(
                rs.getLong("id"),
                rs.getString(SCHOOL_UID_COLUMN),
                rs.getString(FULL_NAME_COLUMN),
                rs.getLong(STUDENT_ID_COLUMN),
                rs.getString("relationship"),
                rs.getString(PHONE_COLUMN)
        );
    }

    private UserDto mapUser(java.sql.ResultSet rs, int rowNum) throws java.sql.SQLException {
        return new UserDto(
                rs.getLong("id"),
                rs.getString("email"),
                rs.getString("role"),
                rs.getString(STATUS_COLUMN),
                rs.getObject("employee_id", Long.class),
                rs.getObject(STUDENT_ID_COLUMN, Long.class),
                rs.getString("firebase_uid")
        );
    }

    private StudentRegistrationDto mapRegistration(java.sql.ResultSet rs, int rowNum) throws java.sql.SQLException {
        StudentDto student = new StudentDto(
                rs.getLong(STUDENT_ID_COLUMN),
                rs.getString(SCHOOL_UID_COLUMN),
                rs.getString("student_name"),
                rs.getString("student_email"),
                rs.getString("student_phone"),
                rs.getObject("student_date_of_birth", LocalDate.class),
                rs.getString("student_address"),
                rs.getString("student_grade"),
                rs.getString("student_class_name")
        );
        SchoolDto school = new SchoolDto(
                rs.getString(SCHOOL_UID_COLUMN),
                rs.getString(PROVINCE_CODE_COLUMN),
                rs.getString(PROVINCE_NAME_COLUMN),
                rs.getString(COMMUNE_CODE_COLUMN),
                rs.getString(COMMUNE_NAME_COLUMN),
                rs.getString("school_code"),
                rs.getString(SCHOOL_NAME_COLUMN),
                rs.getString("school_address"),
                rs.getString("area_type")
        );
        return new StudentRegistrationDto(
                rs.getLong("id"),
                rs.getLong(CAMPAIGN_ID_COLUMN),
                rs.getLong(STUDENT_ID_COLUMN),
                rs.getString(SCHOOL_UID_COLUMN),
                rs.getString(STATUS_COLUMN),
                rs.getString("note"),
                rs.getObject("created_at", LocalDateTime.class),
                rs.getObject("updated_at", LocalDateTime.class),
                student,
                school
        );
    }

    private CampaignDto mapCampaign(java.sql.ResultSet rs, int rowNum) throws java.sql.SQLException {
        LocalDate startDate = rs.getObject("start_date", LocalDate.class);
        LocalDate endDate = rs.getObject("end_date", LocalDate.class);
        return new CampaignDto(
                rs.getLong("id"),
                rs.getString("name"),
                rs.getString(STATUS_COLUMN),
                rs.getString("objective"),
                startDate,
                endDate,
                rs.getObject("owner_employee_id", Long.class)
        );
    }

    private EmployeeDto mapEmployee(java.sql.ResultSet rs, int rowNum) throws java.sql.SQLException {
        return new EmployeeDto(
                rs.getLong("id"),
                rs.getString(FULL_NAME_COLUMN),
                rs.getString("role")
        );
    }

    private CampaignEventDto mapEvent(java.sql.ResultSet rs, int rowNum) throws java.sql.SQLException {
        LocalDateTime startsAt = rs.getObject("starts_at", LocalDateTime.class);
        LocalDateTime endsAt = rs.getObject("ends_at", LocalDateTime.class);
        return new CampaignEventDto(
                rs.getLong("id"),
                rs.getLong(CAMPAIGN_ID_COLUMN),
                rs.getString("name"),
                rs.getString("event_type"),
                rs.getString(STATUS_COLUMN),
                startsAt,
                endsAt,
                rs.getString("note"),
                rs.getString("location_label"),
                rs.getObject("latitude", Double.class),
                rs.getObject("longitude", Double.class),
                rs.getString(SCHOOL_UID_COLUMN),
                rs.getString(PROVINCE_CODE_COLUMN)
        );
    }

    private InteractionDto mapInteraction(java.sql.ResultSet rs, int rowNum) throws java.sql.SQLException {
        LocalDateTime nextFollowUpAt = rs.getObject("next_follow_up_at", LocalDateTime.class);
        LocalDateTime createdAt = rs.getObject("created_at", LocalDateTime.class);
        return new InteractionDto(
                rs.getLong("id"),
                rs.getLong(CAMPAIGN_ID_COLUMN),
                rs.getLong("event_id"),
                rs.getLong("employee_id"),
                rs.getString(SCHOOL_UID_COLUMN),
                rs.getString("participant_type"),
                rs.getLong("participant_id"),
                rs.getString("channel"),
                rs.getString("outcome"),
                rs.getString("note"),
                nextFollowUpAt,
                createdAt
        );
    }
}




