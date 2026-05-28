package com.vnmap.geo;

import com.vnmap.geo.controller.GeoController;
import com.vnmap.geo.dto.AdministrativeUnitDto;
import com.vnmap.geo.dto.AdministrativeUnitSummaryDto;
import com.vnmap.geo.dto.GeoJsonFeatureDto;
import com.vnmap.geo.enums.UnitLevel;
import com.vnmap.geo.service.GeoService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Arrays;
import java.util.List;

import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.is;
import static org.mockito.ArgumentMatchers.anyDouble;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(GeoController.class)
@DisplayName("GeoController Tests")
class GeoControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private GeoService geoService;

    @Nested
    @DisplayName("GET /api/v1/geo/provinces")
    class GetProvinces {

        @Test
        @DisplayName("should return list of provinces")
        void shouldReturnProvinces() throws Exception {
            List<AdministrativeUnitSummaryDto> provinces = Arrays.asList(
                    createSummaryDto("01", "Hà Nội", UnitLevel.PROVINCE),
                    createSummaryDto("79", "Hồ Chí Minh", UnitLevel.PROVINCE)
            );

            when(geoService.getAllProvinces()).thenReturn(provinces);

            mockMvc.perform(get("/api/v1/geo/provinces")
                            .contentType(MediaType.APPLICATION_JSON))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.success", is(true)))
                    .andExpect(jsonPath("$.data", hasSize(2)))
                    .andExpect(jsonPath("$.data[0].code", is("01")))
                    .andExpect(jsonPath("$.data[0].name", is("Hà Nội")));
        }

        @Test
        @DisplayName("should return empty list when no provinces")
        void shouldReturnEmptyList() throws Exception {
            when(geoService.getAllProvinces()).thenReturn(List.of());

            mockMvc.perform(get("/api/v1/geo/provinces")
                            .contentType(MediaType.APPLICATION_JSON))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.success", is(true)))
                    .andExpect(jsonPath("$.data", hasSize(0)));
        }
    }

    @Nested
    @DisplayName("GET /api/v1/geo/districts")
    class GetDistricts {

        @Test
        @DisplayName("should return districts for valid province")
        void shouldReturnDistricts() throws Exception {
            List<AdministrativeUnitSummaryDto> districts = Arrays.asList(
                    createSummaryDto("001", "Ba Đình", UnitLevel.DISTRICT),
                    createSummaryDto("002", "Hoàn Kiếm", UnitLevel.DISTRICT)
            );

            when(geoService.getDistrictsByProvince("01")).thenReturn(districts);

            mockMvc.perform(get("/api/v1/geo/districts")
                            .param("provinceCode", "01")
                            .contentType(MediaType.APPLICATION_JSON))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.success", is(true)))
                    .andExpect(jsonPath("$.data", hasSize(2)))
                    .andExpect(jsonPath("$.data[0].code", is("001")));
        }

        @Test
        @DisplayName("should return 400 when provinceCode is missing")
        void shouldReturn400WhenProvinceCodeMissing() throws Exception {
            mockMvc.perform(get("/api/v1/geo/districts")
                            .contentType(MediaType.APPLICATION_JSON))
                    .andExpect(status().isBadRequest());
        }
    }

    @Nested
    @DisplayName("GET /api/v1/geo/units/{code}")
    class GetUnitByCode {

        @Test
        @DisplayName("should return unit details")
        void shouldReturnUnitDetails() throws Exception {
            AdministrativeUnitDto unit = createDto(1L, "Hà Nội", "01", UnitLevel.PROVINCE);
            when(geoService.getByCode("01")).thenReturn(unit);

            mockMvc.perform(get("/api/v1/geo/units/01")
                            .contentType(MediaType.APPLICATION_JSON))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.success", is(true)))
                    .andExpect(jsonPath("$.data.code", is("01")))
                    .andExpect(jsonPath("$.data.name", is("Hà Nội")));
        }
    }

    @Nested
    @DisplayName("GET /api/v1/geo/reverse")
    class ReverseGeocode {

        @Test
        @DisplayName("should return unit for coordinates")
        void shouldReturnUnitForCoordinates() throws Exception {
            AdministrativeUnitDto unit = createDto(1L, "Hà Nội", "01", UnitLevel.PROVINCE);
            when(geoService.findUnitByCoordinate(anyDouble(), anyDouble())).thenReturn(unit);

            mockMvc.perform(get("/api/v1/geo/reverse")
                            .param("lat", "21.0285")
                            .param("lng", "105.8542")
                            .contentType(MediaType.APPLICATION_JSON))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.success", is(true)))
                    .andExpect(jsonPath("$.data.name", is("Hà Nội")));
        }

        @Test
        @DisplayName("should return 400 for invalid latitude")
        void shouldReturn400ForInvalidLatitude() throws Exception {
            mockMvc.perform(get("/api/v1/geo/reverse")
                            .param("lat", "100.0")
                            .param("lng", "105.8542")
                            .contentType(MediaType.APPLICATION_JSON))
                    .andExpect(status().isBadRequest());
        }
    }

    private AdministrativeUnitSummaryDto createSummaryDto(String code, String name, UnitLevel level) {
        return AdministrativeUnitSummaryDto.builder()
                .code(code)
                .name(name)
                .level(level)
                .build();
    }

    private AdministrativeUnitDto createDto(Long id, String name, String code, UnitLevel level) {
        return AdministrativeUnitDto.builder()
                .id(id)
                .name(name)
                .code(code)
                .level(level)
                .build();
    }
}
