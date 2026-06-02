package com.vnmap.common.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class CorsConfig implements WebMvcConfigurer {

    @Value("${cors.allowed-origins:*}")
    private String allowedOriginsRaw;

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        String[] patterns = allowedOriginsRaw.split(",");
        // Strip whitespace from each pattern
        for (int i = 0; i < patterns.length; i++) {
            patterns[i] = patterns[i].trim();
        }

        boolean wildcardOnly = patterns.length == 1 && patterns[0].equals("*");

        registry.addMapping("/**")
                .allowedOriginPatterns(patterns)
                .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH")
                .allowedHeaders("*")
                .exposedHeaders(
                        "Access-Control-Allow-Origin",
                        "Access-Control-Allow-Credentials",
                        "Content-Disposition"
                )
                // credentials + bare "*" is rejected by the spec
                .allowCredentials(!wildcardOnly)
                .maxAge(3600L);
    }
}
