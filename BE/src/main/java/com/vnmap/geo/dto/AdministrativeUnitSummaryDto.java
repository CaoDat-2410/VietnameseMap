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
public class AdministrativeUnitSummaryDto {

    private Long id;
    private String code;
    private String name;
    private UnitLevel level;
    private Long parentId;
    private String parentCode;
}
