package com.vnmap.geo.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.vnmap.geo.dto.AdministrativeUnitDto;
import com.vnmap.geo.dto.GeoJsonFeatureDto;
import com.vnmap.geo.entity.AdministrativeUnit;
import com.vnmap.geo.entity.CommitteeLocation;
import com.vnmap.geo.mapper.GeoMapper;
import com.vnmap.geo.repository.AdministrativeUnitRepository;
import com.vnmap.geo.repository.CommitteeLocationRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.cache.Cache;
import org.springframework.cache.CacheManager;

import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("GeoServiceImpl Tests (2025 Reform)")
class GeoServiceImplTest {

    @Mock
    private AdministrativeUnitRepository repository;

    @Mock
    private CommitteeLocationRepository committeeRepository;

    @Mock
    private GeoMapper geoMapper;

    @Mock
    private CacheManager cacheManager;

    @Mock
    private Cache cache;

    private GeoServiceImpl geoService;

    private static final String KIND_PROVINCE = "province";
    private static final String KIND_COMMUNE = "commune";

    @BeforeEach
    void setUp() {
        geoService = new GeoServiceImpl(repository, committeeRepository, geoMapper, new ObjectMapper(), cacheManager);
    }

    @Nested
    @DisplayName("getAllProvinces")
    class GetAllProvinces {

        @Test
        @DisplayName("should return all provinces")
        void shouldReturnAllProvinces() {
            AdministrativeUnit province = createUnit(1L, "Hanoi", "01", KIND_PROVINCE, null);
            when(repository.findByKind(KIND_PROVINCE)).thenReturn(List.of(province));
            when(geoMapper.toSummaryDtoList(any())).thenReturn(List.of(
                    com.vnmap.geo.dto.AdministrativeUnitSummaryDto.builder()
                            .id(1L)
                            .code("01")
                            .name("Hanoi")
                            .kind(KIND_PROVINCE)
                            .build()
            ));

            var result = geoService.getAllProvinces();

            assertThat(result).hasSize(1);
            verify(repository).findByKind(KIND_PROVINCE);
        }

        @Test
        @DisplayName("should return empty list when no provinces")
        void shouldReturnEmptyWhenNoProvinces() {
            when(repository.findByKind(KIND_PROVINCE)).thenReturn(List.of());
            when(geoMapper.toSummaryDtoList(any())).thenReturn(List.of());

            var result = geoService.getAllProvinces();

            assertThat(result).isEmpty();
        }
    }

    @Nested
    @DisplayName("getCommunesByProvince")
    class GetCommunesByProvince {

        @Test
        @DisplayName("should return communes for valid province code")
        void shouldReturnCommunesForValidProvince() {
            AdministrativeUnit province = createUnit(1L, "Hanoi", "01", KIND_PROVINCE, null);
            AdministrativeUnit commune = createUnit(2L, "Ba Dinh", "001", KIND_COMMUNE, "01");

            when(repository.findByCode("01")).thenReturn(Optional.of(province));
            when(repository.findByParentCode("01")).thenReturn(List.of(commune));
            when(geoMapper.toSummaryDtoList(any())).thenReturn(List.of(
                    com.vnmap.geo.dto.AdministrativeUnitSummaryDto.builder()
                            .id(2L)
                            .code("001")
                            .name("Ba Dinh")
                            .kind(KIND_COMMUNE)
                            .parentCode("01")
                            .build()
            ));

            var result = geoService.getCommunesByProvince("01");

            assertThat(result).hasSize(1);
            assertThat(result.get(0).getName()).isEqualTo("Ba Dinh");
        }

        @Test
        @DisplayName("should throw ResourceNotFoundException when province not found")
        void shouldThrowWhenProvinceNotFound() {
            when(repository.findByCode("invalid")).thenReturn(Optional.empty());

            assertThatThrownBy(() -> geoService.getCommunesByProvince("invalid"))
                    .isInstanceOf(com.vnmap.common.exception.ResourceNotFoundException.class)
                    .hasMessageContaining("Province");
        }

        @Test
        @DisplayName("should throw IllegalArgumentException when code is not a province")
        void shouldThrowWhenCodeIsNotProvince() {
            AdministrativeUnit commune = createUnit(2L, "Ba Dinh", "001", KIND_COMMUNE, "01");
            when(repository.findByCode("001")).thenReturn(Optional.of(commune));

            assertThatThrownBy(() -> geoService.getCommunesByProvince("001"))
                    .isInstanceOf(IllegalArgumentException.class)
                    .hasMessageContaining("not a province");
        }
    }

    @Nested
    @DisplayName("getCommunesByMacroRegion")
    class GetCommunesByMacroRegion {

        @Test
        @DisplayName("should return communes for valid macro-region")
        void shouldReturnCommunesForValidMacroRegion() {
            AdministrativeUnit province = createUnit(1L, "Hanoi", "01", KIND_PROVINCE, null);
            AdministrativeUnit commune = createUnit(2L, "Ba Dinh", "001", KIND_COMMUNE, "01");

            when(repository.findByMacroRegion("North Delta")).thenReturn(List.of(province));
            when(repository.findByKind(KIND_COMMUNE)).thenReturn(List.of(commune));
            when(geoMapper.toSummaryDtoList(any())).thenReturn(List.of(
                    com.vnmap.geo.dto.AdministrativeUnitSummaryDto.builder()
                            .id(2L)
                            .code("001")
                            .name("Ba Dinh")
                            .kind(KIND_COMMUNE)
                            .build()
            ));

            var result = geoService.getCommunesByMacroRegion("North Delta");

            assertThat(result).hasSize(1);
        }

        @Test
        @DisplayName("should throw ResourceNotFoundException when macro-region not found")
        void shouldThrowWhenMacroRegionNotFound() {
            when(repository.findByMacroRegion("Invalid Region")).thenReturn(List.of());

            assertThatThrownBy(() -> geoService.getCommunesByMacroRegion("Invalid Region"))
                    .isInstanceOf(com.vnmap.common.exception.ResourceNotFoundException.class)
                    .hasMessageContaining("MacroRegion");
        }
    }

    @Nested
    @DisplayName("getByCode")
    class GetByCode {

        @Test
        @DisplayName("should return unit for valid code")
        void shouldReturnUnitForValidCode() {
            AdministrativeUnit unit = createUnit(1L, "Hanoi", "01", KIND_PROVINCE, null);
            AdministrativeUnitDto dto = createDto(1L, "Hanoi", "01", KIND_PROVINCE);

            when(repository.findByCode("01")).thenReturn(Optional.of(unit));
            when(geoMapper.toDto(unit)).thenReturn(dto);
            when(repository.countByParentCode("01")).thenReturn(0);

            AdministrativeUnitDto result = geoService.getByCode("01");

            assertThat(result.getCode()).isEqualTo("01");
            assertThat(result.getName()).isEqualTo("Hanoi");
        }

        @Test
        @DisplayName("should throw ResourceNotFoundException when unit not found")
        void shouldThrowWhenUnitNotFound() {
            when(repository.findByCode("invalid")).thenReturn(Optional.empty());

            assertThatThrownBy(() -> geoService.getByCode("invalid"))
                    .isInstanceOf(com.vnmap.common.exception.ResourceNotFoundException.class)
                    .hasMessageContaining("AdministrativeUnit");
        }

        @Test
        @DisplayName("should set child count")
        void shouldSetChildCount() {
            AdministrativeUnit commune = createUnit(2L, "Ba Dinh", "001", KIND_COMMUNE, "01");
            AdministrativeUnitDto dto = createDto(2L, "Ba Dinh", "001", KIND_COMMUNE);

            when(repository.findByCode("001")).thenReturn(Optional.of(commune));
            when(geoMapper.toDto(commune)).thenReturn(dto);
            when(repository.countByParentCode("001")).thenReturn(5);

            AdministrativeUnitDto result = geoService.getByCode("001");

            assertThat(result.getChildCount()).isEqualTo(5);
        }
    }

    @Nested
    @DisplayName("getBoundaryByCode")
    class GetBoundaryByCode {

        @Test
        @DisplayName("should return boundary for province code")
        void shouldReturnBoundaryForProvince() {
            AdministrativeUnit unit = createUnit(1L, "Hanoi", "01", KIND_PROVINCE, null);
            String geoJson = "{\"type\":\"Polygon\",\"coordinates\":[[[105.0,21.0],[105.5,21.0],[105.5,21.5],[105.0,21.5],[105.0,21.0]]]}";

            when(repository.findByCode("01")).thenReturn(Optional.of(unit));
            when(repository.findBoundaryByCodeAndKind("01", KIND_PROVINCE)).thenReturn(Optional.of(geoJson));

            GeoJsonFeatureDto result = geoService.getBoundaryByCode("01");

            assertThat(result.getCode()).isEqualTo("01");
            assertThat(result.getKind()).isEqualTo(KIND_PROVINCE);
            assertThat(result.getGeometry()).isNotNull();
        }

        @Test
        @DisplayName("should throw ResourceNotFoundException when unit not found")
        void shouldThrowWhenUnitNotFound() {
            when(repository.findByCode("invalid")).thenReturn(Optional.empty());

            assertThatThrownBy(() -> geoService.getBoundaryByCode("invalid"))
                    .isInstanceOf(com.vnmap.common.exception.ResourceNotFoundException.class);
        }
    }

    @Nested
    @DisplayName("findUnitByCoordinate")
    class FindUnitByCoordinate {

        @Test
        @DisplayName("should return commune for valid coordinates")
        void shouldReturnCommuneForCoordinates() {
            AdministrativeUnit commune = createUnit(2L, "Ba Dinh", "001", KIND_COMMUNE, "01");
            AdministrativeUnitDto dto = createDto(2L, "Ba Dinh", "001", KIND_COMMUNE);

            when(repository.findUnitContainingPoint(21.03, 105.85)).thenReturn(Optional.of(commune));
            when(geoMapper.toDto(commune)).thenReturn(dto);
            when(repository.countByParentCode("001")).thenReturn(0);

            AdministrativeUnitDto result = geoService.findUnitByCoordinate(21.03, 105.85);

            assertThat(result.getCode()).isEqualTo("001");
            assertThat(result.getKind()).isEqualTo(KIND_COMMUNE);
        }

        @Test
        @DisplayName("should throw ResourceNotFoundException when no unit at coordinates")
        void shouldThrowWhenNoUnitAtCoordinates() {
            when(repository.findUnitContainingPoint(anyDouble(), anyDouble())).thenReturn(Optional.empty());

            assertThatThrownBy(() -> geoService.findUnitByCoordinate(99.0, 99.0))
                    .isInstanceOf(com.vnmap.common.exception.ResourceNotFoundException.class)
                    .hasMessageContaining("coordinates");
        }
    }

    @Nested
    @DisplayName("getAllProvincesBoundaries")
    class GetAllProvincesBoundaries {

        @Test
        @DisplayName("should return FeatureCollection for provinces")
        void shouldReturnFeatureCollection() {
            AdministrativeUnit province = createUnit(1L, "Hanoi", "01", KIND_PROVINCE, null);
            String geoJson = "{\"type\":\"Polygon\",\"coordinates\":[[[105,21],[105.5,21],[105.5,21.5],[105,21.5],[105,21]]]}";

            when(repository.findByKind(KIND_PROVINCE)).thenReturn(List.of(province));
            when(repository.findBoundaryByCodeAndKind("01", KIND_PROVINCE)).thenReturn(Optional.of(geoJson));

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
            AdministrativeUnit province = createUnit(1L, "Hanoi", "01", KIND_PROVINCE, null);

            when(repository.findByKind(KIND_PROVINCE)).thenReturn(List.of(province));
            when(repository.findBoundaryByCodeAndKind("01", KIND_PROVINCE)).thenReturn(Optional.empty());

            Object result = geoService.getAllProvincesBoundaries();

            @SuppressWarnings("unchecked")
            Map<String, Object> collection = (Map<String, Object>) result;
            @SuppressWarnings("unchecked")
            List<?> features = (List<?>) collection.get("features");
            assertThat(features).isEmpty();
        }
    }

    @Nested
    @DisplayName("getCommunesBoundariesByProvinceCode")
    class GetCommunesBoundariesByProvinceCode {

        @Test
        @DisplayName("should return commune features for valid province")
        void shouldReturnCommuneFeatures() {
            Object[] row = new Object[] {
                    2L, "Ba Dinh", "001", KIND_COMMUNE, "01",
                    "{\"type\":\"Polygon\",\"coordinates\":[[[105.8,21.0],[105.9,21.0],[105.9,21.1],[105.8,21.1]]]}"
            };

            when(repository.findByCode("01")).thenReturn(Optional.of(createUnit(1L, "Hanoi", "01", KIND_PROVINCE, null)));
            when(repository.findCommunesWithBoundariesByProvinceCode("01")).thenReturn(Collections.singletonList(row));

            List<GeoJsonFeatureDto> result = geoService.getCommunesBoundariesByProvinceCode("01");

            assertThat(result).hasSize(1);
            assertThat(result.get(0).getCode()).isEqualTo("001");
            assertThat(result.get(0).getName()).isEqualTo("Ba Dinh");
            assertThat(result.get(0).getKind()).isEqualTo(KIND_COMMUNE);
        }

        @Test
        @DisplayName("should throw when province not found")
        void shouldThrowWhenProvinceNotFound() {
            when(repository.findByCode("invalid")).thenReturn(Optional.empty());

            assertThatThrownBy(() -> geoService.getCommunesBoundariesByProvinceCode("invalid"))
                    .isInstanceOf(com.vnmap.common.exception.ResourceNotFoundException.class);
        }
    }

    @Nested
    @DisplayName("getAllCommittees")
    class GetAllCommittees {

        @Test
        @DisplayName("should return all committees")
        void shouldReturnAllCommittees() {
            CommitteeLocation committee = createCommittee(1L, "UBND Ba Đình", "001", "01");
            when(committeeRepository.findAll()).thenReturn(List.of(committee));
            when(geoMapper.toCommitteeDtoList(any())).thenReturn(List.of(
                    com.vnmap.geo.dto.CommitteeLocationDto.builder()
                            .id(1L)
                            .code("001")
                            .name("UBND Ba Đình")
                            .parentCode("01")
                            .build()
            ));

            var result = geoService.getAllCommittees();

            assertThat(result).hasSize(1);
            verify(committeeRepository).findAll();
        }
    }

    @Nested
    @DisplayName("getCommitteesByProvince")
    class GetCommitteesByProvince {

        @Test
        @DisplayName("should return committees for province")
        void shouldReturnCommitteesForProvince() {
            CommitteeLocation committee = createCommittee(1L, "UBND Ba Đình", "001", "01");
            when(committeeRepository.findByParentCode("01")).thenReturn(List.of(committee));
            when(geoMapper.toCommitteeDtoList(any())).thenReturn(List.of(
                    com.vnmap.geo.dto.CommitteeLocationDto.builder()
                            .id(1L)
                            .code("001")
                            .name("UBND Ba Đình")
                            .parentCode("01")
                            .build()
            ));

            var result = geoService.getCommitteesByProvince("01");

            assertThat(result).hasSize(1);
            verify(committeeRepository).findByParentCode("01");
        }
    }

    @Nested
    @DisplayName("evictAllGeoCache")
    class EvictAllGeoCache {

        @Test
        @DisplayName("should clear geo cache")
        void shouldClearGeoCache() {
            when(cacheManager.getCache("geo")).thenReturn(cache);

            geoService.evictAllGeoCache();

            verify(cache).clear();
        }

        @Test
        @DisplayName("should handle missing cache gracefully")
        void shouldHandleMissingCache() {
            when(cacheManager.getCache("geo")).thenReturn(null);

            geoService.evictAllGeoCache();
        }
    }

    private AdministrativeUnit createUnit(Long id, String name, String code, String kind, String parentCode) {
        return AdministrativeUnit.builder()
                .id(id)
                .name(name)
                .code(code)
                .kind(kind)
                .parentCode(parentCode)
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

    private CommitteeLocation createCommittee(Long id, String name, String code, String parentCode) {
        return CommitteeLocation.builder()
                .id(id)
                .name(name)
                .code(code)
                .parentCode(parentCode)
                .build();
    }
}
