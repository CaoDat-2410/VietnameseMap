package com.vnmap.weather.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
public class WeatherResponseDto {

    private boolean success;
    private CurrentWeatherDto data;
    private String message;
    private Instant timestamp;
    private boolean cached;
    private String unitCode;

    public static WeatherResponseDto fromWeather(CurrentWeatherDto weather, String unitCode, boolean cached) {
        return WeatherResponseDto.builder()
                .success(true)
                .data(weather)
                .message("Weather data retrieved successfully")
                .timestamp(Instant.now())
                .cached(cached)
                .unitCode(unitCode)
                .build();
    }

    public static WeatherResponseDto error(String message) {
        return WeatherResponseDto.builder()
                .success(false)
                .message(message)
                .timestamp(Instant.now())
                .build();
    }
}
