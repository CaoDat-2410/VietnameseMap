package com.vnmap.weather.cache;

import com.vnmap.weather.dto.CurrentWeatherDto;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.util.Optional;

@Service
public class WeatherCacheService {

    private static final Logger log = LoggerFactory.getLogger(WeatherCacheService.class);
    private static final String CACHE_PREFIX = "weather:";
    private static final Duration CACHE_TTL = Duration.ofMinutes(10);

    private final RedisTemplate<String, Object> redisTemplate;

    public WeatherCacheService(RedisTemplate<String, Object> redisTemplate) {
        this.redisTemplate = redisTemplate;
    }

    public Optional<CurrentWeatherDto> get(String cacheKey) {
        try {
            String key = buildCacheKey(cacheKey);
            Object cached = redisTemplate.opsForValue().get(key);
            if (cached instanceof CurrentWeatherDto weather) {
                log.debug("Cache hit for key: {}", key);
                return Optional.of(weather);
            }
        } catch (Exception e) {
            log.warn("Failed to get from cache: {}", e.getMessage());
        }
        return Optional.empty();
    }

    public void put(String cacheKey, CurrentWeatherDto weather) {
        try {
            String key = buildCacheKey(cacheKey);
            redisTemplate.opsForValue().set(key, weather, CACHE_TTL);
            log.debug("Cached weather data with key: {} (TTL: {})", key, CACHE_TTL);
        } catch (Exception e) {
            log.warn("Failed to put in cache: {}", e.getMessage());
        }
    }

    public void evict(String cacheKey) {
        try {
            String key = buildCacheKey(cacheKey);
            redisTemplate.delete(key);
            log.debug("Evicted cache key: {}", key);
        } catch (Exception e) {
            log.warn("Failed to evict from cache: {}", e.getMessage());
        }
    }

    public String buildCacheKey(double lat, double lng) {
        String latStr = String.format("%.2f", lat);
        String lngStr = String.format("%.2f", lng);
        return String.format("%s%s:%s", CACHE_PREFIX, latStr, lngStr);
    }

    private String buildCacheKey(String cacheKey) {
        return cacheKey.startsWith(CACHE_PREFIX) ? cacheKey : CACHE_PREFIX + cacheKey;
    }
}
