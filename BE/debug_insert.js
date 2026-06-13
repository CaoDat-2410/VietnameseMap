const { Client } = require('pg');
const fs = require('fs');

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
    console.log('Connected to:', await client.query('SELECT current_database()'));
    
    // Start transaction
    await client.query('BEGIN');
    
    // Read one feature from GeoJSON
    const content = fs.readFileSync('../FE/assets/geo/communes.geojson', 'utf8').replace(/\bNaN\b/g, 'null');
    const data = JSON.parse(content);
    const feature = data.features[0];
    
    console.log('Feature:', feature.properties.ten);
    console.log('Geom type:', feature.geometry.type);
    
    // Test insert with same SQL as import script
    const result = await client.query(`
      INSERT INTO administrative_units (code, name, level, boundary)
      VALUES (
        $1,
        $2,
        'COMMUNE',
        ST_SetSRID(
          ST_Multi(
            ST_CollectionExtract(
              ST_MakeValid(
                ST_GeomFromGeoJSON($3)
              ), 3
            )
          ), 4326
        )::geometry(MultiPolygon, 4326)
      )
      ON CONFLICT (code) DO UPDATE SET name = EXCLUDED.name
      RETURNING id, code, name
    `, [feature.properties.ma, feature.properties.ten, JSON.stringify(feature.geometry)]);
    
    console.log('Insert result:', result.rows);
    
    // Count before commit
    const countBefore = await client.query("SELECT COUNT(*) FROM administrative_units WHERE level = 'COMMUNE'");
    console.log('Commune count before commit:', countBefore.rows);
    
    await client.query('COMMIT');
    
    // Count after commit
    const countAfter = await client.query("SELECT COUNT(*) FROM administrative_units WHERE level = 'COMMUNE'");
    console.log('Commune count after commit:', countAfter.rows);
    
    await client.end();
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Error:', err.message);
    await client.end();
  }
}

test();
