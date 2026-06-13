const { Client } = require('pg');

async function test() {
  const client = new Client({
    host: 'localhost',
    port: 5432,
    database: 'vnmapdb',
    user: 'postgres',
    password: '123456'
  });

  try {
    await client.connect();
    
    // Test with ST_Multi wrapping like the import script
    const result = await client.query(`
      INSERT INTO administrative_units (code, name, level, boundary)
      VALUES (
        '99997',
        'Test MultiPoly Cast',
        'COMMUNE',
        ST_SetSRID(
          ST_Multi(
            ST_GeomFromGeoJSON('{"type":"Polygon","coordinates":[[[105.8,21.0],[105.8,21.1],[105.9,21.1],[105.9,21.0],[105.8,21.0]]]}')
          ), 4326
        )::geometry(MultiPolygon, 4326)
      )
      ON CONFLICT (code) DO UPDATE SET name = EXCLUDED.name
      RETURNING id, code, name
    `);
    
    console.log('Insert with cast result:', result.rows);
    
    console.log('Insert result:', result.rows);
    
    // Count
    const count = await client.query("SELECT COUNT(*) FROM administrative_units WHERE level = 'COMMUNE'");
    console.log('Commune count:', count.rows);
    
  } catch (err) {
    console.error('Error:', err.message);
  } finally {
    await client.end();
  }
}

test();
