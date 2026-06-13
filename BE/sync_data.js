const { Client } = require('pg');

async function syncData() {
  // Connect to pgpool (source with data)
  const source = new Client({
    host: 'localhost',
    port: 5432,
    database: 'vnmapdb',
    user: 'postgres',
    password: '123456'
  });
  
  try {
    console.log('Connecting to pgpool (source)...');
    await source.connect();
    
    // Get all data from pgpool
    const result = await source.query(`
      SELECT id, code, name, level, parent_id, 
             ST_AsGeoJSON(boundary) as boundary_json,
             centroid_lat, centroid_lng, area_km2, population, density,
             capital, address, phone, decree, decree_url, macro_region, npredecessors
      FROM administrative_units
    `);
    
    console.log(`Found ${result.rows.length} records in pgpool`);
    
    // Count by level
    const counts = await source.query(`
      SELECT level, COUNT(*) 
      FROM administrative_units 
      GROUP BY level
    `);
    console.log('Source counts:');
    counts.rows.forEach(r => console.log(`  ${r.level}: ${r.count}`));
    
    console.log('\nData ready to sync. Please run the sync via Docker exec.');
    console.log('Or we can truncate and re-import all data to vnmap_postgres');
    
    await source.end();
  } catch (e) {
    console.error('Error:', e.message);
    if (source.ended === false) await source.end();
  }
}

syncData();
