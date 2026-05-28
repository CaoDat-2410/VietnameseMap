package com.vnmap.common.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.info.License;
import io.swagger.v3.oas.models.servers.Server;
import io.swagger.v3.oas.models.tags.Tag;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.Arrays;
import java.util.List;

@Configuration
public class OpenApiConfig {

    @Value("${server.port:8080}")
    private int serverPort;

    @Bean
    public OpenAPI customOpenAPI() {
        return new OpenAPI()
                .info(new Info()
                        .title("Vietnam Map + Weather API")
                        .version("1.0.0")
                        .description("REST API for Vietnam administrative boundaries and real-time weather data. " +
                                "Provides geographic data (provinces, districts, wards) with GeoJSON boundaries " +
                                "and weather information from OpenWeatherMap API.")
                        .contact(new Contact()
                                .name("VN Map Team")
                                .email("contact@vnmap.com"))
                        .license(new License()
                                .name("MIT License")
                                .url("https://opensource.org/licenses/MIT")))
                .servers(List.of(
                        new Server()
                                .url("http://localhost:" + serverPort)
                                .description("Local Development Server"),
                        new Server()
                                .url("https://api.vnmap.com")
                                .description("Production Server")))
                .tags(Arrays.asList(
                        new Tag().name("Geo").description("Administrative boundary APIs"),
                        new Tag().name("Weather").description("Weather data APIs"),
                        new Tag().name("Health").description("Health check endpoints")));
    }
}
