package com.vnmap.weather;

import com.vnmap.common.exception.ExternalApiException;
import com.vnmap.weather.client.OpenWeatherMapClient;
import com.vnmap.weather.dto.OpenWeatherApiResponse;
import okhttp3.mockwebserver.MockResponse;
import okhttp3.mockwebserver.MockWebServer;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.web.reactive.function.client.WebClient;

import java.io.IOException;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

@DisplayName("OpenWeatherMapClient Tests")
class WeatherClientTest {

    private MockWebServer mockWebServer;
    private OpenWeatherMapClient client;

    @BeforeEach
    void setUp() throws IOException {
        mockWebServer = new MockWebServer();
        mockWebServer.start();

        String baseUrl = mockWebServer.url("/").toString();
        WebClient.Builder builder = WebClient.builder();

        client = new OpenWeatherMapClient(builder, baseUrl, "test-api-key", 5000);
    }

    @AfterEach
    void tearDown() throws IOException {
        if (mockWebServer != null) {
            mockWebServer.shutdown();
        }
    }

    @Test
    @DisplayName("should return weather response on success")
    void shouldReturnWeatherOnSuccess() {
        String responseBody = """
            {
                "coord": {"lon": 105.85, "lat": 21.03},
                "weather": [{"id": 800, "main": "Clear", "description": "clear sky", "icon": "01d"}],
                "main": {"temp": 25.0, "feels_like": 27.0, "humidity": 70, "pressure": 1013},
                "wind": {"speed": 5.0, "deg": 180},
                "name": "Hanoi",
                "cod": 200
            }
            """;

        mockWebServer.enqueue(new MockResponse()
                .setBody(responseBody)
                .addHeader("Content-Type", "application/json"));

        OpenWeatherApiResponse response = client.fetchCurrentWeather(21.03, 105.85)
                .block();

        assertThat(response).isNotNull();
        assertThat(response.getName()).isEqualTo("Hanoi");
        assertThat(response.getMain().getTemp()).isEqualTo(25.0);
        assertThat(response.getWeather()).hasSize(1);
    }

    @Test
    @DisplayName("should throw exception on 401 unauthorized")
    void shouldThrowOnUnauthorized() {
        mockWebServer.enqueue(new MockResponse()
                .setResponseCode(401)
                .setBody("{\"message\": \"Invalid API key\"}"));

        assertThatThrownBy(() -> client.fetchCurrentWeather(21.03, 105.85).block())
                .isInstanceOf(ExternalApiException.class);
    }

    @Test
    @DisplayName("should throw exception on 404 not found")
    void shouldThrowOnNotFound() {
        mockWebServer.enqueue(new MockResponse()
                .setResponseCode(404)
                .setBody("{\"message\": \"Not found\"}"));

        assertThatThrownBy(() -> client.fetchCurrentWeather(91.0, 200.0).block())
                .isInstanceOf(ExternalApiException.class);
    }

    @Test
    @DisplayName("should throw exception on 500 server error")
    void shouldThrowOnServerError() {
        mockWebServer.enqueue(new MockResponse()
                .setResponseCode(500)
                .setBody("{\"message\": \"Internal server error\"}"));

        assertThatThrownBy(() -> client.fetchCurrentWeather(21.03, 105.85).block())
                .isInstanceOf(ExternalApiException.class);
    }
}
