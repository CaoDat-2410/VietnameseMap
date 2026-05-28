package com.vnmap.geo.mapper;

import com.vnmap.geo.dto.AdministrativeUnitDto;
import com.vnmap.geo.dto.AdministrativeUnitSummaryDto;
import com.vnmap.geo.entity.AdministrativeUnit;
import org.mapstruct.BeanMapping;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.NullValuePropertyMappingStrategy;

import java.util.List;

@Mapper(componentModel = "spring", nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE)
public interface GeoMapper {

    @BeanMapping(ignoreUnmappedSourceProperties = {"boundary", "centroid"})
    @Mapping(target = "parentCode", ignore = true)
    @Mapping(target = "childCount", ignore = true)
    @Mapping(target = "centroidLat", ignore = true)
    @Mapping(target = "centroidLng", ignore = true)
    AdministrativeUnitDto toDto(AdministrativeUnit entity);

    @BeanMapping(ignoreUnmappedSourceProperties = {"boundary", "centroid", "parentId"})
    @Mapping(target = "parentCode", ignore = true)
    AdministrativeUnitSummaryDto toSummaryDto(AdministrativeUnit entity);

    List<AdministrativeUnitDto> toDtoList(List<AdministrativeUnit> entities);

    List<AdministrativeUnitSummaryDto> toSummaryDtoList(List<AdministrativeUnit> entities);

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "parentId", ignore = true)
    @Mapping(target = "boundary", ignore = true)
    @Mapping(target = "centroid", ignore = true)
    AdministrativeUnit toEntity(AdministrativeUnitDto dto);
}
