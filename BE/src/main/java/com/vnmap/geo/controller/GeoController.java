package com.vnmap.geo.controller;

import com.vnmap.common.model.ApiResponse;
import com.vnmap.geo.dto.AdministrativeUnitDto;
import com.vnmap.geo.dto.AdministrativeUnitSummaryDto;
import com.vnmap.geo.dto.CommitteeLocationDto;
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
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
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
@Tag(name = "Geo", description = "Administrative boundary APIs for Vietnam (2025 Reform)")
public class GeoController {

    private final GeoService geoService;

    public GeoController(GeoService geoService) {
        this.geoService = geoService;
    }

    @Operation(
            summary = "Get all provinces",
            description = "Retrieves a list of all 34 provinces in Vietnam with basic information"
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
            description = "Retrieves the GeoJSON boundary for a specific province"
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
            summary = "Get all provinces boundaries",
            description = "Retrieves GeoJSON FeatureCollection with boundaries for all provinces"
    )
    @ApiResponses(value = {
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Boundaries retrieved")
    })
    @GetMapping("/provinces-boundaries")
    public ResponseEntity<ApiResponse<Object>> getAllProvincesBoundaries() {
        Object boundaries = geoService.getAllProvincesBoundaries();
        return ResponseEntity.ok(ApiResponse.success(boundaries, "All province boundaries retrieved"));
    }

    @Operation(
            summary = "Get communes by province",
            description = "Retrieves all communes belonging to a specific province"
    )
    @ApiResponses(value = {
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Communes retrieved"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", description = "Province not found")
    })
    @GetMapping("/provinces/{code}/communes")
    public ResponseEntity<ApiResponse<List<AdministrativeUnitSummaryDto>>> getCommunes(
            @Parameter(description = "Province code", required = true)
            @PathVariable String code) {
        List<AdministrativeUnitSummaryDto> communes = geoService.getCommunesByProvince(code);
        return ResponseEntity.ok(ApiResponse.success(communes, "Communes retrieved successfully"));
    }

    @Operation(
            summary = "Get commune boundaries for a province",
            description = "Retrieves GeoJSON boundaries for all communes in a province (for map display)"
    )
    @ApiResponses(value = {
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Commune boundaries retrieved"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", description = "Province not found")
    })
    @GetMapping("/provinces/{code}/communes-boundaries")
    public ResponseEntity<ApiResponse<List<GeoJsonFeatureDto>>> getCommunesBoundaries(
            @Parameter(description = "Province code", required = true)
            @PathVariable String code) {
        List<GeoJsonFeatureDto> boundaries = geoService.getCommunesBoundariesByProvinceCode(code);
        return ResponseEntity.ok(ApiResponse.success(boundaries, "Commune boundaries retrieved"));
    }

    @Operation(
            summary = "Get paginated communes for a province",
            description = "Retrieves a paginated list of communes in a province"
    )
    @ApiResponses(value = {
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Communes retrieved"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", description = "Province not found")
    })
    @GetMapping("/provinces/{code}/communes-paginated")
    public ResponseEntity<ApiResponse<List<AdministrativeUnitSummaryDto>>> getCommunesPaginated(
            @Parameter(description = "Province code", required = true)
            @PathVariable String code,
            @Parameter(description = "Page number (0-based)", required = true)
            @RequestParam @Min(0) int page,
            @Parameter(description = "Page size", required = true)
            @RequestParam @Min(1) @Max(100) int size) {
        List<AdministrativeUnitSummaryDto> allCommunes = geoService.getCommunesByProvince(code);
        int start = page * size;
        int end = Math.min(start + size, allCommunes.size());
        List<AdministrativeUnitSummaryDto> paged = start < allCommunes.size()
                ? allCommunes.subList(start, end)
                : List.of();
        return ResponseEntity.ok(ApiResponse.success(paged, "Communes retrieved (page " + page + ")"));
    }

    @Operation(
            summary = "Get communes by macro-region",
            description = "Retrieves all communes in a specific macro-region (e.g., 'North Delta', 'Mekong Delta')"
    )
    @ApiResponses(value = {
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Communes retrieved"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", description = "Macro-region not found")
    })
    @GetMapping("/macro-regions/{name}/communes")
    public ResponseEntity<ApiResponse<List<AdministrativeUnitSummaryDto>>> getCommunesByMacroRegion(
            @Parameter(description = "Macro-region name", required = true)
            @PathVariable String name) {
        List<AdministrativeUnitSummaryDto> communes = geoService.getCommunesByMacroRegion(name);
        return ResponseEntity.ok(ApiResponse.success(communes, "Communes in " + name + " retrieved"));
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
            description = "Retrieves the GeoJSON boundary for any administrative unit"
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
            description = "Finds the administrative unit (commune or province) containing the given GPS coordinates"
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

    @Operation(
            summary = "Get all committees",
            description = "Retrieves all People's Committee HQ (trụ sở UBND) locations"
    )
    @ApiResponses(value = {
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Committees retrieved")
    })
    @GetMapping("/committees")
    public ResponseEntity<ApiResponse<List<CommitteeLocationDto>>> getAllCommittees() {
        List<CommitteeLocationDto> committees = geoService.getAllCommittees();
        return ResponseEntity.ok(ApiResponse.success(committees, "All committees retrieved"));
    }

    @Operation(
            summary = "Get committees by province",
            description = "Retrieves all People's Committee HQ locations for a specific province"
    )
    @ApiResponses(value = {
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Committees retrieved"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", description = "Province not found")
    })
    @GetMapping("/committees/{provinceCode}")
    public ResponseEntity<ApiResponse<List<CommitteeLocationDto>>> getCommitteesByProvince(
            @Parameter(description = "Province code", required = true)
            @PathVariable String provinceCode) {
        List<CommitteeLocationDto> committees = geoService.getCommitteesByProvince(provinceCode);
        return ResponseEntity.ok(ApiResponse.success(committees, "Committees for province " + provinceCode + " retrieved"));
    }
}
