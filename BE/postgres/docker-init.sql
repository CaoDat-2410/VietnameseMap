-- Create PostGIS extension
CREATE EXTENSION IF NOT EXISTS postgis;

-- Create administrative_units table
CREATE TABLE IF NOT EXISTS administrative_units (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    code VARCHAR(50) NOT NULL UNIQUE,
    level VARCHAR(20) NOT NULL,
    parent_id BIGINT REFERENCES administrative_units(id),
    boundary GEOMETRY(Geometry, 4326),
    centroid GEOMETRY(Point, 4326),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_unit_code ON administrative_units(code);
CREATE INDEX IF NOT EXISTS idx_unit_level ON administrative_units(level);
CREATE INDEX IF NOT EXISTS idx_unit_parent ON administrative_units(parent_id);
CREATE INDEX IF NOT EXISTS idx_boundary_gist ON administrative_units USING GIST(boundary);
CREATE INDEX IF NOT EXISTS idx_centroid ON administrative_units USING GIST(centroid);
