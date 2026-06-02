package com.vnmap.geo.service;

import com.vnmap.geo.dto.AdministrativeUnitDto;
import com.vnmap.geo.dto.AdministrativeUnitSummaryDto;
import com.vnmap.geo.dto.GeoJsonFeatureDto;

import java.util.List;

public interface GeoService {

    List<AdministrativeUnitSummaryDto> getAllProvinces();

    List<AdministrativeUnitSummaryDto> getDistrictsByProvince(String provinceCode);

    List<AdministrativeUnitSummaryDto> getWardsByDistrict(String districtCode);

    AdministrativeUnitDto getByCode(String code);

    GeoJsonFeatureDto getBoundaryByCode(String code);

    /// Returns a GeoJSON FeatureCollection containing boundaries for all provinces.
    /// This is much more efficient than fetching each province boundary individually.
    Object getAllProvincesBoundaries();

    AdministrativeUnitDto findUnitByCoordinate(double lat, double lng);

    int calculateCentroids();
}
