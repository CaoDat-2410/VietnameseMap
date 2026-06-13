package com.vnmap.geo.dto;

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
    private String kind;       // 'province' | 'commune'
    private String type;       // 'Tỉnh' | 'Thành phố' | 'Phường' | 'Xã' | 'Thị trấn'
    private String parentCode;  // FK to province.code (null for provinces)
}
