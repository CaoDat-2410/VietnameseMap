package com.vnmap.campaign.service;

import com.vnmap.campaign.dto.BulkRegistrationStatusRequest;
import com.vnmap.campaign.dto.CampaignDto;
import com.vnmap.campaign.dto.CampaignRequest;
import com.vnmap.campaign.dto.InteractionDto;
import com.vnmap.common.exception.ResourceNotFoundException;
import com.vnmap.common.security.CurrentUser;
import com.vnmap.geo.repository.AdministrativeUnitRepository;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDate;
import java.time.Month;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.contains;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doReturn;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class CampaignServiceBranchTest {
    private final JdbcTemplate jdbc = mock(JdbcTemplate.class);
    private final PasswordEncoder passwordEncoder = mock(PasswordEncoder.class);
    private final CampaignService service = new CampaignService(
            jdbc,
            passwordEncoder,
            mock(AdministrativeUnitRepository.class)
    );

    @Test
    void resolvesGeneratedIdsAndRejectsMissingKeys() {
        GeneratedKeyHolder numeric = new GeneratedKeyHolder();
        numeric.getKeyList().add(new HashMap<>(Map.of("id", 41L)));
        assertThat((Long) ReflectionTestUtils.invokeMethod(service, "generatedId", numeric)).isEqualTo(41L);

        GeneratedKeyHolder array = new GeneratedKeyHolder();
        array.getKeyList().add(new HashMap<>(Map.of("id", new Object[]{42L})));
        assertThat((Long) ReflectionTestUtils.invokeMethod(service, "generatedId", array)).isEqualTo(42L);

        GeneratedKeyHolder empty = new GeneratedKeyHolder();
        assertThatThrownBy(() -> ReflectionTestUtils.invokeMethod(service, "generatedId", empty))
                .isInstanceOf(IllegalStateException.class);
    }

    @Test
    void coversRegistrationFiltersPaginationAndBulkUpdates() {
        when(jdbc.queryForObject(anyString(), eq(Long.class), any(Object[].class))).thenReturn(null, 0L);
        doReturn(List.of()).when(jdbc).query(anyString(), any(RowMapper.class), any(Object[].class));

        CurrentUser staff = new CurrentUser(7L, "staff@test", "STAFF", "ACTIVE", 9L, null);
        var filtered = service.listRegistrationsForStaff(
                staff, 3L, "school-1", "PENDING", "  name  ", -1, 999
        );
        assertThat(filtered.page()).isZero();
        assertThat(filtered.limit()).isEqualTo(200);
        assertThat(filtered.totalItems()).isZero();

        CurrentUser manager = new CurrentUser(8L, "manager@test", "MANAGER", "ACTIVE", 10L, null);
        var unfiltered = service.listRegistrationsForStaff(manager, null, " ", "", null, 1, 20);
        assertThat(unfiltered.items()).isEmpty();

        assertThat(service.bulkUpdateRegistrationStatus(new BulkRegistrationStatusRequest("APPROVED", null), manager))
                .isZero();
        assertThat(service.bulkUpdateRegistrationStatus(new BulkRegistrationStatusRequest("APPROVED", List.of()), manager))
                .isZero();
        when(jdbc.update(contains("WHERE id IN"), any(Object[].class))).thenReturn(2);
        assertThat(service.bulkUpdateRegistrationStatus(
                new BulkRegistrationStatusRequest("APPROVED", List.of(11L, 12L)), manager
        )).isEqualTo(2);
    }

    @Test
    void validatesCampaignWindowsStatusesPasswordsAndRoles() {
        LocalDate today = LocalDate.now(java.time.ZoneId.of("Asia/Ho_Chi_Minh"));
        CampaignDto inactive = campaign("DRAFT", today.minusDays(1), today.plusDays(1));
        CampaignDto future = campaign("ACTIVE", today.plusDays(1), today.plusDays(2));
        CampaignDto expired = campaign("ACTIVE", today.minusDays(2), today.minusDays(1));
        CampaignDto active = campaign("ACTIVE", today.minusDays(1), today.plusDays(1));

        assertThatThrownBy(() -> ReflectionTestUtils.invokeMethod(service, "ensureCampaignAcceptsStudentRegistrations", inactive))
                .isInstanceOf(ResponseStatusException.class);
        assertThatThrownBy(() -> ReflectionTestUtils.invokeMethod(service, "ensureCampaignAcceptsStudentRegistrations", future))
                .isInstanceOf(ResponseStatusException.class);
        assertThatThrownBy(() -> ReflectionTestUtils.invokeMethod(service, "ensureCampaignAcceptsStudentRegistrations", expired))
                .isInstanceOf(ResponseStatusException.class);
        ReflectionTestUtils.invokeMethod(service, "ensureCampaignAcceptsStudentRegistrations", active);

        CampaignRequest badDates = new CampaignRequest(
                "Campaign", "ACTIVE", null,
                LocalDate.of(2026, Month.FEBRUARY, 2),
                LocalDate.of(2026, Month.FEBRUARY, 1),
                1L
        );
        CampaignRequest badStatus = new CampaignRequest("Campaign", "INVALID", null, null, null, 1L);
        assertThatThrownBy(() -> ReflectionTestUtils.invokeMethod(service, "validateCampaignRequest", badDates))
                .isInstanceOf(ResponseStatusException.class);
        assertThatThrownBy(() -> ReflectionTestUtils.invokeMethod(service, "validateCampaignRequest", badStatus))
                .isInstanceOf(ResponseStatusException.class);

        for (String password : new String[]{null, " ", "short"}) {
            assertThatThrownBy(() -> ReflectionTestUtils.invokeMethod(service, "requirePasswordForCreate", password))
                    .isInstanceOf(ResponseStatusException.class);
        }
        ReflectionTestUtils.invokeMethod(service, "requirePasswordForCreate", "long-enough");

        for (String role : List.of("ADMIN", "MANAGER", "STAFF", "STUDENT")) {
            ReflectionTestUtils.invokeMethod(service, "validateRole", role);
        }
        assertThatThrownBy(() -> ReflectionTestUtils.invokeMethod(service, "validateRole", "ROOT"))
                .isInstanceOf(ResponseStatusException.class);
    }

    @Test
    void normalizesValuesAndChecksInteractionOwnership() {
        assertThat((String) ReflectionTestUtils.invokeMethod(service, "blankToNull", (Object) null)).isNull();
        assertThat((String) ReflectionTestUtils.invokeMethod(service, "blankToNull", " ")).isNull();
        assertThat((String) ReflectionTestUtils.invokeMethod(service, "blankToNull", "value")).isEqualTo("value");
        assertThat((String) ReflectionTestUtils.invokeMethod(service, "normalizeUserStatus", (Object) null)).isEqualTo("ACTIVE");
        assertThat((String) ReflectionTestUtils.invokeMethod(service, "normalizeUserStatus", " ")).isEqualTo("ACTIVE");
        assertThat((String) ReflectionTestUtils.invokeMethod(service, "normalizeUserStatus", "DISABLED")).isEqualTo("DISABLED");
        assertThat((Long) ReflectionTestUtils.invokeMethod(service, "zero", (Object) null)).isZero();
        assertThat((Long) ReflectionTestUtils.invokeMethod(service, "zero", 7L)).isEqualTo(7L);

        InteractionDto interaction = new InteractionDto(
                1L, 2L, 3L, 9L, "school", "STUDENT", 4L,
                "PHONE", "INTERESTED", null, null, null
        );
        CurrentUser manager = new CurrentUser(1L, "m", "MANAGER", "ACTIVE", null, null);
        CurrentUser admin = new CurrentUser(2L, "a", "ADMIN", "ACTIVE", null, null);
        CurrentUser owner = new CurrentUser(3L, "o", "STAFF", "ACTIVE", 9L, null);
        CurrentUser stranger = new CurrentUser(4L, "s", "STAFF", "ACTIVE", 10L, null);
        ReflectionTestUtils.invokeMethod(service, "ensureInteractionOwnerOrManager", interaction, manager);
        ReflectionTestUtils.invokeMethod(service, "ensureInteractionOwnerOrManager", interaction, admin);
        ReflectionTestUtils.invokeMethod(service, "ensureInteractionOwnerOrManager", interaction, owner);
        assertThatThrownBy(() -> ReflectionTestUtils.invokeMethod(
                service, "ensureInteractionOwnerOrManager", interaction, stranger
        )).isInstanceOf(ResponseStatusException.class);
    }

    @Test
    void enforcesRegistrationManagementAndMissingCrudRows() {
        CurrentUser manager = new CurrentUser(1L, "m", "MANAGER", "ACTIVE", null, null);
        CurrentUser staffWithoutEmployee = new CurrentUser(2L, "s", "STAFF", "ACTIVE", null, null);
        CurrentUser staff = new CurrentUser(3L, "s2", "STAFF", "ACTIVE", 8L, null);

        ReflectionTestUtils.invokeMethod(service, "ensureRegistrationManagedByUser", 1L, manager);
        assertThatThrownBy(() -> ReflectionTestUtils.invokeMethod(
                service, "ensureRegistrationManagedByUser", 1L, null
        )).isInstanceOf(ResponseStatusException.class);
        assertThatThrownBy(() -> ReflectionTestUtils.invokeMethod(
                service, "ensureRegistrationManagedByUser", 1L, staffWithoutEmployee
        )).isInstanceOf(ResponseStatusException.class);
        when(jdbc.queryForObject(anyString(), eq(Integer.class), eq(1L), eq(8L), eq(8L)))
                .thenReturn(null, 0, 1);
        assertThatThrownBy(() -> ReflectionTestUtils.invokeMethod(
                service, "ensureRegistrationManagedByUser", 1L, staff
        )).isInstanceOf(ResponseStatusException.class);
        assertThatThrownBy(() -> ReflectionTestUtils.invokeMethod(
                service, "ensureRegistrationManagedByUser", 1L, staff
        )).isInstanceOf(ResponseStatusException.class);
        ReflectionTestUtils.invokeMethod(service, "ensureRegistrationManagedByUser", 1L, staff);

        when(jdbc.update(anyString(), any(Object[].class))).thenReturn(0);
        assertThatThrownBy(() -> service.deleteStudent(91L)).isInstanceOf(ResourceNotFoundException.class);
        assertThatThrownBy(() -> service.deletePerson(92L)).isInstanceOf(ResourceNotFoundException.class);
        assertThatThrownBy(() -> service.deleteRelative(93L)).isInstanceOf(ResourceNotFoundException.class);
        assertThatThrownBy(() -> service.deleteEmployee(94L)).isInstanceOf(ResourceNotFoundException.class);
        assertThatThrownBy(() -> service.deleteUser(95L)).isInstanceOf(ResourceNotFoundException.class);
    }

    private static CampaignDto campaign(String status, LocalDate startDate, LocalDate endDate) {
        return new CampaignDto(1L, "Campaign", status, null, startDate, endDate, 1L);
    }
}