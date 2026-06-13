-- Insert sample provinces (34 provinces with new 2025 codes)
INSERT INTO administrative_units (name, code, level, boundary, centroid, area_km2, population, density, capital, address, phone, decree, decree_url, macro_region, n_predecessors)
VALUES
('Hà Nội', '01', 'PROVINCE', ST_GeomFromText('POLYGON((105.3 20.8, 105.8 20.8, 105.8 21.2, 105.3 21.2, 105.3 20.8))', 4326), ST_GeomFromText('POINT(105.55 21.0)', 4326), 3359.82, 8504000, 2532, 'Hà Nội', '01 Trần Phú, Hoàn Kiếm', '024 3825 4029', 'Địa giới hành chính 2025', 'https://vnepi.edu.vn', 'Đồng bằng sông Hồng', 1),
('Hồ Chí Minh', '79', 'PROVINCE', ST_GeomFromText('POLYGON((106.5 10.3, 107.0 10.3, 107.0 10.9, 106.5 10.9, 106.5 10.3))', 4326), ST_GeomFromText('POINT(106.75 10.6)', 4326), 2061.42, 9000000, 4365, 'TP. Hồ Chí Minh', '86 Lý Tự Trọng, Quận 1', '028 3829 9141', 'Địa giới hành chính 2025', 'https://vnepi.edu.vn', 'Đông Nam Bộ', 1),
('Đà Nẵng', '48', 'PROVINCE', ST_GeomFromText('POLYGON((108.0 15.9, 108.3 15.9, 108.3 16.2, 108.0 16.2, 108.0 15.9))', 4326), ST_GeomFromText('POINT(108.15 16.05)', 4326), 1284.87, 1238000, 963, 'Đà Nẵng', '06 Trần Phú, Hải Châu', '0236 3821 234', 'Địa giới hành chính 2025', 'https://vnepi.edu.vn', 'Bắc Trung Bộ', 1),
('Hải Phòng', '31', 'PROVINCE', ST_GeomFromText('POLYGON((106.4 20.5, 107.0 20.5, 107.0 21.0, 106.4 21.0, 106.4 20.5))', 4326), ST_GeomFromText('POINT(106.7 20.75)', 4326), 1561.79, 2048000, 1311, 'Hải Phòng', '18 Hoàng Van Thu, Ngô Quyền', '0225 3840 789', 'Địa giới hành chính 2025', 'https://vnepi.edu.vn', 'Đồng bằng sông Hồng', 1),
('Cần Thơ', '92', 'PROVINCE', ST_GeomFromText('POLYGON((105.4 10.0, 105.8 10.0, 105.8 10.4, 105.4 10.4, 105.4 10.0))', 4326), ST_GeomFromText('POINT(105.6 10.2)', 4326), 1439.23, 1240000, 862, 'Cần Thơ', '01 Hùng Vương, Ninh Kiều', '0292 3820 012', 'Địa giới hành chính 2025', 'https://vnepi.edu.vn', 'Đồng bằng sông Cửu Long', 1);

-- Insert sample communes
WITH province_ids AS (
    SELECT id, code FROM administrative_units WHERE level = 'PROVINCE'
)
INSERT INTO administrative_units (name, code, level, parent_id, boundary, centroid, area_km2, population, density, macro_region)
SELECT 
    'Ba Đình' as name,
    '001' as code,
    'COMMUNE' as level,
    p.id as parent_id,
    ST_GeomFromText('POLYGON((105.82 21.03, 105.84 21.03, 105.84 21.05, 105.82 21.05, 105.82 21.03))', 4326) as boundary,
    ST_GeomFromText('POINT(105.83 21.04)', 4326) as centroid,
    12.04 as area_km2,
    247100 as population,
    20523 as density,
    'Đồng bằng sông Hồng' as macro_region
FROM province_ids p WHERE p.code = '01'
UNION ALL
SELECT 
    'Hoàn Kiếm' as name,
    '002' as code,
    'COMMUNE' as level,
    p.id as parent_id,
    ST_GeomFromText('POLYGON((105.84 21.02, 105.88 21.02, 105.88 21.04, 105.84 21.04, 105.84 21.02))', 4326) as boundary,
    ST_GeomFromText('POINT(105.86 21.03)', 4326) as centroid,
    9.22 as area_km2,
    180200 as population,
    19545 as density,
    'Đồng bằng sông Hồng' as macro_region
FROM province_ids p WHERE p.code = '01'
UNION ALL
SELECT 
    'Tân Bình' as name,
    '001' as code,
    'COMMUNE' as level,
    p.id as parent_id,
    ST_GeomFromText('POLYGON((106.62 10.78, 106.68 10.78, 106.68 10.84, 106.62 10.84, 106.62 10.78))', 4326) as boundary,
    ST_GeomFromText('POINT(106.65 10.81)', 4326) as centroid,
    8.15 as area_km2,
    445000 as population,
    54596 as density,
    'Đông Nam Bộ' as macro_region
FROM province_ids p WHERE p.code = '79'
UNION ALL
SELECT 
    'Thủ Đức' as name,
    '002' as code,
    'COMMUNE' as level,
    p.id as parent_id,
    ST_GeomFromText('POLYGON((106.72 10.82, 106.80 10.82, 106.80 10.88, 106.72 10.88, 106.72 10.82))', 4326) as boundary,
    ST_GeomFromText('POINT(106.76 10.85)', 4326) as centroid,
    48.11 as area_km2,
    580000 as population,
    12056 as density,
    'Đông Nam Bộ' as macro_region
FROM province_ids p WHERE p.code = '79';

SELECT level, COUNT(*) FROM administrative_units GROUP BY level ORDER BY level;
