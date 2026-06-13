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
public class CommitteeLocationDto {

    private Long id;
    private String code;
    private String name;
    private String type;
    private String parentCode;
    private String address;
    private String phone;
    private Double centroidLat;
    private Double centroidLng;
}
