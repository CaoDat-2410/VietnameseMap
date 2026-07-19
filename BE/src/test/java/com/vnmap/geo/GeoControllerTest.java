package com.vnmap.geo;

import com.vnmap.geo.controller.GeoController;
import com.vnmap.geo.dto.AdministrativeUnitDto;
import com.vnmap.geo.dto.AdministrativeUnitSummaryDto;
import com.vnmap.geo.dto.GeoJsonFeatureDto;
import com.vnmap.geo.service.GeoService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
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
@AutoConfigureMockMvc(addFilters = false)
@DisplayName("GeoController Tests (2025 Reform)")
class GeoControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private GeoService geoService;

    // ==================== Province Endpoints ====================

    @Nested
    @DisplayName("GET /api/v1/geo/provinces")
    class GetProvinces {

        @Test
        @DisplayName("should return list of provinces")
        void shouldReturnProvinces() throws Exception {
            List<AdministrativeUnitSummaryDto> provinces = Arrays.asList(
                    createSummaryDto("01", "Hà Nội", "province"),
                    createSummaryDto("79", "Hồ Chí Minh", "province")
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
    @DisplayName("GET /api/v1/geo/provinces/{code}/boundary")
    class GetProvinceBoundary {

        @Test
        @DisplayName("should return province boundary")
        void shouldReturnProvinceBoundary() throws Exception {
            GeoJsonFeatureDto feature = GeoJsonFeatureDto.builder()
                    .code("01")
                    .name("Hà Nội")
                    .kind("province")
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

    // ==================== Commune Endpoints (NEW) ====================

    @Nested
    @DisplayName("GET /api/v1/geo/provinces/{code}/communes")
    class GetCommunes {

        @Test
        @DisplayName("should return communes for valid province")
        void shouldReturnCommunes() throws Exception {
            List<AdministrativeUnitSummaryDto> communes = Arrays.asList(
                    createSummaryDto("001", "Ba Đình", "commune"),
                    createSummaryDto("002", "Hoàn Kiếm", "commune")
            );

            when(geoService.getCommunesByProvince("01")).thenReturn(communes);

            mockMvc.perform(get("/api/v1/geo/provinces/01/communes")
                            .contentType(MediaType.APPLICATION_JSON))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.success", is(true)))
                    .andExpect(jsonPath("$.data", hasSize(2)))
                    .andExpect(jsonPath("$.data[0].code", is("001")))
                    .andExpect(jsonPath("$.data[0].name", is("Ba Đình")));
        }

        @Test
        @DisplayName("should return empty list when no communes")
        void shouldReturnEmptyList() throws Exception {
            when(geoService.getCommunesByProvince("99")).thenReturn(List.of());

            mockMvc.perform(get("/api/v1/geo/provinces/99/communes")
                            .contentType(MediaType.APPLICATION_JSON))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.success", is(true)))
                    .andExpect(jsonPath("$.data", hasSize(0)));
        }
    }

    @Nested
    @DisplayName("GET /api/v1/geo/provinces/{code}/communes-boundaries")
    class GetCommunesBoundaries {

        @Test
        @DisplayName("should return commune boundaries for province")
        void shouldReturnCommuneBoundaries() throws Exception {
            List<GeoJsonFeatureDto> features = Arrays.asList(
                    GeoJsonFeatureDto.builder()
                            .code("001")
                            .name("Ba Đình")
                            .kind("commune")
                            .type("Feature")
                            .geometry(GeoJsonFeatureDto.GeometryDto.builder()
                                    .type("Polygon")
                                    .coordinates("[[[105.8,21.0],[105.9,21.0],[105.9,21.1]]]")
                                    .build())
                            .build()
            );

            when(geoService.getCommunesBoundariesByProvinceCode("01")).thenReturn(features);

            mockMvc.perform(get("/api/v1/geo/provinces/01/communes-boundaries")
                            .contentType(MediaType.APPLICATION_JSON))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.success", is(true)))
                    .andExpect(jsonPath("$.data", hasSize(1)))
                    .andExpect(jsonPath("$.data[0].code", is("001")));
        }
    }

    @Nested
    @DisplayName("GET /api/v1/geo/provinces/{code}/communes-paginated")
    class GetCommunesPaginated {

        @Test
        @DisplayName("should return paginated communes")
        void shouldReturnPaginatedCommunes() throws Exception {
            List<AdministrativeUnitSummaryDto> communes = List.of(
                    createSummaryDto("001", "Ba Đình", "commune")
            );

            when(geoService.getCommunesByProvince("01")).thenReturn(communes);

            mockMvc.perform(get("/api/v1/geo/provinces/01/communes-paginated")
                            .param("page", "0")
                            .param("size", "10")
                            .contentType(MediaType.APPLICATION_JSON))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.success", is(true)));
        }
    }

    @Nested
    @DisplayName("GET /api/v1/geo/macro-regions/{name}/communes")
    class GetCommunesByMacroRegion {

        @Test
        @DisplayName("should return communes for macro-region")
        void shouldReturnCommunesForMacroRegion() throws Exception {
            List<AdministrativeUnitSummaryDto> communes = List.of(
                    createSummaryDto("001", "Ba Đình", "commune")
            );

            when(geoService.getCommunesByMacroRegion("North Delta")).thenReturn(communes);

            mockMvc.perform(get("/api/v1/geo/macro-regions/North%20Delta/communes")
                            .contentType(MediaType.APPLICATION_JSON))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.success", is(true)));
        }
    }

    // ==================== Unit Endpoints ====================

    @Nested
    @DisplayName("GET /api/v1/geo/units/{code}")
    class GetUnitByCode {

        @Test
        @DisplayName("should return unit details")
        void shouldReturnUnitDetails() throws Exception {
            AdministrativeUnitDto unit = createDto(1L, "Hà Nội", "01", "province");
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
    @DisplayName("GET /api/v1/geo/units/{code}/boundary")
    class GetUnitBoundary {

        @Test
        @DisplayName("should return unit boundary")
        void shouldReturnUnitBoundary() throws Exception {
            GeoJsonFeatureDto feature = GeoJsonFeatureDto.builder()
                    .code("01")
                    .name("Hà Nội")
                    .kind("province")
                    .type("Feature")
                    .build();
            when(geoService.getBoundaryByCode("01")).thenReturn(feature);

            mockMvc.perform(get("/api/v1/geo/units/01/boundary")
                            .contentType(MediaType.APPLICATION_JSON))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.success", is(true)));
        }
    }

    // ==================== Reverse Geocode ====================

    @Nested
    @DisplayName("GET /api/v1/geo/reverse")
    class ReverseGeocode {

        @Test
        @DisplayName("should return commune for coordinates")
        void shouldReturnCommuneForCoordinates() throws Exception {
            AdministrativeUnitDto commune = createDto(2L, "Ba Đình", "001", "commune");
            when(geoService.findUnitByCoordinate(anyDouble(), anyDouble())).thenReturn(commune);

            mockMvc.perform(get("/api/v1/geo/reverse")
                            .param("lat", "21.0285")
                            .param("lng", "105.8542")
                            .contentType(MediaType.APPLICATION_JSON))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.success", is(true)))
                    .andExpect(jsonPath("$.data.name", is("Ba Đình")))
                    .andExpect(jsonPath("$.data.kind", is("commune")));
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

    // ==================== Admin Endpoints ====================

    @Nested
    @DisplayName("POST /api/v1/geo/admin/calculate-centroids")
    class CalculateCentroids {

        @Test
        @DisplayName("should calculate and return count")
        void shouldCalculateAndReturnCount() throws Exception {
            when(geoService.calculateCentroids()).thenReturn(3355);

            mockMvc.perform(post("/api/v1/geo/admin/calculate-centroids")
                            .contentType(MediaType.APPLICATION_JSON))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.success", is(true)))
                    .andExpect(jsonPath("$.data", is(3355)));
        }
    }

    // ==================== Helper Methods ====================

    private AdministrativeUnitSummaryDto createSummaryDto(String code, String name, String kind) {
        return AdministrativeUnitSummaryDto.builder()
                .code(code)
                .name(name)
                .kind(kind)
                .build();
    }

    private AdministrativeUnitDto createDto(Long id, String name, String code, String kind) {
        return AdministrativeUnitDto.builder()
                .id(id)
                .name(name)
                .code(code)
                .kind(kind)
                .build();
    }
}
