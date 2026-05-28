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

    AdministrativeUnitDto findUnitByCoordinate(double lat, double lng);
}
