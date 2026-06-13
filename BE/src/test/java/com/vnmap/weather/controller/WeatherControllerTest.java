package com.vnmap.weather.controller;

import com.vnmap.common.exception.ExternalApiException;
import com.vnmap.weather.dto.CurrentWeatherDto;
import com.vnmap.weather.service.WeatherService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Optional;

import static org.hamcrest.Matchers.is;
import static org.mockito.ArgumentMatchers.anyDouble;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(WeatherController.class)
@DisplayName("WeatherController Tests")
class WeatherControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private WeatherService weatherService;

    @Nested
    @DisplayName("GET /api/v1/weather")
    class GetWeatherByCoordinates {

        @Test
        @DisplayName("should return fresh weather data")
        void shouldReturnFreshWeather() throws Exception {
            CurrentWeatherDto weather = createWeather(25.0, false);
            when(weatherService.getCurrentWeather(anyDouble(), anyDouble())).thenReturn(weather);

            mockMvc.perform(get("/api/v1/weather")
                            .param("lat", "21.03")
                            .param("lng", "105.85")
                            .contentType(MediaType.APPLICATION_JSON))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.success", is(true)))
                    .andExpect(jsonPath("$.message", is("Weather data (fresh)")))
                    .andExpect(jsonPath("$.data.temperature", is(25.0)));
        }

        @Test
        @DisplayName("should return cached weather data")
        void shouldReturnCachedWeather() throws Exception {
            CurrentWeatherDto weather = createWeather(25.0, true);
            when(weatherService.getCurrentWeather(anyDouble(), anyDouble())).thenReturn(weather);

            mockMvc.perform(get("/api/v1/weather")
                            .param("lat", "21.03")
                            .param("lng", "105.85")
                            .contentType(MediaType.APPLICATION_JSON))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.message", is("Weather data (cached)")));
        }

        @Test
        @DisplayName("should return 502 when external API fails")
        void shouldReturn502OnApiError() throws Exception {
            when(weatherService.getCurrentWeather(anyDouble(), anyDouble()))
                    .thenThrow(new ExternalApiException("Weather", "API timeout"));

            mockMvc.perform(get("/api/v1/weather")
                            .param("lat", "21.03")
                            .param("lng", "105.85")
                            .contentType(MediaType.APPLICATION_JSON))
                    .andExpect(status().isBadGateway());
        }

        @Test
        @DisplayName("should return 400 for invalid latitude")
        void shouldReturn400ForInvalidLatitude() throws Exception {
            mockMvc.perform(get("/api/v1/weather")
                            .param("lat", "100.0")
                            .param("lng", "105.85")
                            .contentType(MediaType.APPLICATION_JSON))
                    .andExpect(status().isBadRequest());
        }
    }

    @Nested
    @DisplayName("GET /api/v1/weather/unit/{unitCode}")
    class GetWeatherByUnit {

        @Test
        @DisplayName("should return weather for unit code")
        void shouldReturnWeatherForUnit() throws Exception {
            CurrentWeatherDto weather = createWeather(30.0, false);
            when(weatherService.getWeatherByUnitCode("01")).thenReturn(weather);

            mockMvc.perform(get("/api/v1/weather/unit/01")
                            .contentType(MediaType.APPLICATION_JSON))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.success", is(true)))
                    .andExpect(jsonPath("$.data.temperature", is(30.0)));
        }

        @Test
        @DisplayName("should return 502 when centroid not available")
        void shouldReturn502WhenCentroidNotAvailable() throws Exception {
            when(weatherService.getWeatherByUnitCode("invalid"))
                    .thenThrow(new ExternalApiException("Weather", "Centroid not available"));

            mockMvc.perform(get("/api/v1/weather/unit/invalid")
                            .contentType(MediaType.APPLICATION_JSON))
                    .andExpect(status().isBadGateway());
        }
    }

    @Nested
    @DisplayName("GET /api/v1/weather/cache")
    class CheckCache {

        @Test
        @DisplayName("should return cached weather")
        void shouldReturnCachedWeather() throws Exception {
            CurrentWeatherDto weather = createWeather(25.0, true);
            when(weatherService.getCachedWeather(anyDouble(), anyDouble()))
                    .thenReturn(Optional.of(weather));

            mockMvc.perform(get("/api/v1/weather/cache")
                            .param("lat", "21.03")
                            .param("lng", "105.85")
                            .contentType(MediaType.APPLICATION_JSON))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.success", is(true)))
                    .andExpect(jsonPath("$.message", is("Weather data found in cache")));
        }

        @Test
        @DisplayName("should return null when no cache")
        void shouldReturnNullWhenNoCache() throws Exception {
            when(weatherService.getCachedWeather(anyDouble(), anyDouble()))
                    .thenReturn(Optional.empty());

            mockMvc.perform(get("/api/v1/weather/cache")
                            .param("lat", "21.03")
                            .param("lng", "105.85")
                            .contentType(MediaType.APPLICATION_JSON))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.success", is(true)))
                    .andExpect(jsonPath("$.message", is("No cached data available")));
        }
    }

    private CurrentWeatherDto createWeather(double temp, boolean cached) {
        return CurrentWeatherDto.builder()
                .temperature(temp)
                .humidity(70)
                .windSpeed(5.0)
                .description("Clear sky")
                .cached(cached)
                .build();
    }
}
