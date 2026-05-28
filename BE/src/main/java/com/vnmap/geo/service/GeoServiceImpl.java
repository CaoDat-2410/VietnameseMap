package com.vnmap.geo.service;

import com.vnmap.common.exception.ResourceNotFoundException;
import com.vnmap.geo.dto.AdministrativeUnitDto;
import com.vnmap.geo.dto.AdministrativeUnitSummaryDto;
import com.vnmap.geo.dto.GeoJsonFeatureDto;
import com.vnmap.geo.entity.AdministrativeUnit;
import com.vnmap.geo.enums.UnitLevel;
import com.vnmap.geo.mapper.GeoMapper;
import com.vnmap.geo.repository.AdministrativeUnitRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Transactional(readOnly = true)
public class GeoServiceImpl implements GeoService {

    private static final Logger log = LoggerFactory.getLogger(GeoServiceImpl.class);

    private final AdministrativeUnitRepository repository;
    private final GeoMapper geoMapper;

    public GeoServiceImpl(AdministrativeUnitRepository repository, GeoMapper geoMapper) {
        this.repository = repository;
        this.geoMapper = geoMapper;
    }

    @Override
    @Cacheable(value = "geo", key = "'provinces'")
    public List<AdministrativeUnitSummaryDto> getAllProvinces() {
        log.debug("Fetching all provinces");
        List<AdministrativeUnit> provinces = repository.findByLevel(UnitLevel.PROVINCE);
        return geoMapper.toSummaryDtoList(provinces);
    }

    @Override
    @Cacheable(value = "geo", key = "'districts:' + #provinceCode")
    public List<AdministrativeUnitSummaryDto> getDistrictsByProvince(String provinceCode) {
        log.debug("Fetching districts for province: {}", provinceCode);

        AdministrativeUnit province = repository.findByCode(provinceCode)
                .orElseThrow(() -> new ResourceNotFoundException("Province", "code", provinceCode));

        if (province.getLevel() != UnitLevel.PROVINCE) {
            throw new IllegalArgumentException("Code '" + provinceCode + "' is not a province code");
        }

        List<AdministrativeUnit> districts = repository.findByParentIdAndLevel(province.getId(), UnitLevel.DISTRICT);
        return geoMapper.toSummaryDtoList(districts);
    }

    @Override
    @Cacheable(value = "geo", key = "'wards:' + #districtCode")
    public List<AdministrativeUnitSummaryDto> getWardsByDistrict(String districtCode) {
        log.debug("Fetching wards for district: {}", districtCode);

        AdministrativeUnit district = repository.findByCode(districtCode)
                .orElseThrow(() -> new ResourceNotFoundException("District", "code", districtCode));

        if (district.getLevel() != UnitLevel.DISTRICT) {
            throw new IllegalArgumentException("Code '" + districtCode + "' is not a district code");
        }

        List<AdministrativeUnit> wards = repository.findByParentIdAndLevel(district.getId(), UnitLevel.WARD);
        return geoMapper.toSummaryDtoList(wards);
    }

    @Override
    public AdministrativeUnitDto getByCode(String code) {
        log.debug("Fetching administrative unit by code: {}", code);

        AdministrativeUnit unit = repository.findByCode(code)
                .orElseThrow(() -> new ResourceNotFoundException("AdministrativeUnit", "code", code));

        AdministrativeUnitDto dto = geoMapper.toDto(unit);

        if (unit.getParentId() != null) {
            repository.findById(unit.getParentId())
                    .ifPresent(parent -> dto.setParentCode(parent.getCode()));
        }

        dto.setChildCount(repository.countByParentId(unit.getId()));

        return dto;
    }

    @Override
    public GeoJsonFeatureDto getBoundaryByCode(String code) {
        log.debug("Boundary feature not available - no geometry data");
        throw new ResourceNotFoundException("Boundary", "code", code);
    }

    @Override
    public AdministrativeUnitDto findUnitByCoordinate(double lat, double lng) {
        log.debug("Reverse geocoding not available - no geometry data");
        throw new ResourceNotFoundException("Feature", "coordinates", String.format("(%.4f, %.4f)", lat, lng));
    }
}
