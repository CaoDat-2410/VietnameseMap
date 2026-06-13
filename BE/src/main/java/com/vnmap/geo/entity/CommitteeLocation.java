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
import org.locationtech.jts.geom.Point;

import java.math.BigDecimal;

@Entity
@Table(name = "committee_locations", indexes = {
        @Index(name = "idx_committee_parent", columnList = "parent_code")
})
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CommitteeLocation {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, length = 64)
    private String code;   // HuggingFace: 'ma'

    @Column(nullable = false, length = 255)
    private String name;   // HuggingFace: 'ten'

    @Column(length = 50)
    private String type;   // HuggingFace: 'type'

    @Column(name = "parent_code", nullable = false, length = 20)
    private String parentCode;   // FK to province.code; HuggingFace: 'parent_ma'

    @Column(columnDefinition = "TEXT")
    private String address;   // HuggingFace: 'address'

    @Column(length = 50)
    private String phone;   // HuggingFace: 'phone'

    @Column(columnDefinition = "geometry(Point, 4326)")
    private Point centroid;

    @Column(name = "centroid_lon", precision = 10, scale = 7)
    private BigDecimal centroidLon;

    @Column(name = "centroid_lat", precision = 10, scale = 7)
    private BigDecimal centroidLat;
}
