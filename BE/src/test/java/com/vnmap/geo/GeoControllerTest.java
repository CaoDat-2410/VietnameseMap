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
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
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

    @Nested
    @DisplayName("GET /api/v1/geo/provinces/{code}/boundary")
    class GetProvinceBoundary {

        @Test
        @DisplayName("should return province boundary")
        void shouldReturnProvinceBoundary() throws Exception {
            GeoJsonFeatureDto feature = GeoJsonFeatureDto.builder()
                    .code("01")
                    .name("Hà Nội")
                    .level(UnitLevel.PROVINCE)
                    .type("Feature")
                    .geometry(GeoJsonFeatureDto.GeometryDto.builder()
                            .type("Polygon")
                            .coordinates("[[[105,21],[105.5,21]]]")
                            .build())
                    .build();
            when(geoService.getBoundaryByCode("01")).thenReturn(feature);

            mockMvc.perform(get("/api/v1/geo/provinces/01/boundary")
                            .contentType(MediaType.APPLICATION_JSON))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.success", is(true)))
                    .andExpect(jsonPath("$.data.code", is("01")));
        }
    }

    @Nested
    @DisplayName("GET /api/v1/geo/wards")
    class GetWards {

        @Test
        @DisplayName("should return wards for valid district")
        void shouldReturnWards() throws Exception {
            List<AdministrativeUnitSummaryDto> wards = List.of(
                    createSummaryDto("001_01_001", "Phường 1", UnitLevel.WARD));
            when(geoService.getWardsByDistrict("001")).thenReturn(wards);

            mockMvc.perform(get("/api/v1/geo/wards")
                            .param("districtCode", "001")
                            .contentType(MediaType.APPLICATION_JSON))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.success", is(true)))
                    .andExpect(jsonPath("$.data", hasSize(1)));
        }

        @Test
        @DisplayName("should return 400 when districtCode is missing")
        void shouldReturn400WhenDistrictCodeMissing() throws Exception {
            mockMvc.perform(get("/api/v1/geo/wards")
                            .contentType(MediaType.APPLICATION_JSON))
                    .andExpect(status().isBadRequest());
        }
    }

    @Nested
    @DisplayName("GET /api/v1/geo/units/{code}/boundary")
    class GetUnitBoundary {

        @Test
        @DisplayName("should return unit boundary")
        void shouldReturnUnitBoundary() throws Exception {
            GeoJsonFeatureDto feature = GeoJsonFeatureDto.builder()
                    .code("01")
                    .name("Hà Nội")
                    .level(UnitLevel.PROVINCE)
                    .type("Feature")
                    .build();
            when(geoService.getBoundaryByCode("01")).thenReturn(feature);

            mockMvc.perform(get("/api/v1/geo/units/01/boundary")
                            .contentType(MediaType.APPLICATION_JSON))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.success", is(true)));
        }
    }

    @Nested
    @DisplayName("GET /api/v1/geo/provinces-boundaries")
    class GetAllProvincesBoundaries {

        @Test
        @DisplayName("should return all province boundaries")
        void shouldReturnAllBoundaries() throws Exception {
            when(geoService.getAllProvincesBoundaries()).thenReturn(
                    java.util.Map.of("type", "FeatureCollection", "features", java.util.List.of()));

            mockMvc.perform(get("/api/v1/geo/provinces-boundaries")
                            .contentType(MediaType.APPLICATION_JSON))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.success", is(true)));
        }
    }

    @Nested
    @DisplayName("POST /api/v1/geo/admin/calculate-centroids")
    class CalculateCentroids {

        @Test
        @DisplayName("should calculate and return count")
        void shouldCalculateAndReturnCount() throws Exception {
            when(geoService.calculateCentroids()).thenReturn(10);

            mockMvc.perform(post("/api/v1/geo/admin/calculate-centroids")
                            .contentType(MediaType.APPLICATION_JSON))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.success", is(true)))
                    .andExpect(jsonPath("$.data", is(10)));
        }
    }

    @Nested
    @DisplayName("GET /api/v1/geo/districts/{districtId}/wards-boundaries")
    class GetWardsBoundaries {

        @Test
        @DisplayName("should return ward boundaries")
        void shouldReturnWardBoundaries() throws Exception {
            List<GeoJsonFeatureDto> features = List.of(
                    GeoJsonFeatureDto.builder()
                            .code("001_01_001")
                            .name("Ward 1")
                            .level(UnitLevel.WARD)
                            .type("Feature")
                            .geometry(GeoJsonFeatureDto.GeometryDto.builder()
                                    .type("Polygon")
                                    .coordinates("[[[105,21]]]")
                                    .build())
                            .build());
            when(geoService.getWardsBoundariesByDistrictId(2L)).thenReturn(features);

            mockMvc.perform(get("/api/v1/geo/districts/2/wards-boundaries")
                            .contentType(MediaType.APPLICATION_JSON))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.success", is(true)))
                    .andExpect(jsonPath("$.data", hasSize(1)));
        }
    }
}
