package com.vnmap.weather.cache;

import com.vnmap.weather.dto.CurrentWeatherDto;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.core.ValueOperations;

import java.time.Duration;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.mockito.ArgumentMatchers.any;

import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("WeatherCacheService Tests")
class WeatherCacheServiceTest {

    @Mock
    private RedisTemplate<String, Object> redisTemplate;

    @Mock
    private ValueOperations<String, Object> valueOperations;

    private WeatherCacheService cacheService;

    @BeforeEach
    void setUp() {
        cacheService = new WeatherCacheService(redisTemplate);
    }

    @Nested
    @DisplayName("buildCacheKey")
    class BuildCacheKey {

        @Test
        @DisplayName("should format coordinates with 2 decimal places")
        void shouldFormatCoordinates() {
            String key = cacheService.buildCacheKey(21.0285, 105.8542);
            assertThat(key).isEqualTo("weather:21.03:105.85");
        }

        @Test
        @DisplayName("should round down correctly")
        void shouldRoundDown() {
            String key = cacheService.buildCacheKey(21.024, 105.854);
            assertThat(key).isEqualTo("weather:21.02:105.85");
        }
    }

    @Nested
    @DisplayName("get")
    class Get {

        @Test
        @DisplayName("should return weather from cache")
        void shouldReturnFromCache() {
            CurrentWeatherDto dto = createWeatherDto(25.0, "Clear");
            when(redisTemplate.opsForValue()).thenReturn(valueOperations);
            when(valueOperations.get("weather:21.03:105.85")).thenReturn(dto);

            Optional<CurrentWeatherDto> result = cacheService.get("21.03:105.85");

            assertThat(result).isPresent();
            assertThat(result.get().getTemperature()).isEqualTo(25.0);
        }

        @Test
        @DisplayName("should prepend prefix if missing")
        void shouldPrependPrefixIfMissing() {
            CurrentWeatherDto dto = createWeatherDto(25.0, "Clear");
            when(redisTemplate.opsForValue()).thenReturn(valueOperations);
            when(valueOperations.get("weather:21.03:105.85")).thenReturn(dto);

            cacheService.get("21.03:105.85");

            verify(valueOperations).get("weather:21.03:105.85");
        }

        @Test
        @DisplayName("should return empty when cache miss")
        void shouldReturnEmptyWhenMiss() {
            when(redisTemplate.opsForValue()).thenReturn(valueOperations);
            when(valueOperations.get(any())).thenReturn(null);

            Optional<CurrentWeatherDto> result = cacheService.get("21.03:105.85");

            assertThat(result).isEmpty();
        }

        @Test
        @DisplayName("should return empty when Redis throws")
        void shouldReturnEmptyOnError() {
            when(redisTemplate.opsForValue()).thenThrow(new RuntimeException("Redis down"));

            Optional<CurrentWeatherDto> result = cacheService.get("21.03:105.85");

            assertThat(result).isEmpty();
        }
    }

    @Nested
    @DisplayName("put")
    class Put {

        @Test
        @DisplayName("should store weather with TTL")
        void shouldStoreWithTtl() {
            CurrentWeatherDto dto = createWeatherDto(25.0, "Clear");
            when(redisTemplate.opsForValue()).thenReturn(valueOperations);

            cacheService.put("21.03:105.85", dto);

            verify(valueOperations).set(
                    "weather:21.03:105.85",
                    dto,
                    Duration.ofMinutes(10));
        }

        @Test
        @DisplayName("should handle Redis error gracefully")
        void shouldHandleErrorGracefully() {
            when(redisTemplate.opsForValue()).thenThrow(new RuntimeException("Redis error"));
            CurrentWeatherDto dto = createWeatherDto(25.0, "Clear");

            assertThatCode(() -> cacheService.put("21.03:105.85", dto)).doesNotThrowAnyException();
        }
    }

    @Nested
    @DisplayName("evict")
    class Evict {

        @Test
        @DisplayName("should delete cache key")
        void shouldDeleteKey() {
            cacheService.evict("weather:21.03:105.85");

            verify(redisTemplate).delete("weather:21.03:105.85");
        }

        @Test
        @DisplayName("should handle Redis error gracefully")
        void shouldHandleErrorGracefully() {
            doThrow(new RuntimeException("Redis error")).when(redisTemplate).delete((String) any());

            assertThatCode(() -> cacheService.evict("weather:21.03:105.85")).doesNotThrowAnyException();
        }
    }

    private CurrentWeatherDto createWeatherDto(double temp, String desc) {
        return CurrentWeatherDto.builder()
                .temperature(temp)
                .description(desc)
                .humidity(70)
                .windSpeed(5.0)
                .cached(false)
                .build();
    }
}
