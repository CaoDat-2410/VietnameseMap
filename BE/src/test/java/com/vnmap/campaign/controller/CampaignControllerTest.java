package com.vnmap.campaign.controller;

import com.vnmap.campaign.dto.*;
import com.vnmap.campaign.service.CampaignService;
import com.vnmap.common.model.PagedResponse;
import com.vnmap.common.security.CurrentUser;
import org.junit.jupiter.api.Test;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.Month;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class CampaignControllerTest {

    private final CampaignService service = mock(CampaignService.class);
    private final CampaignController controller = new CampaignController(service);
    private final CurrentUser manager = new CurrentUser(2L, "manager@vnmap.local", "MANAGER", "ACTIVE", 2L, null);

    @Test
    void schoolEndpointsWrapPagedAndDetailResponses() {
        PagedResponse<SchoolDto> page = PagedResponse.of(List.of(school()), 0, 50, 1);
        SchoolDetailDto detail = new SchoolDetailDto(school(), List.of(student()), List.of(person()), List.of(relative()));
        when(service.getSchools(0, 50, "01", "00001", "KV3", "thpt")).thenReturn(page);
        when(service.getSchoolDetail("01-001")).thenReturn(detail);

        assertThat(controller.getSchools(0, 50, "01", "00001", "KV3", "thpt").getBody().getData())
                .isSameAs(page);
        assertThat(controller.getSchool("01-001").getBody().getData()).isSameAs(detail);
    }

    @Test
    void employeeEndpointsDelegateToService() {
        EmployeeDto employee = employee();
        when(service.getEmployees()).thenReturn(List.of(employee));
        when(service.createEmployee(employee)).thenReturn(employee);
        when(service.updateEmployee(1L, employee)).thenReturn(employee);

        assertThat(controller.getEmployees().getBody().getData()).containsExactly(employee);
        assertThat(controller.createEmployee(employee).getBody().getData()).isSameAs(employee);
        assertThat(controller.updateEmployee(1L, employee).getBody().getData()).isSameAs(employee);
        assertThat(controller.deleteEmployee(1L).getBody().getMessage()).isEqualTo("Employee deleted successfully");
        verify(service).deleteEmployee(1L);
    }

    @Test
    void campaignEndpointsDelegateToService() {
        CampaignDto campaign = campaign();
        CampaignRequest request = campaignRequest();
        CampaignDashboardDto dashboard = dashboard();
        when(service.getCampaigns(true)).thenReturn(List.of(campaign));
        when(service.createCampaign(request)).thenReturn(campaign);
        when(service.getCampaign(1L)).thenReturn(campaign);
        when(service.updateCampaign(1L, request)).thenReturn(campaign);
        when(service.getDashboard(1L)).thenReturn(dashboard);

        assertThat(controller.getCampaigns(true, manager).getBody().getData()).containsExactly(campaign);
        assertThat(controller.createCampaign(request).getBody().getData()).isSameAs(campaign);
        assertThat(controller.getCampaign(1L).getBody().getData()).isSameAs(campaign);
        assertThat(controller.updateCampaign(1L, request).getBody().getData()).isSameAs(campaign);
        assertThat(controller.archiveCampaign(1L).getBody().getMessage()).isEqualTo("Campaign archived successfully");
        assertThat(controller.getDashboard(1L).getBody().getData()).isSameAs(dashboard);
        verify(service).archiveCampaign(1L);
    }

    @Test
    void campaignListsIgnoreIncludeArchivedForNonManagers() {
        CurrentUser staff = new CurrentUser(3L, "staff@vnmap.local", "STAFF", "ACTIVE", 3L, null);

        assertThatThrownBy(() -> controller.getCampaigns(true, staff))
                .isInstanceOf(org.springframework.web.server.ResponseStatusException.class)
                .hasMessageContaining("Only managers and admins can include archived data");
    }

    @Test
    void eventEndpointsDelegateToService() {
        CampaignEventDto event = event();
        CampaignEventRequest request = eventRequest();
        when(service.getEvents(1L, true)).thenReturn(List.of(event));
        when(service.createEvent(1L, request)).thenReturn(event);
        when(service.getEvent(10L)).thenReturn(event);
        when(service.updateEvent(10L, request)).thenReturn(event);

        assertThat(controller.getEvents(1L, true, manager).getBody().getData()).containsExactly(event);
        assertThat(controller.createEvent(1L, request).getBody().getData()).isSameAs(event);
        assertThat(controller.getEvent(10L).getBody().getData()).isSameAs(event);
        assertThat(controller.updateEvent(10L, request).getBody().getData()).isSameAs(event);
        assertThat(controller.archiveEvent(10L).getBody().getMessage()).isEqualTo("Event archived successfully");
        verify(service).archiveEvent(10L);
    }

    @Test
    void assignmentEndpointsDelegateToService() {
        when(service.getEventSchools(10L)).thenReturn(List.of(school()));
        when(service.getEventAssignments(10L)).thenReturn(List.of(employee()));

        assertThat(controller.assignSchool(10L, new AssignSchoolRequest("01-001")).getBody().getMessage())
                .isEqualTo("School assigned successfully");
        assertThat(controller.removeSchool(10L, "01-001").getBody().getMessage())
                .isEqualTo("School removed successfully");
        assertThat(controller.getEventSchools(10L).getBody().getData()).containsExactly(school());
        assertThat(controller.assignEmployee(10L, new AssignEmployeeRequest(1L)).getBody().getMessage())
                .isEqualTo("Employee assigned successfully");
        assertThat(controller.removeEmployee(10L, 1L).getBody().getMessage())
                .isEqualTo("Employee removed successfully");
        assertThat(controller.getEventAssignments(10L).getBody().getData()).containsExactly(employee());
        verify(service).assignSchool(10L, "01-001");
        verify(service).removeSchool(10L, "01-001");
        verify(service).assignEmployee(10L, 1L);
        verify(service).removeEmployee(10L, 1L);
    }

    @Test
    void interactionEndpointsDelegateToService() {
        CreateInteractionRequest request = interactionRequest();
        InteractionDto interaction = interaction();
        when(service.getInteractions(10L)).thenReturn(List.of(interaction));
        when(service.createInteraction(10L, request)).thenReturn(interaction);
        when(service.updateInteraction(10L, 100L, request, manager)).thenReturn(interaction);

        assertThat(controller.getInteractions(10L).getBody().getData()).containsExactly(interaction);
        assertThat(controller.createInteraction(10L, request).getBody().getData()).isSameAs(interaction);
        assertThat(controller.updateInteraction(10L, 100L, request, manager).getBody().getData()).isSameAs(interaction);
        assertThat(controller.deleteInteraction(10L, 100L, manager).getBody().getMessage())
                .isEqualTo("Interaction deleted successfully");
        verify(service).deleteInteraction(10L, 100L, manager);
    }

    @Test
    void registrationEndpointsDelegateToService() {
        StudentRegistrationRequest request = registrationRequest();
        StudentRegistrationDto registration = registration();
        CurrentUser studentUser = new CurrentUser(4L, "student@vnmap.local", "STUDENT", "ACTIVE", null, 5L);
        when(service.registerStudent(1L, request)).thenReturn(registration);
        when(service.getCampaignRegistrations(1L)).thenReturn(List.of(registration));
        when(service.getMyRegistrations(studentUser)).thenReturn(List.of(registration));
        when(service.updateRegistrationStatus(20L, "APPROVED")).thenReturn(registration);

        assertThat(controller.registerStudent(1L, request).getBody().getData()).isSameAs(registration);
        assertThat(controller.getCampaignRegistrations(1L).getBody().getData()).containsExactly(registration);
        assertThat(controller.getMyRegistrations(studentUser).getBody().getData()).containsExactly(registration);
        assertThat(controller.updateRegistrationStatus(20L, new UpdateRegistrationStatusRequest("APPROVED"))
                .getBody().getData()).isSameAs(registration);
    }

    @Test
    void studentPersonRelativeAndUserEndpointsDelegateToService() {
        StudentRequest studentRequest = studentRequest();
        PersonRequest personRequest = new PersonRequest("01-001", "Teacher", "TEACHER");
        StudentRelativeRequest relativeRequest = new StudentRelativeRequest(1L, "01-001", "Parent", "PARENT", "090");
        UserRequest userRequest = new UserRequest("user@vnmap.local", "password123", "STAFF", "ACTIVE", 1L, null);
        when(service.getStudents(0, 50, "01-001", "a")).thenReturn(PagedResponse.of(List.of(student()), 0, 50, 1));
        when(service.createStudent(studentRequest)).thenReturn(student());
        when(service.updateStudent(1L, studentRequest)).thenReturn(student());
        when(service.getPersons("01-001")).thenReturn(List.of(person()));
        when(service.createPerson(personRequest)).thenReturn(person());
        when(service.updatePerson(2L, personRequest)).thenReturn(person());
        when(service.getRelatives("01-001", 1L)).thenReturn(List.of(relative()));
        when(service.createRelative(relativeRequest)).thenReturn(relative());
        when(service.updateRelative(3L, relativeRequest)).thenReturn(relative());
        when(service.getUsers()).thenReturn(List.of(user()));
        when(service.createUser(userRequest)).thenReturn(user());
        when(service.updateUser(4L, userRequest)).thenReturn(user());
        when(service.updateUserRole(4L, "ADMIN")).thenReturn(user());
        when(service.updateUserStatus(4L, "DISABLED")).thenReturn(user());

        assertThat(controller.getStudents(0, 50, "01-001", "a").getBody().getData().items()).containsExactly(student());
        assertThat(controller.createStudent(studentRequest).getBody().getData()).isEqualTo(student());
        assertThat(controller.updateStudent(1L, studentRequest).getBody().getData()).isEqualTo(student());
        assertThat(controller.deleteStudent(1L).getBody().getMessage()).isEqualTo("Student deleted successfully");
        assertThat(controller.getPersons("01-001").getBody().getData()).containsExactly(person());
        assertThat(controller.createPerson(personRequest).getBody().getData()).isEqualTo(person());
        assertThat(controller.updatePerson(2L, personRequest).getBody().getData()).isEqualTo(person());
        assertThat(controller.deletePerson(2L).getBody().getMessage()).isEqualTo("Person deleted successfully");
        assertThat(controller.getRelatives("01-001", 1L).getBody().getData()).containsExactly(relative());
        assertThat(controller.createRelative(relativeRequest).getBody().getData()).isEqualTo(relative());
        assertThat(controller.updateRelative(3L, relativeRequest).getBody().getData()).isEqualTo(relative());
        assertThat(controller.deleteRelative(3L).getBody().getMessage()).isEqualTo("Student relative deleted successfully");
        assertThat(controller.getUsers().getBody().getData()).containsExactly(user());
        assertThat(controller.createUser(userRequest).getBody().getData()).isEqualTo(user());
        assertThat(controller.updateUser(4L, userRequest).getBody().getData()).isEqualTo(user());
        assertThat(controller.deleteUser(4L).getBody().getMessage()).isEqualTo("User deleted successfully");
        assertThat(controller.updateUserRole(4L, new UpdateRoleRequest("ADMIN")).getBody().getData()).isEqualTo(user());
        assertThat(controller.updateUserStatus(4L, new UpdateStatusRequest("DISABLED")).getBody().getData()).isEqualTo(user());
    }

    private CampaignDto campaign() {
        return new CampaignDto(1L, "Campaign", "ACTIVE", "Objective",
                LocalDate.of(2026, Month.JUNE, 1), LocalDate.of(2026, Month.JULY, 31), 1L);
    }

    private CampaignRequest campaignRequest() {
        return new CampaignRequest("Campaign", "ACTIVE", "Objective",
                LocalDate.of(2026, Month.JUNE, 1), LocalDate.of(2026, Month.JULY, 31), 1L);
    }

    private CampaignDashboardDto dashboard() {
        return new CampaignDashboardDto(1L, 2, 3, 4, 5,
                Map.of("INTERESTED", 3L),
                List.of(new ProvinceInteractionDto("01", "Ha Noi", 3)),
                List.of(new TopSchoolDto("01-001", "THPT A", 3)));
    }

    private CampaignEventDto event() {
        return new CampaignEventDto(10L, 1L, "Event", "SCHOOL_VISIT", "PLANNED",
                LocalDateTime.of(2026, Month.JUNE, 20, 8, 0),
                LocalDateTime.of(2026, Month.JUNE, 20, 11, 0), "Note",
                "THPT A, Ha Noi", 21.0285, 105.8542, "01-001", "01");
    }

    private CampaignEventRequest eventRequest() {
        return new CampaignEventRequest("Event", "SCHOOL_VISIT", "PLANNED",
                LocalDateTime.of(2026, Month.JUNE, 20, 8, 0),
                LocalDateTime.of(2026, Month.JUNE, 20, 11, 0), "Note",
                "THPT A, Ha Noi", 21.0285, 105.8542, "01-001", "01");
    }

    private SchoolDto school() {
        return new SchoolDto("01-001", "01", "Ha Noi", "00001", "Ba Dinh",
                "001", "THPT A", "Address", "KV3");
    }

    private EmployeeDto employee() {
        return new EmployeeDto(1L, "Dev Staff", "STAFF");
    }

    private StudentDto student() {
        return new StudentDto(1L, "01-001", "Student", "student@vnmap.local", "090",
                LocalDate.of(2008, Month.JANUARY, 1), "Address", "12", "12A1");
    }

    private StudentRequest studentRequest() {
        return new StudentRequest("01-001", "Student", "student@vnmap.local", "090",
                LocalDate.of(2008, Month.JANUARY, 1), "Address", "12", "12A1");
    }

    private PersonDto person() {
        return new PersonDto(2L, "01-001", "Teacher", "TEACHER");
    }

    private StudentRelativeDto relative() {
        return new StudentRelativeDto(3L, "01-001", "Parent", 1L, "PARENT", "090");
    }

    private CreateInteractionRequest interactionRequest() {
        return new CreateInteractionRequest(1L, "01-001", "STUDENT", 1L,
                "MEETING", "INTERESTED", "Note", LocalDateTime.of(2026, Month.JUNE, 25, 9, 0));
    }

    private InteractionDto interaction() {
        return new InteractionDto(100L, 1L, 10L, 1L, "01-001", "STUDENT", 1L,
                "MEETING", "INTERESTED", "Note",
                LocalDateTime.of(2026, Month.JUNE, 25, 9, 0),
                LocalDateTime.of(2026, Month.JUNE, 20, 8, 45));
    }

    private StudentRegistrationRequest registrationRequest() {
        return new StudentRegistrationRequest("01-001", "Student", "student@vnmap.local", "090",
                "password123", "12", "12A1", LocalDate.of(2008, Month.JANUARY, 1), "Address", "Note");
    }

    private StudentRegistrationDto registration() {
        return new StudentRegistrationDto(20L, 1L, 1L, "01-001", "PENDING", "Note",
                LocalDateTime.of(2026, Month.JUNE, 20, 8, 0),
                LocalDateTime.of(2026, Month.JUNE, 20, 8, 0), student(), school());
    }

    private UserDto user() {
        return new UserDto(4L, "user@vnmap.local", "STAFF", "ACTIVE", 1L, null);
    }
}
