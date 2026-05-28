package com.vnmap.weather.controller;

import com.vnmap.common.model.ApiResponse;
import com.vnmap.weather.dto.CurrentWeatherDto;
import com.vnmap.weather.service.WeatherService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/weather")
@Validated
@Tag(name = "Weather", description = "Weather data APIs from OpenWeatherMap")
public class WeatherController {

    private static final Logger log = LoggerFactory.getLogger(WeatherController.class);

    private final WeatherService weatherService;

    public WeatherController(WeatherService weatherService) {
        this.weatherService = weatherService;
    }

    @Operation(
            summary = "Get weather by coordinates",
            description = "Retrieves current weather data for the specified GPS coordinates"
    )
    @ApiResponses(value = {
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "200",
                    description = "Weather data retrieved successfully",
                    content = @Content(schema = @Schema(implementation = ApiResponse.class))
            ),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "400",
                    description = "Invalid coordinates"
            ),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "502",
                    description = "Weather service unavailable"
            )
    })
    @GetMapping
    public ResponseEntity<ApiResponse<CurrentWeatherDto>> getWeatherByCoordinates(
            @Parameter(description = "Latitude (-90 to 90)")
            @RequestParam @DecimalMin("-90.0") @DecimalMax("90.0") double lat,
            @Parameter(description = "Longitude (-180 to 180)")
            @RequestParam @DecimalMin("-180.0") @DecimalMax("180.0") double lng) {
        log.debug("Weather request for coordinates: lat={}, lng={}", lat, lng);

        CurrentWeatherDto weather = weatherService.getCurrentWeather(lat, lng);
        String message = weather.isCached() ? "Weather data (cached)" : "Weather data (fresh)";
        return ResponseEntity.ok(ApiResponse.success(weather, message));
    }

    @Operation(
            summary = "Get weather by administrative unit",
            description = "Retrieves weather data for the centroid of a specific administrative unit"
    )
    @ApiResponses(value = {
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "200",
                    description = "Weather data retrieved successfully"
            ),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "404",
                    description = "Administrative unit not found"
            ),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "502",
                    description = "Weather service unavailable"
            )
    })
    @GetMapping("/unit/{unitCode}")
    public ResponseEntity<ApiResponse<CurrentWeatherDto>> getWeatherByUnit(
            @Parameter(description = "Administrative unit code (province, district, or ward)")
            @PathVariable String unitCode) {
        log.debug("Weather request for unit code: {}", unitCode);

        CurrentWeatherDto weather = weatherService.getWeatherByUnitCode(unitCode);
        String message = weather.isCached() ? "Weather data (cached)" : "Weather data (fresh)";
        return ResponseEntity.ok(ApiResponse.success(weather, message));
    }

    @Operation(
            summary = "Check cache status",
            description = "Checks if weather data is available in cache for the given coordinates"
    )
    @GetMapping("/cache")
    public ResponseEntity<ApiResponse<CurrentWeatherDto>> checkCache(
            @Parameter(description = "Latitude")
            @RequestParam @DecimalMin("-90.0") @DecimalMax("90.0") double lat,
            @Parameter(description = "Longitude")
            @RequestParam @DecimalMin("-180.0") @DecimalMax("180.0") double lng) {
        log.debug("Cache check for coordinates: lat={}, lng={}", lat, lng);

        return weatherService.getCachedWeather(lat, lng)
                .map(weather -> ResponseEntity.ok(
                        ApiResponse.success(weather, "Weather data found in cache")))
                .orElse(ResponseEntity.ok(
                        ApiResponse.success(null, "No cached data available")));
    }
}
