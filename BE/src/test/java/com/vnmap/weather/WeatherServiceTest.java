package com.vnmap.weather;

import com.vnmap.common.exception.ExternalApiException;
import com.vnmap.geo.dto.AdministrativeUnitDto;
import com.vnmap.geo.enums.UnitLevel;
import com.vnmap.geo.service.GeoService;
import com.vnmap.weather.cache.WeatherCacheService;
import com.vnmap.weather.client.OpenWeatherMapClient;
import com.vnmap.weather.dto.CurrentWeatherDto;
import com.vnmap.weather.dto.OpenWeatherApiResponse;
import com.vnmap.weather.service.WeatherService;
import com.vnmap.weather.service.WeatherServiceImpl;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import reactor.core.publisher.Mono;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyDouble;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
@DisplayName("WeatherService Tests")
class WeatherServiceTest {

    @Mock
    private OpenWeatherMapClient weatherClient;

    @Mock
    private WeatherCacheService cacheService;

    @Mock
    private GeoService geoService;

    private WeatherService weatherService;

    @BeforeEach
    void setUp() {
        weatherService = new WeatherServiceImpl(weatherClient, cacheService, geoService);
    }

    @Nested
    @DisplayName("getCurrentWeather")
    class GetCurrentWeather {

        @Test
        @DisplayName("should return cached weather when available")
        void shouldReturnCachedWeather() {
            CurrentWeatherDto cachedWeather = createWeatherDto(25.0, 27.0, "Clear");
            when(cacheService.buildCacheKey(anyDouble(), anyDouble())).thenReturn("weather:21.03:105.85");
            when(cacheService.get(anyString())).thenReturn(Optional.of(cachedWeather));

            CurrentWeatherDto result = weatherService.getCurrentWeather(21.03, 105.85);

            assertThat(result.getTemperature()).isEqualTo(25.0);
            assertThat(result.isCached()).isTrue();
            verify(weatherClient).fetchCurrentWeather(anyDouble(), anyDouble());
        }

        @Test
        @DisplayName("should fetch fresh data when cache miss")
        void shouldFetchFreshDataOnCacheMiss() {
            OpenWeatherApiResponse response = createApiResponse(25.0, 27.0, 70, 5.0, "Clear sky", "01d");
            when(cacheService.buildCacheKey(anyDouble(), anyDouble())).thenReturn("weather:21.03:105.85");
            when(cacheService.get(anyString())).thenReturn(Optional.empty());
            when(weatherClient.fetchCurrentWeather(anyDouble(), anyDouble()))
                    .thenReturn(Mono.just(response));

            CurrentWeatherDto result = weatherService.getCurrentWeather(21.03, 105.85);

            assertThat(result.getTemperature()).isEqualTo(25.0);
            assertThat(result.isCached()).isFalse();
            verify(cacheService).put(anyString(), any(CurrentWeatherDto.class));
        }

        @Test
        @DisplayName("should throw exception when API fails")
        void shouldThrowExceptionWhenApiFails() {
            when(cacheService.buildCacheKey(anyDouble(), anyDouble())).thenReturn("weather:21.03:105.85");
            when(cacheService.get(anyString())).thenReturn(Optional.empty());
            when(weatherClient.fetchCurrentWeather(anyDouble(), anyDouble()))
                    .thenReturn(Mono.error(new ExternalApiException("Weather API error")));

            assertThatThrownBy(() -> weatherService.getCurrentWeather(21.03, 105.85))
                    .isInstanceOf(ExternalApiException.class);
        }
    }

    @Nested
    @DisplayName("getWeatherByUnitCode")
    class GetWeatherByUnitCode {

        @Test
        @DisplayName("should throw exception when coordinates not available")
        void shouldThrowWhenCoordinatesNotAvailable() {
            when(geoService.getByCode("01"))
                    .thenThrow(new ExternalApiException("Weather", "Coordinates not available"));

            assertThatThrownBy(() -> weatherService.getWeatherByUnitCode("01"))
                    .isInstanceOf(ExternalApiException.class);
        }
    }

    private CurrentWeatherDto createWeatherDto(double temp, double feelsLike, String description) {
        return CurrentWeatherDto.builder()
                .temperature(temp)
                .feelsLike(feelsLike)
                .humidity(70)
                .windSpeed(5.0)
                .description(description)
                .iconCode("01d")
                .locationName("Hà Nội")
                .cached(false)
                .build();
    }

    private OpenWeatherApiResponse createApiResponse(double temp, double feelsLike, int humidity,
                                                    double windSpeed, String description, String icon) {
        OpenWeatherApiResponse response = new OpenWeatherApiResponse();
        response.setName("Hà Nội");

        OpenWeatherApiResponse.Main main = new OpenWeatherApiResponse.Main();
        main.setTemp(temp);
        main.setFeelsLike(feelsLike);
        main.setHumidity(humidity);
        main.setPressure(1013);
        response.setMain(main);

        OpenWeatherApiResponse.Wind wind = new OpenWeatherApiResponse.Wind();
        wind.setSpeed(windSpeed);
        response.setWind(wind);

        OpenWeatherApiResponse.Weather weather = new OpenWeatherApiResponse.Weather();
        weather.setDescription(description);
        weather.setIcon(icon);
        response.setWeather(java.util.List.of(weather));

        return response;
    }
}
