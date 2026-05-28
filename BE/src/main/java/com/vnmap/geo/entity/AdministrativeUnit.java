package com.vnmap.geo.entity;

import com.vnmap.geo.enums.UnitLevel;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.locationtech.jts.geom.Geometry;
import org.locationtech.jts.geom.Point;

@Entity
@Table(name = "administrative_units", indexes = {
        @Index(name = "idx_unit_code", columnList = "code"),
        @Index(name = "idx_unit_parent", columnList = "parent_id"),
        @Index(name = "idx_unit_level", columnList = "level")
})
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AdministrativeUnit {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 100)
    private String name;

    @Column(nullable = false, unique = true, length = 10)
    private String code;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private UnitLevel level;

    @Column(name = "parent_id")
    private Long parentId;

    @Column(columnDefinition = "geometry(Geometry, 4326)")
    private Geometry boundary;

    @Column(columnDefinition = "geometry(Point, 4326)")
    private Point centroid;
}
