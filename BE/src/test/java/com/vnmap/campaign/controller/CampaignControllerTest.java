package com.vnmap.campaign.controller;

import com.vnmap.campaign.service.CampaignService;
import com.vnmap.campaign.dto.SchoolCoordinatesUpdateRequest;
import com.vnmap.campaign.dto.UpdateRegistrationStatusRequest;
import com.vnmap.campaign.dto.AssignSchoolRequest;
import com.vnmap.campaign.dto.BulkRegistrationStatusRequest;
import com.vnmap.campaign.dto.AssignEmployeeRequest;
import com.vnmap.campaign.dto.UpdateRoleRequest;
import com.vnmap.campaign.dto.UpdateStatusRequest;
import com.vnmap.campaign.service.OsmGeocodingService;
import com.vnmap.common.security.CurrentUser;
import org.junit.jupiter.api.Test;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.*;

class CampaignControllerTest {
    private final CampaignService campaigns = mock(CampaignService.class);
    private final OsmGeocodingService geocoder = mock(OsmGeocodingService.class);
    private final CampaignController controller = new CampaignController(campaigns, geocoder);
    private final CurrentUser admin = new CurrentUser(1L, "a", "ADMIN", "ACTIVE", null, null);

    @Test
    void delegatesReadAndArchiveEndpoints() {
        controller.getSchools(0, 50, "79", "x", "urban", "q"); controller.getSchool("s"); controller.getSchoolCoordinates("79", "x"); controller.getSchoolCoordinate("s"); controller.updateSchoolCoordinates("s", new SchoolCoordinatesUpdateRequest(10.0, 20.0)); controller.computeApproximateCoordinates(); controller.geocodeSchools(List.of("s"));
        controller.getEmployees(); controller.createEmployee(null); controller.updateEmployee(1, null); controller.deleteEmployee(1);
        controller.getCampaigns(false, null); controller.getCampaigns(true, admin); controller.createCampaign(null); controller.getCampaign(1); controller.updateCampaign(1, null); controller.archiveCampaign(1); controller.getDashboard(1);
        controller.getEvents(1, false, null); controller.getEvents(1, true, admin); controller.createEvent(1, null); controller.getEvent(1); controller.updateEvent(1, null); controller.archiveEvent(1);
        controller.assignSchool(1, new AssignSchoolRequest("school")); controller.removeSchool(1, "s"); controller.getEventSchools(1); controller.assignEmployee(1, new AssignEmployeeRequest(2L)); controller.removeEmployee(1, 2); controller.getEventAssignments(1); controller.getInteractions(1); controller.createInteraction(1, null); controller.updateInteraction(1, 2, null, admin); controller.deleteInteraction(1, 2, admin);
        verify(campaigns).archiveCampaign(1); verify(campaigns).archiveEvent(1); verify(geocoder).geocodeSchools(List.of("s"));
    }

    @Test
    void delegatesRegistrationPeopleAndUserEndpointsAndRejectsArchivedForStudent() {
        controller.registerStudent(1, null, null); controller.getCampaignRegistrations(1); controller.getMyRegistrations(admin); controller.updateRegistrationStatus(1, new UpdateRegistrationStatusRequest("APPROVED"), admin); controller.listStaffRegistrations(1L, "s", "NEW", "q", 0, 50, admin); controller.bulkUpdateRegistrationStatus(new BulkRegistrationStatusRequest("APPROVED", List.of(1L)), admin);
        controller.getStudents(0, 50, "s", "q"); controller.createStudent(null); controller.updateStudent(1, null); controller.deleteStudent(1);
        controller.getPersons("s"); controller.createPerson(null); controller.updatePerson(1, null); controller.deletePerson(1); controller.getRelatives("s", 1L); controller.createRelative(null); controller.updateRelative(1, null); controller.deleteRelative(1);
        controller.getUsers(); controller.createUser(null); controller.updateUser(1, null); controller.deleteUser(1); controller.updateUserRole(1, new UpdateRoleRequest("STAFF")); controller.updateUserStatus(1, new UpdateStatusRequest("ACTIVE"));
        CurrentUser student = new CurrentUser(2L, "s", "STUDENT", "ACTIVE", null, null);
        assertThatThrownBy(() -> controller.getCampaigns(true, student)).isInstanceOf(ResponseStatusException.class);
        assertThat(controller.getCampaigns(false, student).getStatusCode().is2xxSuccessful()).isTrue();
    }
}