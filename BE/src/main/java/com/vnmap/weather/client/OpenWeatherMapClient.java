package com.vnmap.weather.client;

import com.vnmap.common.exception.ExternalApiException;
import com.vnmap.weather.dto.OpenWeatherApiResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatusCode;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.reactive.function.client.WebClientResponseException;
import reactor.core.publisher.Mono;

import java.time.Duration;

@Component
public class OpenWeatherMapClient {

    private static final Logger log = LoggerFactory.getLogger(OpenWeatherMapClient.class);

    private final WebClient webClient;
    private final String apiKey;

    public OpenWeatherMapClient(
            WebClient.Builder builder,
            @Value("${weather.openweathermap.base-url}") String baseUrl,
            @Value("${weather.openweathermap.api-key}") String apiKey,
            @Value("${weather.openweathermap.timeout:5000}") int timeout) {
        this.apiKey = apiKey;
        this.webClient = builder
                .baseUrl(baseUrl)
                .build();
    }

    public Mono<OpenWeatherApiResponse> fetchCurrentWeather(double lat, double lng) {
        log.debug("Fetching weather for coordinates: lat={}, lng={}", lat, lng);

        return webClient.get()
                .uri(uriBuilder -> uriBuilder
                        .path("/data/2.5/weather")
                        .queryParam("lat", lat)
                        .queryParam("lon", lng)
                        .queryParam("appid", apiKey)
                        .queryParam("units", "metric")
                        .queryParam("lang", "vi")
                        .build())
                .retrieve()
                .onStatus(HttpStatusCode::is4xxClientError, response ->
                        Mono.error(new ExternalApiException(
                                "OpenWeatherMap",
                                response.statusCode().value(),
                                "Client error: " + response.statusCode())))
                .onStatus(HttpStatusCode::is5xxServerError, response ->
                        Mono.error(new ExternalApiException(
                                "OpenWeatherMap",
                                response.statusCode().value(),
                                "Server error from weather API")))
                .bodyToMono(OpenWeatherApiResponse.class)
                .timeout(Duration.ofSeconds(5))
                .doOnError(WebClientResponseException.class, e ->
                        log.error("Weather API HTTP error: status={}, body={}",
                                e.getStatusCode(), e.getResponseBodyAsString()))
                .doOnError(e -> !(e instanceof WebClientResponseException),
                        e -> log.error("Weather API error for lat={} lng={}: {}",
                                lat, lng, e.getMessage()));
    }
}
