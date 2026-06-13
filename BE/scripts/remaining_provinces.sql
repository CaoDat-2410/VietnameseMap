-- Add remaining 2 provinces to complete all 34
INSERT INTO administrative_units (name, code, level, boundary, centroid, area_km2, population, density, capital, address, phone, decree, decree_url, macro_region, n_predecessors)
VALUES
('Bắc Kạn', '22', 'PROVINCE', ST_GeomFromText('POLYGON((105.6 21.9, 106.3 21.9, 106.3 22.5, 105.6 22.5, 105.6 21.9))', 4326), ST_GeomFromText('POINT(105.95 22.2)', 4326), 4859.38, 305000, 63, 'Bắc Kạn', '01 Hoàng Đình, Bắc Kạn', '0209 3871 234', 'Resolution 2025/QH15', 'https://vnepi.edu.vn', 'Đông Bắc', 1),
('Nghệ An', '40', 'PROVINCE', ST_GeomFromText('POLYGON((104.0 18.5, 105.8 18.5, 105.8 19.8, 104.0 19.8, 104.0 18.5))', 4326), ST_GeomFromText('POINT(104.9 19.15)', 4326), 14927.45, 3368000, 226, 'Vinh', '02 Lê Mao, Vinh', '0238 3821 234', 'Resolution 2025/QH15', 'https://vnepi.edu.vn', 'Bắc Trung Bộ', 1);

SELECT level, COUNT(*) FROM administrative_units GROUP BY level ORDER BY level;
