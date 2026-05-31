package com.vnmap.weather.service;

import com.vnmap.common.exception.ExternalApiException;
import com.vnmap.geo.dto.AdministrativeUnitDto;
import com.vnmap.geo.service.GeoService;
import com.vnmap.weather.cache.WeatherCacheService;
import com.vnmap.weather.client.OpenWeatherMapClient;
import com.vnmap.weather.dto.CurrentWeatherDto;
import com.vnmap.weather.dto.OpenWeatherApiResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.Optional;

@Service
public class WeatherServiceImpl implements WeatherService {

    private static final Logger log = LoggerFactory.getLogger(WeatherServiceImpl.class);

    private final OpenWeatherMapClient weatherClient;
    private final WeatherCacheService cacheService;
    private final GeoService geoService;

    public WeatherServiceImpl(
            OpenWeatherMapClient weatherClient,
            WeatherCacheService cacheService,
            GeoService geoService) {
        this.weatherClient = weatherClient;
        this.cacheService = cacheService;
        this.geoService = geoService;
    }

    @Override
    public CurrentWeatherDto getCurrentWeather(double lat, double lng) {
        String cacheKey = cacheService.buildCacheKey(lat, lng);

        Optional<CurrentWeatherDto> cached = cacheService.get(cacheKey);
        if (cached.isPresent()) {
            log.debug("Returning cached weather for: lat={}, lng={}", lat, lng);
            CurrentWeatherDto dto = cached.get();
            dto.setCached(true);
            return dto;
        }

        log.debug("Fetching fresh weather data for: lat={}, lng={}", lat, lng);

        OpenWeatherApiResponse response = weatherClient.fetchCurrentWeather(lat, lng)
                .block();

        if (response == null) {
            throw new ExternalApiException("OpenWeatherMap", "No response received from weather API");
        }

        CurrentWeatherDto weather = mapToDto(response);
        weather.setCached(false);

        cacheService.put(cacheKey, weather);

        return weather;
    }

    @Override
    public CurrentWeatherDto getWeatherByUnitCode(String unitCode) {
        log.debug("Fetching weather for unit code: {}", unitCode);

        AdministrativeUnitDto unit = geoService.getByCode(unitCode);

        Double lat = unit.getCentroidLat();
        Double lng = unit.getCentroidLng();

        if (lat == null || lng == null) {
            throw new ExternalApiException("Weather",
                    "Centroid data not available for unit '" + unitCode + "'. Please use weather by coordinates instead.");
        }

        return getCurrentWeather(lat, lng);
    }

    @Override
    public Optional<CurrentWeatherDto> getCachedWeather(double lat, double lng) {
        String cacheKey = cacheService.buildCacheKey(lat, lng);
        return cacheService.get(cacheKey);
    }

    private CurrentWeatherDto mapToDto(OpenWeatherApiResponse response) {
        CurrentWeatherDto dto = CurrentWeatherDto.builder()
                .temperature(response.getMain().getTemp())
                .feelsLike(response.getMain().getFeelsLike())
                .humidity(response.getMain().getHumidity())
                .windSpeed(response.getWind().getSpeed())
                .pressure(response.getMain().getPressure())
                .visibility(response.getVisibility())
                .tempMin(response.getMain().getTempMin())
                .tempMax(response.getMain().getTempMax())
                .locationName(response.getName())
                .timestamp(response.getDateTime() != null
                        ? Instant.ofEpochSecond(response.getDateTime())
                        : Instant.now())
                .source("OpenWeatherMap")
                .cached(false)
                .build();

        if (response.getWeather() != null && !response.getWeather().isEmpty()) {
            OpenWeatherApiResponse.Weather weather = response.getWeather().get(0);
            dto.setDescription(weather.getDescription());
            dto.setIconCode(weather.getIcon());
        }

        return dto;
    }
}
