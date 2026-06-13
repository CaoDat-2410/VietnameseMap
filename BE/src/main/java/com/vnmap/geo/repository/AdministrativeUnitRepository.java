package com.vnmap.geo.repository;

import com.vnmap.geo.entity.AdministrativeUnit;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface AdministrativeUnitRepository extends JpaRepository<AdministrativeUnit, Long> {

    List<AdministrativeUnit> findByKind(String kind);

    List<AdministrativeUnit> findByParentCode(String parentCode);

    Optional<AdministrativeUnit> findByCode(String code);

    Optional<AdministrativeUnit> findByCodeAndKind(String code, String kind);

    List<AdministrativeUnit> findByMacroRegion(String macroRegion);

    @Query("SELECT COUNT(u) FROM AdministrativeUnit u WHERE u.parentCode = :parentCode")
    int countByParentCode(@Param("parentCode") String parentCode);

    @Query(value = "SELECT ST_AsGeoJSON(boundary) FROM administrative_units WHERE code = :code AND kind = :kind AND boundary IS NOT NULL LIMIT 1", nativeQuery = true)
    Optional<String> findBoundaryByCodeAndKind(@Param("code") String code, @Param("kind") String kind);

    @Query(value = "SELECT ST_AsGeoJSON(boundary) FROM administrative_units WHERE id = :id AND boundary IS NOT NULL", nativeQuery = true)
    Optional<String> findBoundaryGeoJsonById(@Param("id") Long id);

    @Query(value = "SELECT ST_X(centroid) as lng, ST_Y(centroid) as lat FROM administrative_units WHERE code = :code AND kind = :kind AND centroid IS NOT NULL", nativeQuery = true)
    Optional<Object[]> findCentroidByCode(@Param("code") String code, @Param("kind") String kind);

    // Reverse geocode: search COMMUNE first, then PROVINCE
    @Query(value = """
            SELECT au.* FROM administrative_units au
            WHERE au.kind = 'commune' AND ST_Contains(au.boundary, ST_SetSRID(ST_MakePoint(:lng, :lat), 4326))
            UNION ALL
            SELECT au.* FROM administrative_units au
            WHERE au.kind = 'province' AND ST_Contains(au.boundary, ST_SetSRID(ST_MakePoint(:lng, :lat), 4326))
            LIMIT 1
            """, nativeQuery = true)
    Optional<AdministrativeUnit> findUnitContainingPoint(@Param("lat") double lat, @Param("lng") double lng);

    // Find all commune boundaries for a province (for map display)
    @Query(value = """
            SELECT au.id, au.name, au.code, au.kind, au.parent_code,
                   ST_AsGeoJSON(au.boundary) as boundary_json,
                   ST_X(au.centroid) as centroid_lng, ST_Y(au.centroid) as centroid_lat
            FROM administrative_units au
            WHERE au.kind = 'commune'
            AND au.parent_code = :provinceCode
            AND au.boundary IS NOT NULL
            """, nativeQuery = true)
    List<Object[]> findCommunesWithBoundariesByProvinceCode(@Param("provinceCode") String provinceCode);
}
