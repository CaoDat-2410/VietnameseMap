package com.vnmap.weather.service;

import com.vnmap.common.exception.ExternalApiException;
import com.vnmap.geo.dto.AdministrativeUnitDto;
import com.vnmap.geo.service.GeoService;
import com.vnmap.weather.cache.WeatherCacheService;
import com.vnmap.weather.client.OpenWeatherMapClient;
import com.vnmap.weather.dto.CurrentWeatherDto;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.anyDouble;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("WeatherServiceImpl Tests")
class WeatherServiceImplTest {

    @Mock
    private OpenWeatherMapClient weatherClient;

    @Mock
    private WeatherCacheService cacheService;

    @Mock
    private GeoService geoService;

    private WeatherServiceImpl weatherService;

    @BeforeEach
    void setUp() {
        weatherService = new WeatherServiceImpl(weatherClient, cacheService, geoService);
    }

    @Nested
    @DisplayName("getCurrentWeather")
    class GetCurrentWeather {

        @Test
        @DisplayName("should map weather description when available")
        void shouldMapWeatherDescription() {
            CurrentWeatherDto cached = createCachedWeather(25.0);
            when(cacheService.buildCacheKey(anyDouble(), anyDouble())).thenReturn("weather:21.03:105.85");
            when(cacheService.get(anyString())).thenReturn(Optional.of(cached));

            CurrentWeatherDto result = weatherService.getCurrentWeather(21.03, 105.85);

            assertThat(result.isCached()).isTrue();
            verify(weatherClient, never()).fetchCurrentWeather(anyDouble(), anyDouble());
        }
    }

    @Nested
    @DisplayName("getWeatherByUnitCode")
    class GetWeatherByUnitCode {

        @Test
        @DisplayName("should throw when centroid is null")
        void shouldThrowWhenCentroidNull() {
            AdministrativeUnitDto unit = createUnitDto("01", null, null);
            when(geoService.getByCode("01")).thenReturn(unit);

            assertThatThrownBy(() -> weatherService.getWeatherByUnitCode("01"))
                    .isInstanceOf(ExternalApiException.class)
                    .hasMessageContaining("Centroid data not available");
        }

        @Test
        @DisplayName("should delegate to getCurrentWeather with centroid")
        void shouldDelegateWithCentroid() {
            AdministrativeUnitDto unit = createUnitDto("01", 21.03, 105.85);
            CurrentWeatherDto cached = createCachedWeather(25.0);

            when(geoService.getByCode("01")).thenReturn(unit);
            when(cacheService.buildCacheKey(anyDouble(), anyDouble())).thenReturn("weather:21.03:105.85");
            when(cacheService.get(anyString())).thenReturn(Optional.of(cached));

            CurrentWeatherDto result = weatherService.getWeatherByUnitCode("01");

            assertThat(result).isNotNull();
            verify(geoService).getByCode("01");
        }
    }

    @Nested
    @DisplayName("getCachedWeather")
    class GetCachedWeather {

        @Test
        @DisplayName("should return cached weather")
        void shouldReturnCached() {
            CurrentWeatherDto cached = createCachedWeather(25.0);
            when(cacheService.buildCacheKey(anyDouble(), anyDouble())).thenReturn("weather:21.03:105.85");
            when(cacheService.get(anyString())).thenReturn(Optional.of(cached));

            Optional<CurrentWeatherDto> result = weatherService.getCachedWeather(21.03, 105.85);

            assertThat(result).isPresent();
            assertThat(result.get().getTemperature()).isEqualTo(25.0);
        }

        @Test
        @DisplayName("should return empty when not cached")
        void shouldReturnEmptyWhenNotCached() {
            when(cacheService.buildCacheKey(anyDouble(), anyDouble())).thenReturn("weather:21.03:105.85");
            when(cacheService.get(anyString())).thenReturn(Optional.empty());

            Optional<CurrentWeatherDto> result = weatherService.getCachedWeather(21.03, 105.85);

            assertThat(result).isEmpty();
        }
    }

    private CurrentWeatherDto createCachedWeather(double temp) {
        return CurrentWeatherDto.builder()
                .temperature(temp)
                .humidity(70)
                .windSpeed(5.0)
                .cached(true)
                .build();
    }

    private AdministrativeUnitDto createUnitDto(String code, Double lat, Double lng) {
        return AdministrativeUnitDto.builder()
                .code(code)
                .name("Test")
                .kind("province")
                .centroidLat(lat)
                .centroidLng(lng)
                .build();
    }

}
