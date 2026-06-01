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
import java.util.Map;
import java.util.HashMap;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

@Service
@Transactional(readOnly = true)
public class GeoServiceImpl implements GeoService {

    private static final Logger log = LoggerFactory.getLogger(GeoServiceImpl.class);

    private final AdministrativeUnitRepository repository;
    private final GeoMapper geoMapper;
    private final ObjectMapper objectMapper;

    public GeoServiceImpl(AdministrativeUnitRepository repository, GeoMapper geoMapper, ObjectMapper objectMapper) {
        this.repository = repository;
        this.geoMapper = geoMapper;
        this.objectMapper = objectMapper;
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

        if (unit.getCentroid() != null) {
            dto.setCentroidLat(unit.getCentroid().getY());
            dto.setCentroidLng(unit.getCentroid().getX());
        } else {
            repository.findCentroidByCode(code)
                    .ifPresent(row -> {
                        Object[] arr = (Object[]) row;
                        if (arr[1] != null) dto.setCentroidLat(((Number) arr[1]).doubleValue());
                        if (arr[0] != null) dto.setCentroidLng(((Number) arr[0]).doubleValue());
                    });
        }

        return dto;
    }

    @Override
    @Cacheable(value = "geo", key = "'boundary:' + #code")
    public GeoJsonFeatureDto getBoundaryByCode(String code) {
        log.debug("Fetching boundary for unit: {}", code);

        AdministrativeUnit unit = repository.findByCode(code)
                .orElseThrow(() -> new ResourceNotFoundException("AdministrativeUnit", "code", code));

        String geoJson = repository.findBoundaryGeoJsonByCode(code)
                .orElseThrow(() -> new ResourceNotFoundException("Boundary", "code", code));

        String parentCode = null;
        if (unit.getParentId() != null) {
            parentCode = repository.findById(unit.getParentId())
                    .map(AdministrativeUnit::getCode)
                    .orElse(null);
        }

        GeoJsonFeatureDto feature = GeoJsonFeatureDto.builder()
                .type("Feature")
                .code(unit.getCode())
                .name(unit.getName())
                .level(unit.getLevel())
                .parentCode(parentCode)
                .build();

        try {
            JsonNode root = objectMapper.readTree(geoJson);
            String type = root.path("type").asText("Polygon");
            JsonNode coordsNode = root.path("coordinates");
            if (coordsNode.isMissingNode() || !coordsNode.isArray()) {
                log.warn("No valid coordinates found in GeoJSON for code: {}", code);
            }
            feature.setGeometry(GeoJsonFeatureDto.GeometryDto.builder()
                    .type(type)
                    .coordinates(objectMapper.convertValue(coordsNode, Object.class))
                    .build());
        } catch (Exception e) {
            log.error("Failed to parse GeoJSON for code: {}: {}", code, e.getMessage());
            feature.setGeometry(GeoJsonFeatureDto.GeometryDto.builder()
                    .type("Polygon")
                    .coordinates(geoJson)
                    .build());
        }

        return feature;
    }

    @Override
    @Cacheable(value = "geo", key = "'reverse:' + #lat + ':' + #lng")
    public AdministrativeUnitDto findUnitByCoordinate(double lat, double lng) {
        log.debug("Reverse geocoding for coordinates: lat={}, lng={}", lat, lng);

        AdministrativeUnit unit = repository.findUnitContainingPoint(lat, lng)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "AdministrativeUnit", "coordinates", String.format("(%.4f, %.4f)", lat, lng)));

        AdministrativeUnitDto dto = geoMapper.toDto(unit);

        if (unit.getParentId() != null) {
            repository.findById(unit.getParentId())
                    .ifPresent(parent -> dto.setParentCode(parent.getCode()));
        }

        if (unit.getCentroid() != null) {
            dto.setCentroidLat(unit.getCentroid().getY());
            dto.setCentroidLng(unit.getCentroid().getX());
        } else {
            repository.findCentroidByCode(unit.getCode())
                    .ifPresent(row -> {
                        Object[] arr = (Object[]) row;
                        if (arr[1] != null) dto.setCentroidLat(((Number) arr[1]).doubleValue());
                        if (arr[0] != null) dto.setCentroidLng(((Number) arr[0]).doubleValue());
                    });
        }

        dto.setChildCount(repository.countByParentId(unit.getId()));

        return dto;
    }

    @Transactional
    public int calculateCentroids() {
        log.info("Calculating centroids for all units");
        int count = 0;
        List<AdministrativeUnit> units = repository.findAll();
        for (AdministrativeUnit unit : units) {
            if (unit.getBoundary() != null && unit.getCentroid() == null) {
                unit.setCentroid(unit.getBoundary().getCentroid());
                repository.save(unit);
                count++;
            }
        }
        log.info("Calculated {} centroids", count);
        return count;
    }
}
