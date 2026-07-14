package com.vnmap.campaign.service;

import com.vnmap.campaign.dto.*;
import com.vnmap.common.exception.ResourceNotFoundException;
import com.vnmap.common.security.CurrentUser;
import com.vnmap.geo.repository.AdministrativeUnitRepository;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.DriverManagerDataSource;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.server.ResponseStatusException;

import java.sql.DriverManager;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.Month;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.junit.jupiter.api.Assumptions.assumeTrue;

class CampaignServiceDatabaseTest {

    private static final String JDBC_URL = System.getenv().getOrDefault(
            "CAMPAIGN_TEST_JDBC_URL",
            "jdbc:postgresql://vnmap_postgres:5432/vnmapdb"
    );
    private static final String JDBC_USER = System.getenv().getOrDefault("CAMPAIGN_TEST_DB_USER", "postgres");
    private static final String JDBC_PASSWORD = System.getenv().getOrDefault("CAMPAIGN_TEST_DB_PASSWORD", "123456");

    private JdbcTemplate jdbc;
    private CampaignService service;
    private String runId;
    private String schoolUid;
    private String secondSchoolUid;

    @BeforeEach
    void setUp() {
        assumeTrue(databaseAvailable(), "Campaign compose database is not reachable");
        DriverManagerDataSource dataSource = new DriverManagerDataSource(JDBC_URL, JDBC_USER, JDBC_PASSWORD);
        jdbc = new JdbcTemplate(dataSource);
        PasswordEncoder passwordEncoder = new BCryptPasswordEncoder();
        AdministrativeUnitRepository unitRepository = null; // Not needed for most tests
        service = new CampaignService(jdbc, passwordEncoder, unitRepository);
        runId = "codex_cov_" + UUID.randomUUID().toString().replace("-", "").substring(0, 12);
        schoolUid = "99-" + runId.substring(runId.length() - 6);
        secondSchoolUid = "98-" + runId.substring(runId.length() - 6);
        cleanup();
        insertSchool(schoolUid, "99", "99901", "Coverage High School");
        insertSchool(secondSchoolUid, "98", "99801", "Coverage Second School");
    }

    @AfterEach
    void tearDown() {
        if (jdbc != null && runId != null) {
            cleanup();
        }
    }

    @Test
    void coversCampaignEventRegistrationInteractionAndCrudFlows() {
        EmployeeDto manager = service.createEmployee(new EmployeeDto(null, runId + " Manager", "MANAGER"));
        EmployeeDto staff = service.createEmployee(new EmployeeDto(null, runId + " Staff", "STAFF"));
        assertThat(service.getEmployees()).extracting(EmployeeDto::id).contains(manager.id(), staff.id());

        CampaignDto campaign = service.createCampaign(new CampaignRequest(
                runId + " Campaign",
                "ACTIVE",
                "Coverage objective",
                LocalDate.of(2026, Month.JUNE, 1),
                LocalDate.of(2026, Month.JULY, 31),
                manager.id()
        ));
        CampaignDto updatedCampaign = service.updateCampaign(
                campaign.id(),
                new CampaignRequest(
                        runId + " Campaign Updated",
                        "ACTIVE",
                        "Updated objective",
                        LocalDate.of(2026, Month.JUNE, 2),
                        LocalDate.of(2026, Month.AUGUST, 1),
                        manager.id()
                )
        );
        assertThat(updatedCampaign.name()).endsWith("Updated");
        assertThat(service.getCampaigns(false)).extracting(CampaignDto::id).contains(campaign.id());
        assertThat(service.getCampaign(campaign.id()).objective()).isEqualTo("Updated objective");

        CampaignEventDto event = service.createEvent(
                campaign.id(),
                new CampaignEventRequest(
                        runId + " Event",
                        "SCHOOL_VISIT",
                        "PLANNED",
                        LocalDateTime.of(2026, Month.JUNE, 20, 8, 0),
                        LocalDateTime.of(2026, Month.JUNE, 20, 11, 0),
                        "Initial note",
                        null, null, null, null, null
                )
        );
        CampaignEventDto updatedEvent = service.updateEvent(
                event.id(),
                new CampaignEventRequest(
                        runId + " Event Updated",
                        "SCHOOL_VISIT",
                        "DONE",
                        LocalDateTime.of(2026, Month.JUNE, 20, 9, 0),
                        LocalDateTime.of(2026, Month.JUNE, 20, 12, 0),
                        "Updated note",
                        "THPT A, Coverage Province", 21.0285, 105.8542, schoolUid, "99"
                )
        );
        assertThat(updatedEvent.status()).isEqualTo("DONE");
        assertThat(updatedEvent.locationLabel()).isEqualTo("THPT A, Coverage Province");
        assertThat(updatedEvent.latitude()).isEqualTo(21.0285);
        assertThat(updatedEvent.longitude()).isEqualTo(105.8542);
        assertThat(updatedEvent.schoolUid()).isEqualTo(schoolUid);
        assertThat(updatedEvent.provinceCode()).isEqualTo("99");
        assertThat(service.getEvents(campaign.id(), false)).extracting(CampaignEventDto::id).contains(event.id());
        assertThat(service.getEvent(event.id()).name()).contains("Updated");
        assertThat(service.getEvent(event.id()).latitude()).isEqualTo(21.0285);

        assertThat(service.getSchools(-5, 999, "99", null, "KV3", "Coverage").items())
                .extracting(SchoolDto::schoolUid)
                .contains(schoolUid);
        SchoolDetailDto initialDetail = service.getSchoolDetail(schoolUid);
        assertThat(initialDetail.school().schoolName()).contains("Coverage");

        service.assignSchool(event.id(), schoolUid);
        service.assignSchool(event.id(), secondSchoolUid);
        assertThat(service.getEventSchools(event.id())).extracting(SchoolDto::schoolUid)
                .contains(schoolUid, secondSchoolUid);
        service.removeSchool(event.id(), secondSchoolUid);
        assertThat(service.getEventSchools(event.id())).extracting(SchoolDto::schoolUid)
                .contains(schoolUid)
                .doesNotContain(secondSchoolUid);

        service.assignEmployee(event.id(), manager.id());
        service.assignEmployee(event.id(), staff.id());
        assertThat(service.getEventAssignments(event.id())).extracting(EmployeeDto::id)
                .contains(manager.id(), staff.id());
        service.removeEmployee(event.id(), staff.id());
        assertThat(service.getEventAssignments(event.id())).extracting(EmployeeDto::id)
                .contains(manager.id())
                .doesNotContain(staff.id());

        StudentRegistrationRequest registrationRequest = new StudentRegistrationRequest(
                schoolUid,
                runId + " Student",
                runId + "@student.local",
                "0900000000",
                "password123",
                "12",
                "12A1",
                LocalDate.of(2008, Month.JANUARY, 2),
                "Coverage address",
                "Interested"
        );
        StudentRegistrationDto registration = service.registerStudent(campaign.id(), registrationRequest, null);
        assertThat(registration.status()).isEqualTo("PENDING");
        assertThat(service.getCampaignRegistrations(campaign.id())).extracting(StudentRegistrationDto::id)
                .contains(registration.id());
        assertThat(service.getMyRegistrations(new CurrentUser(9L, runId + "@student.local", "STUDENT", "ACTIVE", null, registration.studentId())))
                .extracting(StudentRegistrationDto::id)
                .contains(registration.id());
        assertThat(service.updateRegistrationStatus(registration.id(), "APPROVED", new CurrentUser(1L, "admin@test.local", "ADMIN", "ACTIVE", null, null)).status()).isEqualTo("APPROVED");
        assertThatThrownBy(() -> service.registerStudent(campaign.id(), registrationRequest, null))
                .isInstanceOf(ResponseStatusException.class)
                .hasMessageContaining("Registration already exists");

        service.updateRegistrationStatus(registration.id(), "REJECTED", new CurrentUser(1L, "admin@test.local", "ADMIN", "ACTIVE", null, null));
        StudentRegistrationDto reopened = service.registerStudent(campaign.id(), registrationRequest, null);
        assertThat(reopened.status()).isEqualTo("PENDING");
        StudentRegistrationRequest wrongPassword = new StudentRegistrationRequest(
                schoolUid,
                runId + " Student",
                runId + "@student.local",
                "0900000000",
                "badpassword",
                "12",
                "12A1",
                LocalDate.of(2008, Month.JANUARY, 2),
                "Coverage address",
                "Interested"
        );
        assertThatThrownBy(() -> service.registerStudent(campaign.id(), wrongPassword, null))
                .isInstanceOf(ResponseStatusException.class)
                .hasMessageContaining("Email or password is incorrect");

        InteractionDto interaction = service.createInteraction(
                event.id(),
                new CreateInteractionRequest(
                        manager.id(),
                        schoolUid,
                        "STUDENT",
                        registration.studentId(),
                        "MEETING",
                        "INTERESTED",
                        "Coverage note",
                        LocalDateTime.of(2026, Month.JUNE, 25, 9, 0)
                )
        );
        assertThat(service.getInteractions(event.id())).extracting(InteractionDto::id).contains(interaction.id());
        assertThat(service.getDashboard(campaign.id()).interactionsByOutcome().get("INTERESTED")).isGreaterThanOrEqualTo(1);

        InteractionDto updatedInteraction = service.updateInteraction(
                event.id(),
                interaction.id(),
                new CreateInteractionRequest(
                        manager.id(),
                        schoolUid,
                        "STUDENT",
                        registration.studentId(),
                        "PHONE",
                        "FOLLOW_UP",
                        "Updated coverage note",
                        LocalDateTime.of(2026, Month.JUNE, 26, 9, 0)
                ),
                new CurrentUser(2L, "manager@vnmap.local", "MANAGER", "ACTIVE", manager.id(), null)
        );
        assertThat(updatedInteraction.outcome()).isEqualTo("FOLLOW_UP");
        assertThatThrownBy(() -> service.deleteInteraction(
                event.id(),
                interaction.id(),
                new CurrentUser(3L, "other@vnmap.local", "STAFF", "ACTIVE", 999999L, null)
        )).isInstanceOf(ResponseStatusException.class)
                .hasMessageContaining("Forbidden");
        service.deleteInteraction(
                event.id(),
                interaction.id(),
                new CurrentUser(2L, "manager@vnmap.local", "MANAGER", "ACTIVE", manager.id(), null)
        );

        StudentDto manualStudent = service.createStudent(new StudentRequest(
                schoolUid,
                runId + " Manual Student",
                runId + "_manual@student.local",
                "091",
                LocalDate.of(2007, Month.MARCH, 4),
                "Manual address",
                "11",
                "11A1"
        ));
        assertThat(service.updateStudent(manualStudent.id(), new StudentRequest(
                secondSchoolUid,
                runId + " Manual Student Updated",
                runId + "_manual@student.local",
                "092",
                LocalDate.of(2007, Month.MARCH, 4),
                "Manual updated",
                "12",
                "12A2"
        )).schoolUid()).isEqualTo(secondSchoolUid);
        assertThat(service.getStudents(0, 20, secondSchoolUid, "Manual").items())
                .extracting(StudentDto::id)
                .contains(manualStudent.id());

        PersonDto person = service.createPerson(new PersonRequest(schoolUid, runId + " Teacher", "TEACHER"));
        assertThat(service.getPersons(schoolUid)).extracting(PersonDto::id).contains(person.id());
        assertThat(service.updatePerson(person.id(), new PersonRequest(schoolUid, runId + " Principal", "PRINCIPAL")).role())
                .isEqualTo("PRINCIPAL");

        StudentRelativeDto relative = service.createRelative(new StudentRelativeRequest(
                manualStudent.id(),
                secondSchoolUid,
                runId + " Parent",
                "PARENT",
                "093"
        ));
        assertThat(service.getRelatives(secondSchoolUid, manualStudent.id())).extracting(StudentRelativeDto::id)
                .contains(relative.id());
        assertThat(service.updateRelative(relative.id(), new StudentRelativeRequest(
                manualStudent.id(),
                secondSchoolUid,
                runId + " Guardian",
                "GUARDIAN",
                "094"
        )).relationship()).isEqualTo("GUARDIAN");

        UserDto user = service.createUser(new UserRequest(
                runId + "@staff.local",
                "password123",
                "STAFF",
                null,
                staff.id(),
                null
        ));
        assertThat(service.getUsers()).extracting(UserDto::id).contains(user.id());
        assertThat(service.updateUser(user.id(), new UserRequest(
                runId + "@staff.local",
                "password123",
                "MANAGER",
                "ACTIVE",
                staff.id(),
                null
        )).role()).isEqualTo("MANAGER");
        assertThat(service.updateUserRole(user.id(), "ADMIN").role()).isEqualTo("ADMIN");
        assertThat(service.updateUserStatus(user.id(), "DISABLED").status()).isEqualTo("DISABLED");
        assertThatThrownBy(() -> service.updateUserRole(user.id(), "ROOT"))
                .isInstanceOf(ResponseStatusException.class)
                .hasMessageContaining("Invalid value");

        EmployeeDto updatedEmployee = service.updateEmployee(staff.id(), new EmployeeDto(staff.id(), runId + " Staff Updated", "STAFF"));
        assertThat(updatedEmployee.fullName()).contains("Updated");

        service.deleteUser(user.id());
        service.deleteRelative(relative.id());
        service.deletePerson(person.id());
        service.deleteStudent(manualStudent.id());
        service.archiveEvent(event.id());
        service.archiveCampaign(campaign.id());
        assertThat(service.getEvents(campaign.id(), false)).extracting(CampaignEventDto::id).doesNotContain(event.id());
        assertThat(service.getEvents(campaign.id(), true)).extracting(CampaignEventDto::id).contains(event.id());
        assertThat(service.getCampaigns(false)).extracting(CampaignDto::id).doesNotContain(campaign.id());
        assertThat(service.getCampaigns(true)).extracting(CampaignDto::id).contains(campaign.id());

        assertThatThrownBy(() -> service.deleteEmployee(99999999L))
                .isInstanceOf(ResourceNotFoundException.class);
        assertThatThrownBy(() -> service.updateRegistrationStatus(registration.id(), "UNKNOWN", new CurrentUser(1L, "admin@test.local", "ADMIN", "ACTIVE", null, null)))
                .isInstanceOf(ResponseStatusException.class)
                .hasMessageContaining("Invalid value");
    }

    private boolean databaseAvailable() {
        try (var connection = DriverManager.getConnection(JDBC_URL, JDBC_USER, JDBC_PASSWORD)) {
            return connection.isValid(2);
        } catch (Exception ignored) {
            return false;
        }
    }

    private void insertSchool(String uid, String provinceCode, String schoolCode, String name) {
        jdbc.update(
                """
                INSERT INTO schools (
                    school_uid, province_code, province_name, commune_code, commune_name,
                    school_code, school_name, address, area_type
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT (school_uid) DO UPDATE
                SET school_name = EXCLUDED.school_name,
                    address = EXCLUDED.address,
                    area_type = EXCLUDED.area_type
                """,
                uid,
                provinceCode,
                "Coverage Province",
                provinceCode + "001",
                "Coverage Commune",
                schoolCode,
                name,
                "Coverage address",
                "KV3"
        );
    }

    private void cleanup() {
        jdbc.update("DELETE FROM refresh_tokens WHERE user_id IN (SELECT id FROM app_users WHERE email LIKE ?)", runId + "%");
        jdbc.update("DELETE FROM campaign_student_registrations WHERE campaign_id IN (SELECT id FROM campaigns WHERE name LIKE ?)", runId + "%");
        jdbc.update("DELETE FROM interactions WHERE campaign_id IN (SELECT id FROM campaigns WHERE name LIKE ?)", runId + "%");
        jdbc.update("DELETE FROM event_assignments WHERE event_id IN (SELECT id FROM campaign_events WHERE name LIKE ?)", runId + "%");
        jdbc.update("DELETE FROM event_schools WHERE event_id IN (SELECT id FROM campaign_events WHERE name LIKE ?)", runId + "%");
        jdbc.update("DELETE FROM campaign_events WHERE name LIKE ?", runId + "%");
        jdbc.update("DELETE FROM campaigns WHERE name LIKE ?", runId + "%");
        jdbc.update("DELETE FROM app_users WHERE email LIKE ?", runId + "%");
        jdbc.update("DELETE FROM student_relatives WHERE full_name LIKE ?", runId + "%");
        jdbc.update("DELETE FROM persons WHERE full_name LIKE ?", runId + "%");
        jdbc.update("DELETE FROM students WHERE full_name LIKE ? OR email LIKE ?", runId + "%", runId + "%");
        jdbc.update("DELETE FROM employees WHERE full_name LIKE ?", runId + "%");
        if (schoolUid != null) {
            jdbc.update("DELETE FROM schools WHERE school_uid IN (?, ?)", schoolUid, secondSchoolUid);
        }
    }
}
