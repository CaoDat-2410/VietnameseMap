package com.vnmap.geo.dto;

import com.vnmap.geo.enums.UnitLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AdministrativeUnitDto {

    private Long id;
    private String name;
    private String code;
    private UnitLevel level;
    private Long parentId;
    private String parentCode;
    private Double centroidLat;
    private Double centroidLng;
    private Integer childCount;
}
