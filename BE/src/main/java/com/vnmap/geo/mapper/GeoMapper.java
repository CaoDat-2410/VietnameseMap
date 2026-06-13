package com.vnmap.geo.mapper;

import com.vnmap.geo.dto.AdministrativeUnitDto;
import com.vnmap.geo.dto.AdministrativeUnitSummaryDto;
import com.vnmap.geo.dto.CommitteeLocationDto;
import com.vnmap.geo.entity.AdministrativeUnit;
import com.vnmap.geo.entity.CommitteeLocation;
import org.mapstruct.BeanMapping;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.NullValuePropertyMappingStrategy;

import java.util.List;

@Mapper(componentModel = "spring", nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE)
public interface GeoMapper {

    @BeanMapping(ignoreUnmappedSourceProperties = {"boundary", "centroid"})
    @Mapping(target = "childCount", ignore = true)
    AdministrativeUnitDto toDto(AdministrativeUnit entity);

    @BeanMapping(ignoreUnmappedSourceProperties = {"boundary", "centroid",
            "areaKm2", "population", "density", "capital", "decree", "decreeUrl",
            "macroRegion", "predecessors"})
    AdministrativeUnitSummaryDto toSummaryDto(AdministrativeUnit entity);

    List<AdministrativeUnitDto> toDtoList(List<AdministrativeUnit> entities);

    List<AdministrativeUnitSummaryDto> toSummaryDtoList(List<AdministrativeUnit> entities);

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "boundary", ignore = true)
    @Mapping(target = "centroid", ignore = true)
    @Mapping(target = "centroidLon", source = "centroidLng")
    @Mapping(target = "centroidLat", source = "centroidLat")
    AdministrativeUnit toEntity(AdministrativeUnitDto dto);

    @BeanMapping(ignoreUnmappedSourceProperties = {"centroid"})
    CommitteeLocationDto toCommitteeDto(CommitteeLocation entity);

    List<CommitteeLocationDto> toCommitteeDtoList(List<CommitteeLocation> entities);
}
