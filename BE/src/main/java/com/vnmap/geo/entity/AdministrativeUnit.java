package com.vnmap.geo.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
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

import java.math.BigDecimal;

@Entity
@Table(name = "administrative_units", indexes = {
        @Index(name = "idx_unit_code", columnList = "code"),
        @Index(name = "idx_unit_kind", columnList = "kind"),
        @Index(name = "idx_unit_parent_code", columnList = "parent_code"),
        @Index(name = "idx_unit_macro_region", columnList = "macro_region")
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

    @Column(nullable = false, length = 20)
    private String kind;   // 'province' | 'commune'

    @Column(nullable = false, unique = true, length = 20)
    private String code;   // HuggingFace: 'ma'

    @Column(nullable = false, length = 255)
    private String name;   // HuggingFace: 'ten'

    @Column(length = 50)
    private String type;   // HuggingFace: 'type' — 'Tỉnh' | 'Thành phố' | 'Phường' | 'Xã' | 'Thị trấn'

    @Column(name = "parent_code", length = 20)
    private String parentCode;   // FK to province.code (null for provinces); HuggingFace: 'parent_ma'

    // Extended fields from HuggingFace dataset
    @Column(name = "area_km2", precision = 10, scale = 2)
    private BigDecimal areaKm2;

    @Column
    private Long population;

    @Column(name = "density", precision = 10, scale = 2)
    private BigDecimal density;

    @Column(length = 100)
    private String capital;

    @Column(columnDefinition = "geometry(Geometry, 4326)")
    private Geometry boundary;

    @Column(columnDefinition = "geometry(Point, 4326)")
    private Point centroid;

    @Column(name = "centroid_lon", precision = 10, scale = 7)
    private BigDecimal centroidLon;

    @Column(name = "centroid_lat", precision = 10, scale = 7)
    private BigDecimal centroidLat;

    @Column(length = 255)
    private String decree;

    @Column(name = "decree_url", columnDefinition = "TEXT")
    private String decreeUrl;

    @Column(name = "macro_region", length = 100)
    private String macroRegion;

    @Column(name = "n_predecessors")
    private Integer nPredecessors;

    @Column(columnDefinition = "TEXT")
    private String predecessors;   // Merger lineage prose
}
