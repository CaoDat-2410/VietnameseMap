package com.vnmap.weather.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;

import java.util.List;

@Data
@JsonIgnoreProperties(ignoreUnknown = true)
public class OpenWeatherApiResponse {

    @JsonProperty("coord")
    private Coord coord;

    @JsonProperty("weather")
    private List<Weather> weather;

    @JsonProperty("main")
    private Main main;

    @JsonProperty("wind")
    private Wind wind;

    @JsonProperty("clouds")
    private Clouds clouds;

    @JsonProperty("visibility")
    private Integer visibility;

    @JsonProperty("dt")
    private Long dateTime;

    @JsonProperty("sys")
    private Sys sys;

    @JsonProperty("timezone")
    private Integer timezone;

    @JsonProperty("id")
    private Long id;

    @JsonProperty("name")
    private String name;

    @JsonProperty("cod")
    private Integer cod;

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Coord {
        @JsonProperty("lon")
        private Double lon;

        @JsonProperty("lat")
        private Double lat;
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Weather {
        @JsonProperty("id")
        private Integer id;

        @JsonProperty("main")
        private String main;

        @JsonProperty("description")
        private String description;

        @JsonProperty("icon")
        private String icon;
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Main {
        @JsonProperty("temp")
        private Double temp;

        @JsonProperty("feels_like")
        private Double feelsLike;

        @JsonProperty("temp_min")
        private Double tempMin;

        @JsonProperty("temp_max")
        private Double tempMax;

        @JsonProperty("pressure")
        private Integer pressure;

        @JsonProperty("humidity")
        private Integer humidity;

        @JsonProperty("sea_level")
        private Integer seaLevel;

        @JsonProperty("grnd_level")
        private Integer grndLevel;
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Wind {
        @JsonProperty("speed")
        private Double speed;

        @JsonProperty("deg")
        private Integer deg;

        @JsonProperty("gust")
        private Double gust;
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Clouds {
        @JsonProperty("all")
        private Integer all;
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Sys {
        @JsonProperty("type")
        private Integer type;

        @JsonProperty("id")
        private Integer id;

        @JsonProperty("country")
        private String country;

        @JsonProperty("sunrise")
        private Long sunrise;

        @JsonProperty("sunset")
        private Long sunset;
    }
}
