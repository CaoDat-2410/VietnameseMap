package com.vnmap.geo.repository;

import com.vnmap.geo.entity.AdministrativeUnit;
import com.vnmap.geo.enums.UnitLevel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

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
}
