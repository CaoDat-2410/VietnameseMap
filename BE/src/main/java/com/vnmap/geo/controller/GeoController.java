package com.vnmap.geo.controller;

import com.vnmap.common.model.ApiResponse;
import com.vnmap.geo.dto.AdministrativeUnitDto;
import com.vnmap.geo.dto.AdministrativeUnitSummaryDto;
import com.vnmap.geo.dto.GeoJsonFeatureDto;
import com.vnmap.geo.service.GeoService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1/geo")
@Validated
@Tag(name = "Geo", description = "Administrative boundary APIs for Vietnam")
public class GeoController {

    private final GeoService geoService;

    public GeoController(GeoService geoService) {
        this.geoService = geoService;
    }

    @Operation(
            summary = "Get all provinces",
            description = "Retrieves a list of all provinces in Vietnam with basic information"
    )
    @ApiResponses(value = {
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "200",
                    description = "Successfully retrieved provinces",
                    content = @Content(schema = @Schema(implementation = ApiResponse.class))
            )
    })
    @GetMapping("/provinces")
    public ResponseEntity<ApiResponse<List<AdministrativeUnitSummaryDto>>> getProvinces() {
        List<AdministrativeUnitSummaryDto> provinces = geoService.getAllProvinces();
        return ResponseEntity.ok(ApiResponse.success(provinces, "Provinces retrieved successfully"));
    }

    @Operation(
            summary = "Get province boundary",
            description = "Retrieves the simplified GeoJSON boundary for a specific province"
    )
    @ApiResponses(value = {
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Boundary retrieved"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", description = "Province not found")
    })
    @GetMapping("/provinces/{code}/boundary")
    public ResponseEntity<ApiResponse<GeoJsonFeatureDto>> getProvinceBoundary(
            @Parameter(description = "Province code")
            @PathVariable String code) {
        GeoJsonFeatureDto boundary = geoService.getBoundaryByCode(code);
        return ResponseEntity.ok(ApiResponse.success(boundary, "Province boundary retrieved"));
    }

    @Operation(
            summary = "Get districts by province",
            description = "Retrieves all districts belonging to a specific province"
    )
    @ApiResponses(value = {
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Districts retrieved"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", description = "Province not found")
    })
    @GetMapping("/districts")
    public ResponseEntity<ApiResponse<List<AdministrativeUnitSummaryDto>>> getDistricts(
            @Parameter(description = "Province code", required = true)
            @RequestParam @NotBlank
            @Pattern(regexp = "^[A-Za-z0-9._-]+$") String provinceCode) {
        List<AdministrativeUnitSummaryDto> districts = geoService.getDistrictsByProvince(provinceCode);
        return ResponseEntity.ok(ApiResponse.success(districts, "Districts retrieved successfully"));
    }

    @Operation(
            summary = "Get wards by district",
            description = "Retrieves all wards belonging to a specific district"
    )
    @ApiResponses(value = {
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Wards retrieved"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", description = "District not found")
    })
    @GetMapping("/wards")
    public ResponseEntity<ApiResponse<List<AdministrativeUnitSummaryDto>>> getWards(
            @Parameter(description = "District code", required = true)
            @RequestParam @NotBlank
            @Pattern(regexp = "^[A-Za-z0-9._-]+$") String districtCode) {
        List<AdministrativeUnitSummaryDto> wards = geoService.getWardsByDistrict(districtCode);
        return ResponseEntity.ok(ApiResponse.success(wards, "Wards retrieved successfully"));
    }

    @Operation(
            summary = "Get administrative unit by code",
            description = "Retrieves detailed information for a specific administrative unit"
    )
    @ApiResponses(value = {
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Unit retrieved"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", description = "Unit not found")
    })
    @GetMapping("/units/{code}")
    public ResponseEntity<ApiResponse<AdministrativeUnitDto>> getUnitByCode(
            @Parameter(description = "Administrative unit code")
            @PathVariable String code) {
        AdministrativeUnitDto unit = geoService.getByCode(code);
        return ResponseEntity.ok(ApiResponse.success(unit, "Unit retrieved successfully"));
    }

    @Operation(
            summary = "Get boundary by code",
            description = "Retrieves the simplified GeoJSON boundary for any administrative unit"
    )
    @ApiResponses(value = {
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Boundary retrieved"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", description = "Unit not found")
    })
    @GetMapping("/units/{code}/boundary")
    public ResponseEntity<ApiResponse<GeoJsonFeatureDto>> getUnitBoundary(
            @Parameter(description = "Administrative unit code")
            @PathVariable String code) {
        GeoJsonFeatureDto boundary = geoService.getBoundaryByCode(code);
        return ResponseEntity.ok(ApiResponse.success(boundary, "Boundary retrieved successfully"));
    }

    @Operation(
            summary = "Reverse geocode coordinates",
            description = "Finds the administrative unit containing the given GPS coordinates"
    )
    @ApiResponses(value = {
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Unit found"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", description = "No unit found at coordinates")
    })
    @GetMapping("/reverse")
    public ResponseEntity<ApiResponse<AdministrativeUnitDto>> reverseGeocode(
            @Parameter(description = "Latitude (-90 to 90)")
            @RequestParam @DecimalMin("-90.0") @DecimalMax("90.0") double lat,
            @Parameter(description = "Longitude (-180 to 180)")
            @RequestParam @DecimalMin("-180.0") @DecimalMax("180.0") double lng) {
        AdministrativeUnitDto unit = geoService.findUnitByCoordinate(lat, lng);
        return ResponseEntity.ok(ApiResponse.success(unit, "Reverse geocoding successful"));
    }

    @Operation(
            summary = "Calculate centroids for all units",
            description = "Calculates and stores centroid coordinates from boundary geometries (admin)"
    )
    @ApiResponses(value = {
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Centroids calculated")
    })
    @PostMapping("/admin/calculate-centroids")
    public ResponseEntity<ApiResponse<Integer>> calculateCentroids() {
        int count = geoService.calculateCentroids();
        return ResponseEntity.ok(ApiResponse.success(count, "Calculated " + count + " centroids"));
    }
}
