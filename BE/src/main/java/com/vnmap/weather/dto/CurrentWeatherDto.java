package com.vnmap.weather.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;
import java.time.Instant;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
public class CurrentWeatherDto implements Serializable {

    private static final long serialVersionUID = 1L;

    private Double temperature;
    private Double feelsLike;
    private Integer humidity;
    private Double windSpeed;
    private String description;
    private String iconCode;
    private String locationName;
    private Integer pressure;
    private Integer visibility;
    private Double tempMin;
    private Double tempMax;
    private Instant timestamp;
    private String source;
    @Builder.Default
    private boolean cached = false;
}
