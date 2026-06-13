package com.vnmap.geo.repository;

import com.vnmap.geo.entity.CommitteeLocation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CommitteeLocationRepository extends JpaRepository<CommitteeLocation, Long> {

    List<CommitteeLocation> findByParentCode(String parentCode);

    long countByParentCode(String parentCode);
}
