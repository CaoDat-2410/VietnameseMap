const { Client } = require('pg');
const fs = require('fs');
const https = require('https');
const http = require('http');

const DB_CONFIG = {
  host: 'localhost',
  port: 5432,
  user: 'postgres',
  password: '123456',
  database: 'vnmapdb'
};

const COMMUNE_GEOJSON_URL = 'https://huggingface.co/datasets/tmquan/sapnhap-bando-vn/resolve/main/geo/communes.geojson';
const PROVINCE_GEOJSON_URL = 'https://huggingface.co/datasets/tmquan/sapnhap-bando-vn/resolve/main/geo/provinces.geojson';

const os = require('os');
const path = require('path');
const tempDir = os.tmpdir();
const tempFile = path.join(tempDir, 'temp_geojson.json');

function downloadFile(url) {
  return new Promise((resolve, reject) => {
    const file = fs.createWriteStream(tempFile);
    const protocol = url.startsWith('https') ? https : http;
    
    console.log(`Downloading ${url}...`);
    console.log(`Saving to ${tempFile}...`);
    protocol.get(url, (response) => {
      if (response.statusCode === 302 || response.statusCode === 301) {
        const redirectUrl = response.headers.location;
        console.log(`Redirecting to ${redirectUrl}...`);
        file.close();
        downloadFile(redirectUrl).then(resolve).catch(reject);
        return;
      }
      
      response.pipe(file);
      file.on('finish', () => {
        file.close();
        console.log('Download complete');
        resolve(tempFile);
      });
    }).on('error', (err) => {
      if (fs.existsSync(tempFile)) fs.unlinkSync(tempFile);
      reject(err);
    });
  });
}

async function loadGeoJson(filepath) {
  let content = fs.readFileSync(filepath, 'utf8');
  // Replace NaN, Infinity with null
  content = content.replace(/NaN/g, 'null').replace(/Infinity/g, 'null').replace(/-Infinity/g, 'null');
  return JSON.parse(content);
}

async function getExistingProvinces(client) {
  const result = await client.query('SELECT id, code FROM administrative_units WHERE level = $1', ['PROVINCE']);
  const map = new Map();
  result.rows.forEach(row => {
    map.set(row.code, row.id);
  });
  return map;
}

async function clearCommunes(client) {
  console.log('Clearing existing communes...');
  await client.query('DELETE FROM administrative_units WHERE level = $1', ['COMMUNE']);
}

async function insertCommunes(client, features, provinceMap) {
  console.log(`Inserting ${features.length} communes...`);
  
  const batchSize = 100;
  let inserted = 0;
  let errors = 0;
  
  for (let i = 0; i < features.length; i += batchSize) {
    const batch = features.slice(i, i + batchSize);
    const values = [];
    const params = [];
    let paramIndex = 1;
    
    for (const feature of batch) {
      const props = feature.properties;
      const geom = JSON.stringify(feature.geometry);
      
      // ma is the code, parent_ma is parent province code
      const provinceCode = props.parent_ma || props.ma?.substring(0, 2);
      const provinceId = provinceMap.get(provinceCode);
      
      if (!provinceId) {
        console.log(`Warning: Province not found for code ${provinceCode}, skipping commune ${props.ten}`);
        errors++;
        continue;
      }
      
      // Format: MA code (e.g., "00101" format)
      const code = props.ma;
      const name = props.ten;
      const level = 'COMMUNE';
      const areaKm2 = props.area_km2 || null;
      const population = props.population || null;
      const density = props.density || null;
      const capital = props.capital || null;
      const address = props.address || null;
      const phone = props.phone || null;
      const decree = props.decree || null;
      const decreeUrl = props.decree_url || null;
      const macroRegion = props.macro_region || null;
      const nPredecessors = props.n_predecessors || null;
      
      values.push(`($${paramIndex}, $${paramIndex+1}, $${paramIndex+2}, $${paramIndex+3}, ST_GeomFromGeoJSON($${paramIndex+4}), $${paramIndex+5}, $${paramIndex+6}, $${paramIndex+7}, $${paramIndex+8}, $${paramIndex+9}, $${paramIndex+10}, $${paramIndex+11}, $${paramIndex+12}, $${paramIndex+13}, $${paramIndex+14}, $${paramIndex+15})`);
      params.push(
        code, name, level, provinceId,
        geom, areaKm2, population, density, capital, address, phone, decree, decreeUrl, macroRegion, nPredecessors
      );
      paramIndex += 16;
    }
    
    if (values.length > 0) {
      const sql = `
        INSERT INTO administrative_units 
        (code, name, level, parent_id, boundary, area_km2, population, density, capital, address, phone, decree, decree_url, macro_region, n_predecessors)
        VALUES ${values.join(', ')}
        ON CONFLICT DO NOTHING
      `;
      
      try {
        await client.query(sql, params);
        inserted += values.length;
        console.log(`Inserted ${inserted}/${features.length} communes...`);
      } catch (err) {
        console.log(`Error inserting batch: ${err.message}`);
        errors += values.length;
      }
    }
  }
  
  return { inserted, errors };
}

async function main() {
  console.log('Starting data import from HuggingFace...\n');
  
  // Step 1: Download communes GeoJSON
  const communesFile = await downloadFile(COMMUNE_GEOJSON_URL);
  const communesData = await loadGeoJson(communesFile);
  
  console.log(`\nCommunes data loaded: ${communesData.features.length} features`);
  
  // Sample one feature to understand structure
  if (communesData.features.length > 0) {
    console.log('\nSample commune properties:');
    console.log(JSON.stringify(communesData.features[0].properties, null, 2));
  }
  
  // Connect to database
  console.log('\nConnecting to database...');
  const client = new Client(DB_CONFIG);
  await client.connect();
  
  try {
    // Get existing provinces
    const provinceMap = await getExistingProvinces(client);
    console.log(`Found ${provinceMap.size} provinces in database`);
    
    // Show province map
    console.log('\nProvince map:');
    for (const [code, id] of provinceMap) {
      console.log(`  ${code} -> ${id}`);
    }
    
    // Clear existing communes
    await clearCommunes(client);
    
    // Insert communes
    const result = await insertCommunes(client, communesData.features, provinceMap);
    
    console.log(`\n=== Import Complete ===`);
    console.log(`Inserted: ${result.inserted}`);
    console.log(`Errors: ${result.errors}`);
    
    // Verify
    const countResult = await client.query('SELECT COUNT(*) FROM administrative_units WHERE level = $1', ['COMMUNE']);
    console.log(`Total communes in DB: ${countResult.rows[0].count}`);
    
  } finally {
    await client.end();
  }
  
  // Cleanup
  if (fs.existsSync(tempFile)) fs.unlinkSync(tempFile);
}

main().catch(err => {
  console.error('Error:', err);
  process.exit(1);
});
