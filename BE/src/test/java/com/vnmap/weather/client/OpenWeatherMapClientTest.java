package com.vnmap.weather.client;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.web.reactive.function.client.WebClient;

import static org.assertj.core.api.Assertions.assertThat;

@DisplayName("OpenWeatherMapClient Tests")
class OpenWeatherMapClientTest {

    private OpenWeatherMapClient client;

    @BeforeEach
    void setUp() {
        WebClient.Builder builder = WebClient.builder();
        client = new OpenWeatherMapClient(
                builder,
                "https://api.openweathermap.org",
                "test-api-key",
                5
        );
    }

    @Nested
    @DisplayName("fetchCurrentWeather")
    class FetchCurrentWeather {

        @Test
        @DisplayName("should return a Mono")
        void shouldReturnMono() {
            var mono = client.fetchCurrentWeather(21.03, 105.85);
            assertThat(mono).isNotNull();
        }
    }
}
