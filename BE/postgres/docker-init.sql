-- ============================================
-- Vietnam Administrative Units (Post-2025 Reform)
-- HuggingFace Dataset: tmquan/sapnhap-bando-vn
-- Requires: PostgreSQL 9.5+ (for ON CONFLICT DO UPDATE)
-- ============================================

-- Create PostGIS extension
CREATE EXTENSION IF NOT EXISTS postgis;

-- ============================================
-- Table 1: administrative_units (provinces + communes)
-- ============================================
DROP TABLE IF EXISTS administrative_units CASCADE;
CREATE TABLE administrative_units (
    id BIGSERIAL PRIMARY KEY,
    kind VARCHAR(20) NOT NULL,           -- 'province' | 'commune'
    code VARCHAR(20) NOT NULL UNIQUE,    -- HuggingFace: 'ma'
    name VARCHAR(255) NOT NULL,           -- HuggingFace: 'ten'
    type VARCHAR(50),                     -- HuggingFace: 'type' (loại đơn vị hành chính)
    parent_code VARCHAR(20),              -- FK to province.code (null for provinces)
                                          -- HuggingFace: 'parent_ma'

    -- Extended fields from HuggingFace dataset
    area_km2 DECIMAL(10,2),
    population BIGINT,
    density DECIMAL(10,2),
    capital VARCHAR(100),

    -- Geographic
    boundary GEOMETRY(Geometry, 4326),
    centroid GEOMETRY(Point, 4326),
    centroid_lon DECIMAL(10,7),
    centroid_lat DECIMAL(10,7),

    -- Administrative
    decree VARCHAR(255),
    decree_url TEXT,
    macro_region VARCHAR(100),
    n_predecessors INTEGER,
    predecessors TEXT,                    -- Merger lineage prose

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- FK: commune.parent_code references province.code
-- Deferrable so import script can load in order: provinces first, then communes
ALTER TABLE administrative_units
ADD CONSTRAINT fk_parent
FOREIGN KEY (parent_code) REFERENCES administrative_units(code)
DEFERRABLE INITIALLY DEFERRED;

-- Indexes
CREATE INDEX idx_unit_kind ON administrative_units(kind);
CREATE INDEX idx_unit_code ON administrative_units(code);
CREATE INDEX idx_unit_parent_code ON administrative_units(parent_code);
CREATE INDEX idx_unit_macro_region ON administrative_units(macro_region);
CREATE INDEX idx_boundary_gist ON administrative_units USING GIST(boundary);
CREATE INDEX idx_centroid_gist ON administrative_units USING GIST(centroid);

-- ============================================
-- Table 2: committee_locations (People's Committee HQ / Trụ sở UBND)
-- ============================================
DROP TABLE IF EXISTS committee_locations CASCADE;
CREATE TABLE committee_locations (
    id BIGSERIAL PRIMARY KEY,
    code VARCHAR(64) NOT NULL UNIQUE,    -- HuggingFace: 'id' (e.g. 'uybannhandancapxa_2025.1')
    name VARCHAR(255) NOT NULL,           -- HuggingFace: 'ten'
    type VARCHAR(50),                     -- HuggingFace: 'type'
    parent_code VARCHAR(20),           -- FK to province.code; nullable for orphan records (HuggingFace: 'parent_ma')
    address TEXT,
    phone VARCHAR(50),
    centroid GEOMETRY(Point, 4326),
    centroid_lon DECIMAL(10,7),
    centroid_lat DECIMAL(10,7),

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_committee_parent ON committee_locations(parent_code);
CREATE INDEX idx_committee_centroid_gist ON committee_locations USING GIST(centroid);

\i /docker-entrypoint-initdb.d/campaign-module.sql
