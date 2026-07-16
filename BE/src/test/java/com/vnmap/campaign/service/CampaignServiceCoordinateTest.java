package com.vnmap.campaign.service;

import com.vnmap.campaign.dto.SchoolCoordinatesDto;
import com.vnmap.geo.repository.AdministrativeUnitRepository;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.List;
import java.util.Map;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

class CampaignServiceCoordinateTest {
    @Test
    void computesApproximateAndPendingCoordinatesFromCommuneCentroids() {
        JdbcTemplate jdbc = mock(JdbcTemplate.class);
        AdministrativeUnitRepository units = mock(AdministrativeUnitRepository.class);
        CampaignService service = new CampaignService(jdbc, mock(PasswordEncoder.class), units);
        when(jdbc.queryForList(anyString())).thenReturn(List.of(
                Map.of("school_uid", "a", "commune_code", "001", "school_name", "A", "province_name", "P", "commune_name", "C", "address", "Address"),
                Map.of("school_uid", "b", "commune_code", "", "school_name", "B", "province_name", "P", "commune_name", "C", "address", "Address")
        ));
        when(units.findCentroidByCode("001", "commune")).thenReturn(Optional.of(new Object[]{105.8d, 21.0d}));

        List<SchoolCoordinatesDto> result = service.computeApproximateCoordinates();

        assertThat(result).hasSize(2);
        assertThat(result.get(0).geocodeStatus()).isEqualTo("APPROXIMATE");
        assertThat(result.get(0).latitude()).isEqualTo(21.0d);
        assertThat(result.get(1).geocodeStatus()).isEqualTo("PENDING");
        verify(jdbc, times(2)).update(anyString(), any(), any(), any(), any(), any());
    }

    @Test
    void marksUnknownCentroidAsPending() {
        JdbcTemplate jdbc = mock(JdbcTemplate.class);
        AdministrativeUnitRepository units = mock(AdministrativeUnitRepository.class);
        CampaignService service = new CampaignService(jdbc, mock(PasswordEncoder.class), units);
        when(jdbc.queryForList(anyString())).thenReturn(List.of(Map.of("school_uid", "a", "commune_code", "001", "school_name", "A", "province_name", "P", "commune_name", "C", "address", "Address")));
        when(units.findCentroidByCode("001", "commune")).thenReturn(Optional.empty());

        assertThat(service.computeApproximateCoordinates()).singleElement().extracting(SchoolCoordinatesDto::geocodeStatus).isEqualTo("PENDING");
    }
}