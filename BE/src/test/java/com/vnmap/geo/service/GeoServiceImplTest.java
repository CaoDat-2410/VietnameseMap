package com.vnmap.geo.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.vnmap.common.exception.ResourceNotFoundException;
import com.vnmap.geo.dto.AdministrativeUnitDto;
import com.vnmap.geo.dto.GeoJsonFeatureDto;
import com.vnmap.geo.entity.AdministrativeUnit;
import com.vnmap.geo.enums.UnitLevel;
import com.vnmap.geo.mapper.GeoMapper;
import com.vnmap.geo.repository.AdministrativeUnitRepository;
import org.locationtech.jts.geom.Geometry;
import org.locationtech.jts.geom.Point;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("GeoServiceImpl Tests")
class GeoServiceImplTest {

    @Mock
    private AdministrativeUnitRepository repository;

    @Mock
    private GeoMapper geoMapper;

    private GeoServiceImpl geoService;

    @BeforeEach
    void setUp() {
        geoService = new GeoServiceImpl(repository, geoMapper, new ObjectMapper());
    }

    @Nested
    @DisplayName("getWardsByDistrict")
    class GetWardsByDistrict {

        @Test
        @DisplayName("should return wards for valid district code")
        void shouldReturnWardsForValidDistrict() {
            AdministrativeUnit district = createUnit(2L, "Ba Dinh", "001_01", UnitLevel.DISTRICT, 1L);
            AdministrativeUnit ward = createUnit(3L, "Truong Da", "001_01_001", UnitLevel.WARD, 2L);

            when(repository.findByCode("001_01")).thenReturn(Optional.of(district));
            when(repository.findByParentIdAndLevel(2L, UnitLevel.WARD)).thenReturn(List.of(ward));
            when(geoMapper.toSummaryDtoList(any())).thenReturn(List.of(
                    com.vnmap.geo.dto.AdministrativeUnitSummaryDto.builder()
                            .id(3L)
                            .code("001_01_001")
                            .name("Truong Da")
                            .level(UnitLevel.WARD)
                            .build()
            ));

            List<?> result = geoService.getWardsByDistrict("001_01");

            assertThat(result).hasSize(1);
        }

        @Test
        @DisplayName("should throw ResourceNotFoundException when district not found")
        void shouldThrowWhenDistrictNotFound() {
            when(repository.findByCode("invalid")).thenReturn(Optional.empty());

            assertThatThrownBy(() -> geoService.getWardsByDistrict("invalid"))
                    .isInstanceOf(ResourceNotFoundException.class)
                    .hasMessageContaining("District");
        }

        @Test
        @DisplayName("should throw IllegalArgumentException when code is not a district")
        void shouldThrowWhenCodeIsNotDistrict() {
            AdministrativeUnit province = createUnit(1L, "Hanoi", "01", UnitLevel.PROVINCE, null);
            when(repository.findByCode("01")).thenReturn(Optional.of(province));

            assertThatThrownBy(() -> geoService.getWardsByDistrict("01"))
                    .isInstanceOf(IllegalArgumentException.class)
                    .hasMessageContaining("not a district");
        }
    }

    @Nested
    @DisplayName("getBoundaryByCode")
    class GetBoundaryByCode {

        @Test
        @DisplayName("should return boundary for province code")
        void shouldReturnBoundaryForProvince() {
            AdministrativeUnit unit = createUnit(1L, "Hanoi", "01", UnitLevel.PROVINCE, null);
            String geoJson = "{\"type\":\"Polygon\",\"coordinates\":[[[105.0,21.0],[105.5,21.0],[105.5,21.5],[105.0,21.5],[105.0,21.0]]]}";

            when(repository.findByCodeAndLevel("01", UnitLevel.PROVINCE)).thenReturn(Optional.of(unit));
            when(repository.findBoundaryByCodeAndLevel("01", "PROVINCE")).thenReturn(Optional.of(geoJson));

            GeoJsonFeatureDto result = geoService.getBoundaryByCode("01");

            assertThat(result.getCode()).isEqualTo("01");
            assertThat(result.getLevel()).isEqualTo(UnitLevel.PROVINCE);
            assertThat(result.getGeometry()).isNotNull();
        }

        @Test
        @DisplayName("should throw ResourceNotFoundException when unit not found")
        void shouldThrowWhenUnitNotFound() {
            when(repository.findByCodeAndLevel("invalid", UnitLevel.PROVINCE)).thenReturn(Optional.empty());

            assertThatThrownBy(() -> geoService.getBoundaryByCode("invalid"))
                    .isInstanceOf(ResourceNotFoundException.class);
        }

        @Test
        @DisplayName("should throw ResourceNotFoundException when boundary not found")
        void shouldThrowWhenBoundaryNotFound() {
            AdministrativeUnit unit = createUnit(1L, "Hanoi", "01", UnitLevel.PROVINCE, null);
            when(repository.findByCodeAndLevel("01", UnitLevel.PROVINCE)).thenReturn(Optional.of(unit));
            when(repository.findBoundaryByCodeAndLevel("01", "PROVINCE")).thenReturn(Optional.empty());

            assertThatThrownBy(() -> geoService.getBoundaryByCode("01"))
                    .isInstanceOf(ResourceNotFoundException.class)
                    .hasMessageContaining("Boundary");
        }

        @Test
        @DisplayName("should fallback to Polygon type when type is missing in GeoJSON")
        void shouldFallbackToPolygonType() {
            AdministrativeUnit unit = createUnit(1L, "Hanoi", "01", UnitLevel.PROVINCE, null);
            String geoJson = "{\"coordinates\":[[[105.0,21.0]]]}";

            when(repository.findByCodeAndLevel("01", UnitLevel.PROVINCE)).thenReturn(Optional.of(unit));
            when(repository.findBoundaryByCodeAndLevel("01", "PROVINCE")).thenReturn(Optional.of(geoJson));

            GeoJsonFeatureDto result = geoService.getBoundaryByCode("01");

            assertThat(result.getGeometry().getType()).isEqualTo("Polygon");
        }

        @Test
        @DisplayName("should fallback to coordinates string on parse error")
        void shouldFallbackOnParseError() {
            AdministrativeUnit unit = createUnit(1L, "Hanoi", "01", UnitLevel.PROVINCE, null);
            String invalidJson = "not-valid-json";

            when(repository.findByCodeAndLevel("01", UnitLevel.PROVINCE)).thenReturn(Optional.of(unit));
            when(repository.findBoundaryByCodeAndLevel("01", "PROVINCE")).thenReturn(Optional.of(invalidJson));

            GeoJsonFeatureDto result = geoService.getBoundaryByCode("01");

            assertThat(result.getGeometry().getType()).isEqualTo("Polygon");
            assertThat(result.getGeometry().getCoordinates()).isEqualTo(invalidJson);
        }
    }

    @Nested
    @DisplayName("findUnitByCoordinate")
    class FindUnitByCoordinate {

        @Test
        @DisplayName("should return unit for valid coordinates")
        void shouldReturnUnitForCoordinates() {
            AdministrativeUnit unit = createUnit(1L, "Hanoi", "01", UnitLevel.PROVINCE, null);
            AdministrativeUnitDto dto = createDto(1L, "Hanoi", "01", UnitLevel.PROVINCE);

            when(repository.findUnitContainingPoint(21.03, 105.85)).thenReturn(Optional.of(unit));
            when(geoMapper.toDto(unit)).thenReturn(dto);
            when(repository.countByParentId(anyLong())).thenReturn(0);

            AdministrativeUnitDto result = geoService.findUnitByCoordinate(21.03, 105.85);

            assertThat(result.getCode()).isEqualTo("01");
        }

        @Test
        @DisplayName("should throw ResourceNotFoundException when no unit at coordinates")
        void shouldThrowWhenNoUnitAtCoordinates() {
            when(repository.findUnitContainingPoint(anyDouble(), anyDouble())).thenReturn(Optional.empty());

            assertThatThrownBy(() -> geoService.findUnitByCoordinate(99.0, 99.0))
                    .isInstanceOf(ResourceNotFoundException.class)
                    .hasMessageContaining("coordinates");
        }

        @Test
        @DisplayName("should set parent code when parent exists")
        void shouldSetParentCodeWhenParentExists() {
            AdministrativeUnit unit = createUnit(2L, "Ba Dinh", "001", UnitLevel.DISTRICT, 1L);
            AdministrativeUnit parent = createUnit(1L, "Hanoi", "01", UnitLevel.PROVINCE, null);
            AdministrativeUnitDto dto = createDto(2L, "Ba Dinh", "001", UnitLevel.DISTRICT);

            when(repository.findUnitContainingPoint(anyDouble(), anyDouble())).thenReturn(Optional.of(unit));
            when(geoMapper.toDto(unit)).thenReturn(dto);
            when(repository.findById(1L)).thenReturn(Optional.of(parent));
            when(repository.countByParentId(2L)).thenReturn(0);

            geoService.findUnitByCoordinate(21.03, 105.85);

            verify(repository).findById(1L);
        }
    }

    @Nested
    @DisplayName("getAllProvincesBoundaries")
    class GetAllProvincesBoundaries {

        @Test
        @DisplayName("should return FeatureCollection for provinces")
        void shouldReturnFeatureCollection() {
            AdministrativeUnit province = createUnit(1L, "Hanoi", "01", UnitLevel.PROVINCE, null);
            String geoJson = "{\"type\":\"Polygon\",\"coordinates\":[[[105,21],[105.5,21],[105.5,21.5],[105,21.5],[105,21]]]}";

            when(repository.findByLevel(UnitLevel.PROVINCE)).thenReturn(List.of(province));
            when(repository.findBoundaryByCodeAndLevel("01", "PROVINCE")).thenReturn(Optional.of(geoJson));

            Object result = geoService.getAllProvincesBoundaries();

            assertThat(result).isInstanceOf(Map.class);
            @SuppressWarnings("unchecked")
            Map<String, Object> collection = (Map<String, Object>) result;
            assertThat(collection.get("type")).isEqualTo("FeatureCollection");
            @SuppressWarnings("unchecked")
            List<?> features = (List<?>) collection.get("features");
            assertThat(features).hasSize(1);
        }

        @Test
        @DisplayName("should skip provinces with blank boundaries")
        void shouldSkipBlankBoundaries() {
            AdministrativeUnit province = createUnit(1L, "Hanoi", "01", UnitLevel.PROVINCE, null);

            when(repository.findByLevel(UnitLevel.PROVINCE)).thenReturn(List.of(province));
            when(repository.findBoundaryByCodeAndLevel("01", "PROVINCE")).thenReturn(Optional.empty());

            Object result = geoService.getAllProvincesBoundaries();

            @SuppressWarnings("unchecked")
            Map<String, Object> collection = (Map<String, Object>) result;
            @SuppressWarnings("unchecked")
            List<?> features = (List<?>) collection.get("features");
            assertThat(features).isEmpty();
        }

        @Test
        @DisplayName("should fallback geometry on invalid GeoJSON in getAllProvincesBoundaries")
        void shouldFallbackGeometryOnInvalidGeoJson() {
            AdministrativeUnit province = createUnit(1L, "Hanoi", "01", UnitLevel.PROVINCE, null);
            String invalidJson = "not-valid-json";

            when(repository.findByLevel(UnitLevel.PROVINCE)).thenReturn(List.of(province));
            when(repository.findBoundaryByCodeAndLevel("01", "PROVINCE")).thenReturn(Optional.of(invalidJson));

            Object result = geoService.getAllProvincesBoundaries();

            @SuppressWarnings("unchecked")
            Map<String, Object> collection = (Map<String, Object>) result;
            @SuppressWarnings("unchecked")
            List<?> features = (List<?>) collection.get("features");
            assertThat(features).hasSize(1);
            @SuppressWarnings("unchecked")
            Map<String, Object> feature = (Map<String, Object>) features.get(0);
            @SuppressWarnings("unchecked")
            Map<String, Object> geometry = (Map<String, Object>) feature.get("geometry");
            assertThat(geometry.get("type")).isEqualTo("Polygon");
            assertThat(geometry.get("coordinates")).isEqualTo(java.util.Collections.emptyList());
        }
    }

    @Nested
    @DisplayName("getWardsBoundariesByDistrictId")
    class GetWardsBoundariesByDistrictId {

        @Test
        @DisplayName("should return ward features for valid district")
        void shouldReturnWardFeatures() {
            Object[] row = new Object[] { 3L, "Ward A", "001_01_003", "District", "Province", "{\"type\":\"Polygon\",\"coordinates\":[[[105,21],[105.5,21],[105.5,21.5],[105,21.5]]]}" };

            when(repository.findWardsWithBoundariesByDistrictId(2L)).thenReturn(Collections.singletonList(row));

            List<GeoJsonFeatureDto> result = geoService.getWardsBoundariesByDistrictId(2L);

            assertThat(result).hasSize(1);
            assertThat(result.get(0).getCode()).isEqualTo("001_01_003");
            assertThat(result.get(0).getName()).isEqualTo("Ward A");
            assertThat(result.get(0).getLevel()).isEqualTo(UnitLevel.WARD);
        }

        @Test
        @DisplayName("should return empty list when no wards found")
        void shouldReturnEmptyWhenNoWards() {
            when(repository.findWardsWithBoundariesByDistrictId(2L)).thenReturn(Collections.emptyList());

            List<GeoJsonFeatureDto> result = geoService.getWardsBoundariesByDistrictId(2L);

            assertThat(result).isEmpty();
        }

        @Test
        @DisplayName("should skip ward when GeoJSON parse fails")
        void shouldSkipWardOnParseError() {
            Object[] row = new Object[] { 3L, "Ward A", "001_01_003", "District", "Province", "not-valid-json" };

            when(repository.findWardsWithBoundariesByDistrictId(2L)).thenReturn(Collections.singletonList(row));

            List<GeoJsonFeatureDto> result = geoService.getWardsBoundariesByDistrictId(2L);

            assertThat(result).isEmpty();
        }

        @Test
        @DisplayName("should skip ward when boundary is null")
        void shouldSkipWardWhenBoundaryIsNull() {
            Object[] row = new Object[] { 3L, "Ward A", "001_01_003", "District", "Province", null };

            when(repository.findWardsWithBoundariesByDistrictId(2L)).thenReturn(Collections.singletonList(row));

            List<GeoJsonFeatureDto> result = geoService.getWardsBoundariesByDistrictId(2L);

            assertThat(result).isEmpty();
        }
    }

    @Nested
    @DisplayName("getAllProvinces")
    class GetAllProvinces {

        @Test
        @DisplayName("should return all provinces")
        void shouldReturnAllProvinces() {
            AdministrativeUnit province = createUnit(1L, "Hanoi", "01", UnitLevel.PROVINCE, null);
            when(repository.findByLevel(UnitLevel.PROVINCE)).thenReturn(List.of(province));
            when(geoMapper.toSummaryDtoList(any())).thenReturn(List.of(
                    com.vnmap.geo.dto.AdministrativeUnitSummaryDto.builder()
                            .id(1L)
                            .code("01")
                            .name("Hanoi")
                            .level(UnitLevel.PROVINCE)
                            .build()
            ));

            List<?> result = geoService.getAllProvinces();

            assertThat(result).hasSize(1);
            verify(repository).findByLevel(UnitLevel.PROVINCE);
        }
    }

    @Nested
    @DisplayName("getDistrictsByProvince")
    class GetDistrictsByProvince {

        @Test
        @DisplayName("should return districts for valid province code")
        void shouldReturnDistrictsForValidProvince() {
            AdministrativeUnit province = createUnit(1L, "Hanoi", "01", UnitLevel.PROVINCE, null);
            AdministrativeUnit district = createUnit(2L, "Ba Dinh", "001", UnitLevel.DISTRICT, 1L);

            when(repository.findByCode("01")).thenReturn(Optional.of(province));
            when(repository.findByParentIdAndLevel(1L, UnitLevel.DISTRICT)).thenReturn(List.of(district));
            when(geoMapper.toSummaryDtoList(any())).thenReturn(List.of(
                    com.vnmap.geo.dto.AdministrativeUnitSummaryDto.builder()
                            .id(2L)
                            .code("001")
                            .name("Ba Dinh")
                            .level(UnitLevel.DISTRICT)
                            .build()
            ));

            List<?> result = geoService.getDistrictsByProvince("01");

            assertThat(result).hasSize(1);
        }

        @Test
        @DisplayName("should throw ResourceNotFoundException when province not found")
        void shouldThrowWhenProvinceNotFound() {
            when(repository.findByCode("invalid")).thenReturn(Optional.empty());

            assertThatThrownBy(() -> geoService.getDistrictsByProvince("invalid"))
                    .isInstanceOf(ResourceNotFoundException.class)
                    .hasMessageContaining("Province");
        }

        @Test
        @DisplayName("should throw IllegalArgumentException when code is not a province")
        void shouldThrowWhenCodeIsNotProvince() {
            AdministrativeUnit district = createUnit(2L, "Ba Dinh", "001", UnitLevel.DISTRICT, 1L);
            when(repository.findByCode("001")).thenReturn(Optional.of(district));

            assertThatThrownBy(() -> geoService.getDistrictsByProvince("001"))
                    .isInstanceOf(IllegalArgumentException.class)
                    .hasMessageContaining("not a province");
        }
    }

    @Nested
    @DisplayName("getByCode")
    class GetByCode {

        @Test
        @DisplayName("should return unit for valid code")
        void shouldReturnUnitForValidCode() {
            AdministrativeUnit unit = createUnit(1L, "Hanoi", "01", UnitLevel.PROVINCE, null);
            AdministrativeUnitDto dto = createDto(1L, "Hanoi", "01", UnitLevel.PROVINCE);

            when(repository.findByCode("01")).thenReturn(Optional.of(unit));
            when(geoMapper.toDto(unit)).thenReturn(dto);
            when(repository.countByParentId(1L)).thenReturn(0);

            AdministrativeUnitDto result = geoService.getByCode("01");

            assertThat(result.getCode()).isEqualTo("01");
            assertThat(result.getName()).isEqualTo("Hanoi");
        }

        @Test
        @DisplayName("should throw ResourceNotFoundException when unit not found")
        void shouldThrowWhenUnitNotFound() {
            when(repository.findByCode("invalid")).thenReturn(Optional.empty());

            assertThatThrownBy(() -> geoService.getByCode("invalid"))
                    .isInstanceOf(ResourceNotFoundException.class)
                    .hasMessageContaining("AdministrativeUnit");
        }

        @Test
        @DisplayName("should set parent code when parent exists")
        void shouldSetParentCodeWhenParentExists() {
            AdministrativeUnit district = createUnit(2L, "Ba Dinh", "001", UnitLevel.DISTRICT, 1L);
            AdministrativeUnit province = createUnit(1L, "Hanoi", "01", UnitLevel.PROVINCE, null);
            AdministrativeUnitDto dto = createDto(2L, "Ba Dinh", "001", UnitLevel.DISTRICT);

            when(repository.findByCode("001")).thenReturn(Optional.of(district));
            when(geoMapper.toDto(district)).thenReturn(dto);
            when(repository.findById(1L)).thenReturn(Optional.of(province));
            when(repository.countByParentId(2L)).thenReturn(0);

            AdministrativeUnitDto result = geoService.getByCode("001");

            assertThat(result.getParentCode()).isEqualTo("01");
        }

        @Test
        @DisplayName("should set child count")
        void shouldSetChildCount() {
            AdministrativeUnit district = createUnit(2L, "Ba Dinh", "001", UnitLevel.DISTRICT, 1L);
            AdministrativeUnitDto dto = createDto(2L, "Ba Dinh", "001", UnitLevel.DISTRICT);

            when(repository.findByCode("001")).thenReturn(Optional.of(district));
            when(geoMapper.toDto(district)).thenReturn(dto);
            when(repository.countByParentId(2L)).thenReturn(5);

            AdministrativeUnitDto result = geoService.getByCode("001");

            assertThat(result.getChildCount()).isEqualTo(5);
        }

        @Test
        @DisplayName("should use existing centroid when available")
        void shouldUseExistingCentroid() {
            AdministrativeUnit unit = createUnit(1L, "Hanoi", "01", UnitLevel.PROVINCE, null);
            AdministrativeUnitDto dto = createDto(1L, "Hanoi", "01", UnitLevel.PROVINCE);
            Point centroid = mock(Point.class);
            when(centroid.getX()).thenReturn(105.85);
            when(centroid.getY()).thenReturn(21.03);
            unit.setCentroid(centroid);

            when(repository.findByCode("01")).thenReturn(Optional.of(unit));
            when(geoMapper.toDto(unit)).thenReturn(dto);
            when(repository.countByParentId(1L)).thenReturn(0);

            AdministrativeUnitDto result = geoService.getByCode("01");

            assertThat(result.getCentroidLat()).isEqualTo(21.03);
            assertThat(result.getCentroidLng()).isEqualTo(105.85);
        }

        @Test
        @DisplayName("should fallback to repository centroid when unit centroid is null")
        void shouldFallbackToRepositoryCentroid() {
            AdministrativeUnit unit = createUnit(1L, "Hanoi", "01", UnitLevel.PROVINCE, null);
            AdministrativeUnitDto dto = createDto(1L, "Hanoi", "01", UnitLevel.PROVINCE);

            Object[] centroidRow = new Object[] { 105.85, 21.03 };

            when(repository.findByCode("01")).thenReturn(Optional.of(unit));
            when(geoMapper.toDto(unit)).thenReturn(dto);
            when(repository.countByParentId(1L)).thenReturn(0);
            when(repository.findCentroidByCode("01", "PROVINCE")).thenReturn(Optional.of(centroidRow));

            AdministrativeUnitDto result = geoService.getByCode("01");

            assertThat(result.getCentroidLat()).isEqualTo(21.03);
            assertThat(result.getCentroidLng()).isEqualTo(105.85);
        }
    }

    @Nested
    @DisplayName("getBoundaryByCode - additional")
    class GetBoundaryByCodeAdditional {

        @Test
        @DisplayName("should set parent code when parent exists")
        void shouldSetParentCodeWhenParentExists() {
            AdministrativeUnit district = createUnit(2L, "Ba Dinh", "001", UnitLevel.DISTRICT, 1L);
            AdministrativeUnit province = createUnit(1L, "Hanoi", "01", UnitLevel.PROVINCE, null);
            String geoJson = "{\"type\":\"Polygon\",\"coordinates\":[[[105,21]]]}";

            when(repository.findByCodeAndLevel("001", UnitLevel.PROVINCE)).thenReturn(Optional.of(district));
            when(repository.findBoundaryByCodeAndLevel("001", "DISTRICT")).thenReturn(Optional.of(geoJson));
            when(repository.findById(1L)).thenReturn(Optional.of(province));

            GeoJsonFeatureDto result = geoService.getBoundaryByCode("001");

            assertThat(result.getParentCode()).isEqualTo("01");
        }

        @Test
        @DisplayName("should handle missing parent gracefully")
        void shouldHandleMissingParent() {
            AdministrativeUnit district = createUnit(2L, "Ba Dinh", "001", UnitLevel.DISTRICT, 1L);
            String geoJson = "{\"type\":\"Polygon\",\"coordinates\":[[[105,21]]]}";

            when(repository.findByCodeAndLevel("001", UnitLevel.PROVINCE)).thenReturn(Optional.of(district));
            when(repository.findBoundaryByCodeAndLevel("001", "DISTRICT")).thenReturn(Optional.of(geoJson));
            when(repository.findById(1L)).thenReturn(Optional.empty());

            GeoJsonFeatureDto result = geoService.getBoundaryByCode("001");

            assertThat(result.getParentCode()).isNull();
        }
    }

    @Nested
    @DisplayName("findUnitByCoordinate - additional")
    class FindUnitByCoordinateAdditional {

        @Test
        @DisplayName("should fallback to repository centroid when unit centroid is null")
        void shouldFallbackToRepositoryCentroid() {
            AdministrativeUnit unit = createUnit(1L, "Hanoi", "01", UnitLevel.PROVINCE, null);
            AdministrativeUnitDto dto = createDto(1L, "Hanoi", "01", UnitLevel.PROVINCE);

            Object[] centroidRow = new Object[] { 105.85, 21.03 };

            when(repository.findUnitContainingPoint(21.03, 105.85)).thenReturn(Optional.of(unit));
            when(geoMapper.toDto(unit)).thenReturn(dto);
            when(repository.countByParentId(1L)).thenReturn(0);
            when(repository.findCentroidByCode("01", "PROVINCE")).thenReturn(Optional.of(centroidRow));

            AdministrativeUnitDto result = geoService.findUnitByCoordinate(21.03, 105.85);

            assertThat(result.getCentroidLat()).isEqualTo(21.03);
            assertThat(result.getCentroidLng()).isEqualTo(105.85);
        }
    }

    @Nested
    @DisplayName("calculateCentroids")
    class CalculateCentroids {

        @Test
        @DisplayName("should calculate centroids for units without them")
        void shouldCalculateCentroids() {
            AdministrativeUnit unit = createUnit(1L, "Hanoi", "01", UnitLevel.PROVINCE, null);
            com.vnmap.geo.entity.AdministrativeUnit spyUnit = spy(unit);
            Geometry boundary = mock(Geometry.class);
            Point centroid = mock(Point.class);
            when(boundary.getCentroid()).thenReturn(centroid);
            spyUnit.setBoundary(boundary);

            when(repository.findAll()).thenReturn(List.of(spyUnit));

            int count = geoService.calculateCentroids();

            assertThat(count).isEqualTo(1);
            verify(repository).save(spyUnit);
        }

        @Test
        @DisplayName("should skip units already with centroids")
        void shouldSkipUnitsWithCentroids() {
            AdministrativeUnit unit = createUnit(1L, "Hanoi", "01", UnitLevel.PROVINCE, null);
            Point existingCentroid = mock(Point.class);
            unit.setCentroid(existingCentroid);
            unit.setBoundary(null);

            when(repository.findAll()).thenReturn(List.of(unit));

            int count = geoService.calculateCentroids();

            assertThat(count).isEqualTo(0);
            verify(repository, never()).save(any());
        }
    }

    @Nested
    @DisplayName("determineLevelFromCode")
    class DetermineLevelFromCode {

        @Test
        @DisplayName("should return PROVINCE for code without underscore")
        void shouldReturnProvinceForNoUnderscore() throws Exception {
            var method = GeoServiceImpl.class.getDeclaredMethod("determineLevelFromCode", String.class);
            method.setAccessible(true);

            UnitLevel level = (UnitLevel) method.invoke(geoService, "01");

            assertThat(level).isEqualTo(UnitLevel.PROVINCE);
        }

        @Test
        @DisplayName("should return WARD for code with 1 underscore")
        void shouldReturnWardFor1Underscore() throws Exception {
            var method = GeoServiceImpl.class.getDeclaredMethod("determineLevelFromCode", String.class);
            method.setAccessible(true);

            UnitLevel level = (UnitLevel) method.invoke(geoService, "001_01");

            assertThat(level).isEqualTo(UnitLevel.WARD);
        }

        @Test
        @DisplayName("should return DISTRICT for code with 2 underscores")
        void shouldReturnDistrictFor2Underscores() throws Exception {
            var method = GeoServiceImpl.class.getDeclaredMethod("determineLevelFromCode", String.class);
            method.setAccessible(true);

            UnitLevel level = (UnitLevel) method.invoke(geoService, "001_01_001");

            assertThat(level).isEqualTo(UnitLevel.DISTRICT);
        }
    }

    private AdministrativeUnit createUnit(Long id, String name, String code, UnitLevel level, Long parentId) {
        return AdministrativeUnit.builder()
                .id(id)
                .name(name)
                .code(code)
                .level(level)
                .parentId(parentId)
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
