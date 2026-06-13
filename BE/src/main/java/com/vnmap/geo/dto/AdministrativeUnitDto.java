package com.vnmap.geo.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AdministrativeUnitDto {

    private Long id;
    private String kind;       // 'province' | 'commune'
    private String name;
    private String code;
    private String type;       // 'Tỉnh' | 'Thành phố' | 'Phường' | 'Xã' | 'Thị trấn'
    private String parentCode;  // FK to province.code (null for provinces)
    private String centroidCode;
    private Double centroidLat;
    private Double centroidLng;
    private Integer childCount;

    // Extended fields from HuggingFace dataset
    private BigDecimal areaKm2;
    private Long population;
    private BigDecimal density;
    private String capital;
    private String address;
    private String phone;
    private String decree;
    private String decreeUrl;
    private String macroRegion;
    private Integer nPredecessors;
    private String predecessors;
}
