package com.vnmap.geo;

import com.vnmap.common.exception.ResourceNotFoundException;
import com.vnmap.geo.dto.AdministrativeUnitDto;
import com.vnmap.geo.dto.AdministrativeUnitSummaryDto;
import com.vnmap.geo.entity.AdministrativeUnit;
import com.vnmap.geo.entity.CommitteeLocation;
import com.vnmap.geo.mapper.GeoMapper;
import com.vnmap.geo.repository.AdministrativeUnitRepository;
import com.vnmap.geo.repository.CommitteeLocationRepository;
import com.vnmap.geo.service.GeoService;
import com.vnmap.geo.service.GeoServiceImpl;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.cache.CacheManager;

import java.util.Arrays;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
@DisplayName("GeoService Tests (2025 Reform)")
class GeoServiceTest {

    @Mock
    private AdministrativeUnitRepository repository;

    @Mock
    private CommitteeLocationRepository committeeRepository;

    @Mock
    private GeoMapper geoMapper;

    @Mock
    private CacheManager cacheManager;

    private GeoService geoService;

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
        @DisplayName("should return list of province summaries")
        void shouldReturnProvinceSummaries() {
            AdministrativeUnit hanoi = createUnit(1L, "Hà Nội", "01", KIND_PROVINCE, null);
            AdministrativeUnit hcm = createUnit(2L, "Hồ Chí Minh", "79", KIND_PROVINCE, null);

            AdministrativeUnitSummaryDto hanoiDto = createSummaryDto("01", "Hà Nội", KIND_PROVINCE);
            AdministrativeUnitSummaryDto hcmDto = createSummaryDto("79", "Hồ Chí Minh", KIND_PROVINCE);

            when(repository.findByKind(KIND_PROVINCE)).thenReturn(Arrays.asList(hanoi, hcm));
            when(geoMapper.toSummaryDtoList(any())).thenReturn(Arrays.asList(hanoiDto, hcmDto));

            List<AdministrativeUnitSummaryDto> result = geoService.getAllProvinces();

            assertThat(result).hasSize(2);
            assertThat(result.get(0).getCode()).isEqualTo("01");
            assertThat(result.get(1).getCode()).isEqualTo("79");
            verify(repository).findByKind(KIND_PROVINCE);
        }

        @Test
        @DisplayName("should return empty list when no provinces exist")
        void shouldReturnEmptyListWhenNoProvinces() {
            when(repository.findByKind(KIND_PROVINCE)).thenReturn(List.of());
            when(geoMapper.toSummaryDtoList(any())).thenReturn(List.of());

            List<AdministrativeUnitSummaryDto> result = geoService.getAllProvinces();

            assertThat(result).isEmpty();
        }
    }

    @Nested
    @DisplayName("getCommunesByProvince")
    class GetCommunesByProvince {

        @Test
        @DisplayName("should return communes for valid province code")
        void shouldReturnCommunesForValidProvince() {
            AdministrativeUnit province = createUnit(1L, "Hà Nội", "01", KIND_PROVINCE, null);
            AdministrativeUnit commune1 = createUnit(2L, "Ba Đình", "001", KIND_COMMUNE, "01");
            AdministrativeUnit commune2 = createUnit(3L, "Hoàn Kiếm", "002", KIND_COMMUNE, "01");

            when(repository.findByCode("01")).thenReturn(Optional.of(province));
            when(repository.findByParentCode("01")).thenReturn(Arrays.asList(commune1, commune2));
            when(geoMapper.toSummaryDtoList(any())).thenReturn(List.of(
                    createSummaryDto("001", "Ba Đình", KIND_COMMUNE),
                    createSummaryDto("002", "Hoàn Kiếm", KIND_COMMUNE)
            ));

            List<AdministrativeUnitSummaryDto> result = geoService.getCommunesByProvince("01");

            assertThat(result).hasSize(2);
            assertThat(result.get(0).getCode()).isEqualTo("001");
        }

        @Test
        @DisplayName("should throw exception for invalid province code")
        void shouldThrowForInvalidProvinceCode() {
            when(repository.findByCode("999")).thenReturn(Optional.empty());

            assertThatThrownBy(() -> geoService.getCommunesByProvince("999"))
                    .isInstanceOf(ResourceNotFoundException.class)
                    .hasMessageContaining("Province")
                    .hasMessageContaining("999");
        }

        @Test
        @DisplayName("should throw exception when code is not a province")
        void shouldThrowWhenCodeIsNotProvince() {
            AdministrativeUnit commune = createUnit(2L, "Ba Đình", "001", KIND_COMMUNE, "01");
            when(repository.findByCode("001")).thenReturn(Optional.of(commune));

            assertThatThrownBy(() -> geoService.getCommunesByProvince("001"))
                    .isInstanceOf(IllegalArgumentException.class)
                    .hasMessageContaining("not a province");
        }
    }

    @Nested
    @DisplayName("getByCode")
    class GetByCode {

        @Test
        @DisplayName("should return unit details for valid code")
        void shouldReturnUnitForValidCode() {
            AdministrativeUnit unit = createUnit(1L, "Hà Nội", "01", KIND_PROVINCE, null);
            AdministrativeUnitDto dto = createDto(1L, "Hà Nội", "01", KIND_PROVINCE);

            when(repository.findByCode("01")).thenReturn(Optional.of(unit));
            when(geoMapper.toDto(unit)).thenReturn(dto);
            when(repository.countByParentCode("01")).thenReturn(30);

            AdministrativeUnitDto result = geoService.getByCode("01");

            assertThat(result.getCode()).isEqualTo("01");
            assertThat(result.getName()).isEqualTo("Hà Nội");
            assertThat(result.getChildCount()).isEqualTo(30);
        }

        @Test
        @DisplayName("should throw exception for non-existent code")
        void shouldThrowForNonExistentCode() {
            when(repository.findByCode("999")).thenReturn(Optional.empty());

            assertThatThrownBy(() -> geoService.getByCode("999"))
                    .isInstanceOf(ResourceNotFoundException.class)
                    .hasMessageContaining("999");
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

    private AdministrativeUnit createUnit(Long id, String name, String code, String kind, String parentCode) {
        return AdministrativeUnit.builder()
                .id(id)
                .name(name)
                .code(code)
                .kind(kind)
                .parentCode(parentCode)
                .build();
    }

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

    private CommitteeLocation createCommittee(Long id, String name, String code, String parentCode) {
        return CommitteeLocation.builder()
                .id(id)
                .name(name)
                .code(code)
                .parentCode(parentCode)
                .build();
    }
}
