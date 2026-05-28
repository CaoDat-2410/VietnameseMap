package com.vnmap.geo;

import com.vnmap.common.exception.ResourceNotFoundException;
import com.vnmap.geo.dto.AdministrativeUnitDto;
import com.vnmap.geo.dto.AdministrativeUnitSummaryDto;
import com.vnmap.geo.entity.AdministrativeUnit;
import com.vnmap.geo.enums.UnitLevel;
import com.vnmap.geo.mapper.GeoMapper;
import com.vnmap.geo.repository.AdministrativeUnitRepository;
import com.vnmap.geo.service.GeoService;
import com.vnmap.geo.service.GeoServiceImpl;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Arrays;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
@DisplayName("GeoService Tests")
class GeoServiceTest {

    @Mock
    private AdministrativeUnitRepository repository;

    @Mock
    private GeoMapper geoMapper;

    private GeoService geoService;

    @BeforeEach
    void setUp() {
        geoService = new GeoServiceImpl(repository, geoMapper);
    }

    @Nested
    @DisplayName("getAllProvinces")
    class GetAllProvinces {

        @Test
        @DisplayName("should return list of province summaries")
        void shouldReturnProvinceSummaries() {
            AdministrativeUnit hanoi = createUnit(1L, "Hà Nội", "01", UnitLevel.PROVINCE, null);
            AdministrativeUnit hcm = createUnit(2L, "Hồ Chí Minh", "79", UnitLevel.PROVINCE, null);

            AdministrativeUnitSummaryDto hanoiDto = createSummaryDto("01", "Hà Nội", UnitLevel.PROVINCE);
            AdministrativeUnitSummaryDto hcmDto = createSummaryDto("79", "Hồ Chí Minh", UnitLevel.PROVINCE);

            when(repository.findByLevel(UnitLevel.PROVINCE)).thenReturn(Arrays.asList(hanoi, hcm));
            when(geoMapper.toSummaryDtoList(any())).thenReturn(Arrays.asList(hanoiDto, hcmDto));

            List<AdministrativeUnitSummaryDto> result = geoService.getAllProvinces();

            assertThat(result).hasSize(2);
            assertThat(result.get(0).getCode()).isEqualTo("01");
            assertThat(result.get(1).getCode()).isEqualTo("79");
            verify(repository).findByLevel(UnitLevel.PROVINCE);
        }

        @Test
        @DisplayName("should return empty list when no provinces exist")
        void shouldReturnEmptyListWhenNoProvinces() {
            when(repository.findByLevel(UnitLevel.PROVINCE)).thenReturn(List.of());
            when(geoMapper.toSummaryDtoList(any())).thenReturn(List.of());

            List<AdministrativeUnitSummaryDto> result = geoService.getAllProvinces();

            assertThat(result).isEmpty();
        }
    }

    @Nested
    @DisplayName("getDistrictsByProvince")
    class GetDistrictsByProvince {

        @Test
        @DisplayName("should return districts for valid province code")
        void shouldReturnDistrictsForValidProvince() {
            AdministrativeUnit province = createUnit(1L, "Hà Nội", "01", UnitLevel.PROVINCE, null);
            AdministrativeUnit district1 = createUnit(2L, "Ba Đình", "001", UnitLevel.DISTRICT, 1L);
            AdministrativeUnit district2 = createUnit(3L, "Hoàn Kiếm", "002", UnitLevel.DISTRICT, 1L);

            when(repository.findByCode("01")).thenReturn(Optional.of(province));
            when(repository.findByParentIdAndLevel(1L, UnitLevel.DISTRICT))
                    .thenReturn(Arrays.asList(district1, district2));
            when(geoMapper.toSummaryDtoList(any())).thenReturn(List.of(
                    createSummaryDto("001", "Ba Đình", UnitLevel.DISTRICT),
                    createSummaryDto("002", "Hoàn Kiếm", UnitLevel.DISTRICT)
            ));

            List<AdministrativeUnitSummaryDto> result = geoService.getDistrictsByProvince("01");

            assertThat(result).hasSize(2);
            assertThat(result.get(0).getCode()).isEqualTo("001");
        }

        @Test
        @DisplayName("should throw exception for invalid province code")
        void shouldThrowForInvalidProvinceCode() {
            when(repository.findByCode("999")).thenReturn(Optional.empty());

            assertThatThrownBy(() -> geoService.getDistrictsByProvince("999"))
                    .isInstanceOf(ResourceNotFoundException.class)
                    .hasMessageContaining("Province")
                    .hasMessageContaining("999");
        }

        @Test
        @DisplayName("should throw exception when code is not a province")
        void shouldThrowWhenCodeIsNotProvince() {
            AdministrativeUnit district = createUnit(2L, "Ba Đình", "001", UnitLevel.DISTRICT, 1L);
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
        @DisplayName("should return unit details for valid code")
        void shouldReturnUnitForValidCode() {
            AdministrativeUnit unit = createUnit(1L, "Hà Nội", "01", UnitLevel.PROVINCE, null);
            AdministrativeUnitDto dto = createDto(1L, "Hà Nội", "01", UnitLevel.PROVINCE);

            when(repository.findByCode("01")).thenReturn(Optional.of(unit));
            when(geoMapper.toDto(unit)).thenReturn(dto);
            when(repository.countByParentId(1L)).thenReturn(30);

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

    private AdministrativeUnit createUnit(Long id, String name, String code, UnitLevel level, Long parentId) {
        return AdministrativeUnit.builder()
                .id(id)
                .name(name)
                .code(code)
                .level(level)
                .parentId(parentId)
                .build();
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
