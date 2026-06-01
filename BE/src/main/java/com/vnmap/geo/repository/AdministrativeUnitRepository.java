package com.vnmap.geo.repository;

import com.vnmap.geo.entity.AdministrativeUnit;
import com.vnmap.geo.enums.UnitLevel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.locationtech.jts.geom.Point;

import java.util.List;
import java.util.Optional;

@Repository
public interface AdministrativeUnitRepository extends JpaRepository<AdministrativeUnit, Long> {

    List<AdministrativeUnit> findByLevel(UnitLevel level);

    List<AdministrativeUnit> findByParentIdAndLevel(Long parentId, UnitLevel level);

    Optional<AdministrativeUnit> findByCode(String code);

    Optional<AdministrativeUnit> findByNameAndLevel(String name, UnitLevel level);

    @Query("SELECT COUNT(u) FROM AdministrativeUnit u WHERE u.parentId = :parentId")
    int countByParentId(@Param("parentId") Long parentId);

    @Query("SELECT DISTINCT u.parentId FROM AdministrativeUnit u WHERE u.parentId IS NOT NULL")
    List<Long> findAllParentIds();

    @Query("""
            SELECT u FROM AdministrativeUnit u
            WHERE u.parentId = :parentId
            """)
    List<AdministrativeUnit> findByParentId(@Param("parentId") Long parentId);

    @Query(value = """
            SELECT ST_AsGeoJSON(boundary)
            FROM administrative_units
            WHERE code = :code AND boundary IS NOT NULL
            """, nativeQuery = true)
    Optional<String> findBoundaryGeoJsonByCode(@Param("code") String code);

    @Query(value = """
            SELECT ST_X(centroid) as lng, ST_Y(centroid) as lat
            FROM administrative_units
            WHERE code = :code AND centroid IS NOT NULL
            """, nativeQuery = true)
    Optional<Object[]> findCentroidByCode(@Param("code") String code);

    @Query(value = """
            SELECT au.* FROM administrative_units au
            WHERE au.level = 'WARD'
              AND ST_Contains(au.boundary, ST_SetSRID(ST_MakePoint(:lng, :lat), 4326))
            UNION ALL
            SELECT au.* FROM administrative_units au
            WHERE au.level = 'DISTRICT'
              AND ST_Contains(au.boundary, ST_SetSRID(ST_MakePoint(:lng, :lat), 4326))
            UNION ALL
            SELECT au.* FROM administrative_units au
            WHERE au.level = 'PROVINCE'
              AND ST_Contains(au.boundary, ST_SetSRID(ST_MakePoint(:lng, :lat), 4326))
            LIMIT 1
            """, nativeQuery = true)
    Optional<AdministrativeUnit> findUnitContainingPoint(@Param("lat") double lat, @Param("lng") double lng);

    @Query(value = """
            SELECT id, name, code, level, parent_id,
                   ST_X(centroid) as centroid_lng,
                   ST_Y(centroid) as centroid_lat
            FROM administrative_units
            WHERE code = :code
            """, nativeQuery = true)
    Optional<Object[]> findWithCentroidByCode(@Param("code") String code);
}
