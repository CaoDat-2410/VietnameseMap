package com.vnmap.geo.service;

import com.vnmap.common.exception.ResourceNotFoundException;
import com.vnmap.geo.dto.AdministrativeUnitDto;
import com.vnmap.geo.dto.AdministrativeUnitSummaryDto;
import com.vnmap.geo.dto.CommitteeLocationDto;
import com.vnmap.geo.dto.GeoJsonFeatureDto;
import com.vnmap.geo.entity.AdministrativeUnit;
import com.vnmap.geo.entity.CommitteeLocation;
import com.vnmap.geo.mapper.GeoMapper;
import com.vnmap.geo.repository.AdministrativeUnitRepository;
import com.vnmap.geo.repository.CommitteeLocationRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.cache.CacheManager;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.Optional;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

@Service
@Transactional(readOnly = true)
public class GeoServiceImpl implements GeoService {

    private static final Logger log = LoggerFactory.getLogger(GeoServiceImpl.class);
    private static final String FEATURE_TYPE = "Feature";
    private static final String POLYGON_TYPE = "Polygon";
    private static final String COORDINATES_KEY = "coordinates";
    private static final String KIND_PROVINCE = "province";
    private static final String KIND_COMMUNE = "commune";

    private final AdministrativeUnitRepository repository;
    private final CommitteeLocationRepository committeeRepository;
    private final GeoMapper geoMapper;
    private final ObjectMapper objectMapper;
    private final CacheManager cacheManager;

    public GeoServiceImpl(AdministrativeUnitRepository repository,
                          CommitteeLocationRepository committeeRepository,
                          GeoMapper geoMapper,
                          ObjectMapper objectMapper,
                          CacheManager cacheManager) {
        this.repository = repository;
        this.committeeRepository = committeeRepository;
        this.geoMapper = geoMapper;
        this.objectMapper = objectMapper;
        this.cacheManager = cacheManager;
    }

    @Override
    @Cacheable(value = "geo", key = "'provinces'")
    public List<AdministrativeUnitSummaryDto> getAllProvinces() {
        log.debug("Fetching all provinces");
        List<AdministrativeUnit> provinces = repository.findByKind(KIND_PROVINCE);
        return geoMapper.toSummaryDtoList(provinces);
    }

    @Override
    public List<AdministrativeUnitSummaryDto> getCommunesByProvince(String provinceCode) {
        log.debug("Fetching communes for province: {}", provinceCode);

        AdministrativeUnit province = repository.findByCode(provinceCode)
                .orElseThrow(() -> new ResourceNotFoundException("Province", "code", provinceCode));

        if (!KIND_PROVINCE.equals(province.getKind())) {
            throw new IllegalArgumentException("Code '" + provinceCode + "' is not a province code");
        }

        List<AdministrativeUnit> communes = repository.findByParentCode(provinceCode);
        return geoMapper.toSummaryDtoList(communes);
    }

    @Override
    public List<AdministrativeUnitSummaryDto> getCommunesByMacroRegion(String macroRegion) {
        log.debug("Fetching communes for macro-region: {}", macroRegion);

        List<AdministrativeUnit> provinces = repository.findByMacroRegion(macroRegion);
        if (provinces.isEmpty()) {
            throw new ResourceNotFoundException("MacroRegion", "name", macroRegion);
        }

        List<AdministrativeUnit> communes = repository.findByKind(KIND_COMMUNE);
        List<String> provinceCodes = provinces.stream().map(AdministrativeUnit::getCode).toList();
        List<AdministrativeUnit> filteredCommunes = communes.stream()
                .filter(c -> c.getParentCode() != null && provinceCodes.contains(c.getParentCode()))
                .toList();

        return geoMapper.toSummaryDtoList(filteredCommunes);
    }

    @Override
    public AdministrativeUnitDto getByCode(String code) {
        log.debug("Fetching administrative unit by code: {}", code);

        AdministrativeUnit unit = repository.findByCode(code)
                .orElseThrow(() -> new ResourceNotFoundException("AdministrativeUnit", "code", code));

        AdministrativeUnitDto dto = geoMapper.toDto(unit);
        dto.setParentCode(unit.getParentCode());
        dto.setChildCount(repository.countByParentCode(unit.getCode()));

        if (unit.getCentroid() != null) {
            dto.setCentroidLat(unit.getCentroid().getY());
            dto.setCentroidLng(unit.getCentroid().getX());
        } else {
            repository.findCentroidByCode(code, unit.getKind())
                    .ifPresent(row -> {
                        @SuppressWarnings("unchecked")
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

        Optional<AdministrativeUnit> unitOpt = repository.findByCode(code);
        if (unitOpt.isEmpty()) {
            throw new ResourceNotFoundException("AdministrativeUnit", "code", code);
        }
        AdministrativeUnit unit = unitOpt.get();

        Optional<String> boundaryOpt = repository.findBoundaryByCodeAndKind(code, unit.getKind());
        if (boundaryOpt.isEmpty()) {
            throw new ResourceNotFoundException("Boundary", "code", code);
        }
        String boundaryJson = boundaryOpt.get();

        GeoJsonFeatureDto feature = GeoJsonFeatureDto.builder()
                .id(unit.getId())
                .type(FEATURE_TYPE)
                .code(unit.getCode())
                .name(unit.getName())
                .kind(unit.getKind())
                .parentCode(unit.getParentCode())
                .build();

        try {
            JsonNode root = objectMapper.readTree(boundaryJson);
            String type = root.path("type").asText(POLYGON_TYPE);
            JsonNode coordsNode = root.path(COORDINATES_KEY);
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
                    .type(POLYGON_TYPE)
                    .coordinates(boundaryJson)
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
                        "AdministrativeUnit", COORDINATES_KEY, String.format("(%.4f, %.4f)", lat, lng)));

        AdministrativeUnitDto dto = geoMapper.toDto(unit);
        dto.setParentCode(unit.getParentCode());
        dto.setChildCount(repository.countByParentCode(unit.getCode()));

        if (unit.getCentroid() != null) {
            dto.setCentroidLat(unit.getCentroid().getY());
            dto.setCentroidLng(unit.getCentroid().getX());
        } else {
            repository.findCentroidByCode(unit.getCode(), unit.getKind())
                    .ifPresent(row -> {
                        @SuppressWarnings("unchecked")
                        Object[] arr = (Object[]) row;
                        if (arr[1] != null) dto.setCentroidLat(((Number) arr[1]).doubleValue());
                        if (arr[0] != null) dto.setCentroidLng(((Number) arr[0]).doubleValue());
                    });
        }

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

    @Override
    @Cacheable(value = "geo", key = "'allProvincesBoundaries'")
    public Object getAllProvincesBoundaries() {
        log.debug("Fetching all province boundaries as FeatureCollection");
        List<AdministrativeUnit> provinces = repository.findByKind(KIND_PROVINCE);
        List<Object> features = new java.util.ArrayList<>();

        for (AdministrativeUnit province : provinces) {
            String geoJson = repository.findBoundaryByCodeAndKind(province.getCode(), KIND_PROVINCE).orElse(null);
            if (geoJson == null || geoJson.isBlank()) continue;

            Map<String, Object> feature = new java.util.LinkedHashMap<>();
            feature.put("type", FEATURE_TYPE);
            feature.put("id", province.getId());
            feature.put("code", province.getCode());
            feature.put("name", province.getName());
            feature.put("kind", province.getKind());

            try {
                JsonNode root = objectMapper.readTree(geoJson);
                Map<String, Object> geometry = new java.util.LinkedHashMap<>();
                geometry.put("type", root.path("type").asText(POLYGON_TYPE));
                geometry.put(COORDINATES_KEY, objectMapper.convertValue(root.path(COORDINATES_KEY), Object.class));
                feature.put("geometry", geometry);
            } catch (Exception e) {
                log.warn("Failed to parse GeoJSON for province {}: {}", province.getCode(), e.getMessage());
                Map<String, Object> geometry = new java.util.LinkedHashMap<>();
                geometry.put("type", POLYGON_TYPE);
                geometry.put(COORDINATES_KEY, java.util.Collections.emptyList());
                feature.put("geometry", geometry);
            }

            features.add(feature);
        }

        Map<String, Object> collection = new java.util.LinkedHashMap<>();
        collection.put("type", "FeatureCollection");
        collection.put("features", features);
        return collection;
    }

    @Override
    public List<GeoJsonFeatureDto> getCommunesBoundariesByProvinceCode(String provinceCode) {
        log.debug("Fetching commune boundaries for province code: {}", provinceCode);

        repository.findByCode(provinceCode)
                .orElseThrow(() -> new ResourceNotFoundException("Province", "code", provinceCode));

        List<Object[]> rows = repository.findCommunesWithBoundariesByProvinceCode(provinceCode);
        return mapRowsToFeatures(rows);
    }

    private List<GeoJsonFeatureDto> mapRowsToFeatures(List<Object[]> rows) {
        List<GeoJsonFeatureDto> features = new java.util.ArrayList<>();
        for (Object[] row : rows) {
            try {
                Long id = ((Number) row[0]).longValue();
                String name = (String) row[1];
                String code = (String) row[2];
                String boundaryJson = (String) row[5];

                GeoJsonFeatureDto feature = GeoJsonFeatureDto.builder()
                        .id(id)
                        .type(FEATURE_TYPE)
                        .code(code)
                        .name(name)
                        .kind(KIND_COMMUNE)
                        .parentCode((String) row[4])
                        .build();

                JsonNode root = objectMapper.readTree(boundaryJson);
                String type = root.path("type").asText(POLYGON_TYPE);
                JsonNode coordsNode = root.path(COORDINATES_KEY);
                feature.setGeometry(GeoJsonFeatureDto.GeometryDto.builder()
                        .type(type)
                        .coordinates(objectMapper.convertValue(coordsNode, Object.class))
                        .build());
                features.add(feature);
            } catch (Exception e) {
                log.warn("Failed to parse commune boundary: {}", e.getMessage());
            }
        }
        return features;
    }

    @Override
    public void evictAllGeoCache() {
        log.info("Evicting all geo cache entries");
        var cache = cacheManager.getCache("geo");
        if (cache != null) {
            cache.clear();
            log.info("Geo cache cleared");
        }
    }

    @Override
    @Cacheable(value = "geo", key = "'committees'")
    public List<CommitteeLocationDto> getAllCommittees() {
        log.debug("Fetching all committees");
        List<CommitteeLocation> committees = committeeRepository.findAll();
        return geoMapper.toCommitteeDtoList(committees);
    }

    @Override
    public List<CommitteeLocationDto> getCommitteesByProvince(String provinceCode) {
        log.debug("Fetching committees for province: {}", provinceCode);
        return geoMapper.toCommitteeDtoList(committeeRepository.findByParentCode(provinceCode));
    }
}
