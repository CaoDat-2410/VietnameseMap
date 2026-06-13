INSERT INTO administrative_units (code, name, level, boundary)
VALUES (
  '99999',
  'Test Commune',
  'COMMUNE',
  ST_SetSRID(
    ST_Multi(
      ST_CollectionExtract(
        ST_MakeValid(
          ST_GeomFromGeoJSON('{"type":"MultiPolygon","coordinates":[[[[105.8,21.0],[105.8,21.1],[105.9,21.1],[105.9,21.0],[105.8,21.0]]]]}')
        ), 3
      )
    ), 4326
  )::geometry(MultiPolygon, 4326)
)
RETURNING id, code, name;
