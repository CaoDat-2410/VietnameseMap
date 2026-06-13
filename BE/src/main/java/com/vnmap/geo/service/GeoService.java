package com.vnmap.geo.service;

import com.vnmap.geo.dto.AdministrativeUnitDto;
import com.vnmap.geo.dto.AdministrativeUnitSummaryDto;
import com.vnmap.geo.dto.CommitteeLocationDto;
import com.vnmap.geo.dto.GeoJsonFeatureDto;

import java.util.List;

public interface GeoService {

    List<AdministrativeUnitSummaryDto> getAllProvinces();

    List<AdministrativeUnitSummaryDto> getCommunesByProvince(String provinceCode);

    List<AdministrativeUnitSummaryDto> getCommunesByMacroRegion(String macroRegion);

    AdministrativeUnitDto getByCode(String code);

    GeoJsonFeatureDto getBoundaryByCode(String code);

    Object getAllProvincesBoundaries();

    List<GeoJsonFeatureDto> getCommunesBoundariesByProvinceCode(String provinceCode);

    AdministrativeUnitDto findUnitByCoordinate(double lat, double lng);

    int calculateCentroids();

    void evictAllGeoCache();

    // Committee endpoints
    List<CommitteeLocationDto> getAllCommittees();

    List<CommitteeLocationDto> getCommitteesByProvince(String provinceCode);
}
