package com.vnmap.geo.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GeoJsonFeatureDto {

    private Long id;
    private String type;
    private String code;
    private String name;
    private String kind;  // 'province' | 'commune'
    private String parentCode;
    private GeometryDto geometry;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class GeometryDto {
        private String type;
        private Object coordinates;
    }
}
