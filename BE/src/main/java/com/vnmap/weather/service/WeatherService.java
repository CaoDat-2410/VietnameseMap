package com.vnmap.weather.service;

import com.vnmap.weather.dto.CurrentWeatherDto;

import java.util.Optional;

public interface WeatherService {

    CurrentWeatherDto getCurrentWeather(double lat, double lng);

    CurrentWeatherDto getWeatherByUnitCode(String unitCode);

    Optional<CurrentWeatherDto> getCachedWeather(double lat, double lng);
}
