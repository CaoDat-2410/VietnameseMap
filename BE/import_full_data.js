const { Client } = require('pg');
const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const os = require('os');

const DB_CONFIG = {
  host: 'localhost',
  port: 5432,
  user: 'postgres',
  password: '123456',
  database: 'vnmapdb'
};

const PROVINCE_GEOJSON_URL = 'https://huggingface.co/datasets/tmquan/sapnhap-bando-vn/resolve/main/geo/provinces.geojson';
const COMMUNE_GEOJSON_URL = 'https://huggingface.co/datasets/tmquan/sapnhap-bando-vn/resolve/main/geo/communes.geojson';

const tempDir = os.tmpdir();

function downloadWithCurl(url, outputPath) {
  console.log(`Downloading ${url}...`);
  try {
    // Use curl with proper UTF-8 handling and follow redirects
    execSync(`curl.exe -L -s -o "${outputPath}" "${url}"`, { 
      windowsHide: true,
      stdio: 'pipe'
    });
    
    // Fix encoding issues - the file might have BOM or wrong encoding
    let content = fs.readFileSync(outputPath);
    
    // Try to detect and fix encoding
    const contentStr = content.toString('utf8');
    
    // Replace NaN, Infinity with null
    const fixedContent = contentStr
      .replace(/NaN/g, 'null')
      .replace(/Infinity/g, 'null')
      .replace(/-Infinity/g, 'null');
    
    fs.writeFileSync(outputPath, fixedContent, 'utf8');
    console.log(`Download complete: ${outputPath}`);
    return outputPath;
  } catch (err) {
    console.error(`Download failed: ${err.message}`);
    throw err;
  }
}

function parseGeoJsonFile(filepath) {
  const content = fs.readFileSync(filepath, 'utf8');
  
  // Replace NaN/Infinity before parsing
  const cleaned = content
    .replace(/"NaN"/g, 'null')
    .replace(/"Infinity"/g, 'null')
    .replace(/"-Infinity"/g, 'null')
    .replace(/\bNaN\b/g, 'null')
    .replace(/\bInfinity\b/g, 'null')
    .replace(/\b-Infinity\b/g, 'null');
  
  try {
    return JSON.parse(cleaned);
  } catch (err) {
    console.error(`JSON parse error: ${err.message}`);
    console.error(`First 500 chars: ${cleaned.substring(0, 500)}`);
    throw err;
  }
}

async function insertProvinces(client, features) {
  console.log(`Inserting ${features.length} provinces...`);
  let inserted = 0;
  
  for (const feature of features) {
    const props = feature.properties;
    const geom = feature.geometry ? JSON.stringify(feature.geometry) : null;
    
    const sql = `
      INSERT INTO administrative_units 
      (code, name, level, boundary, area_km2, population, density, capital, decree, decree_url, macro_region, n_predecessors)
      VALUES ($1, $2, $3, ST_GeomFromGeoJSON($4), $5, $6, $7, $8, $9, $10, $11, $12)
      ON CONFLICT (code) DO NOTHING
      RETURNING id
    `;
    
    try {
      const result = await client.query(sql, [
        props.ma,
        props.ten,
        'PROVINCE',
        geom,
        props.area_km2 || null,
        props.population ? Math.floor(props.population) : null,
        props.density || null,
        props.capital || null,
        props.decree || null,
        props.decree_url || null,
        props.macro_region || null,
        props.n_predecessors || null
      ]);
      if (result.rows.length > 0) inserted++;
    } catch (err) {
      console.log(`Error inserting province ${props.ten}: ${err.message}`);
    }
  }
  console.log(`Inserted ${inserted} provinces`);
  return inserted;
}

async function insertCommunes(client, features, provinceMap) {
  console.log(`Inserting ${features.length} communes...`);
  
  let inserted = 0;
  let skipped = 0;
  const batchSize = 25;
  
  for (let i = 0; i < features.length; i++) {
    const feature = features[i];
    const props = feature.properties;
    const geom = feature.geometry ? JSON.stringify(feature.geometry) : null;
    
    // parent_ma is the province code
    const provinceCode = String(props.parent_ma).padStart(2, '0');
    const provinceId = provinceMap.get(provinceCode);
    
    if (!provinceId) {
      // Try without padding
      const provinceIdAlt = provinceMap.get(String(props.parent_ma));
      if (!provinceIdAlt) {
        console.log(`Warning: Province not found for code "${props.parent_ma}", skipping ${props.ten}`);
        skipped++;
        continue;
      }
    }
    
    const actualProvinceId = provinceId || provinceMap.get(String(props.parent_ma));
    
    const sql = `
      INSERT INTO administrative_units 
      (code, name, level, parent_id, boundary, area_km2, population, density, capital, address, decree, macro_region, n_predecessors)
      VALUES ($1, $2, $3, $4, ST_GeomFromGeoJSON($5), $6, $7, $8, $9, $10, $11, $12, $13)
      ON CONFLICT (code) DO NOTHING
      RETURNING id
    `;
    
    try {
      const result = await client.query(sql, [
        props.ma,
        props.ten,
        'COMMUNE',
        actualProvinceId,
        geom,
        props.area_km2 || null,
        props.population ? Math.floor(props.population) : null,
        props.density || null,
        props.capital || null,
        props.address || null,
        props.decree || null,
        props.macro_region || null,
        props.n_predecessors || null
      ]);
      if (result.rows.length > 0) inserted++;
    } catch (err) {
      console.log(`Error: ${props.ten} - ${err.message}`);
      skipped++;
    }
    
    if ((i + 1) % 500 === 0 || i + 1 === features.length) {
      console.log(`Progress: ${i + 1}/${features.length} (inserted: ${inserted}, skipped: ${skipped})`);
    }
  }
  
  return { inserted, skipped };
}

async function calculateCentroids(client) {
  console.log('Calculating centroids...');
  try {
    const result = await client.query(`
      UPDATE administrative_units 
      SET centroid = ST_Centroid(boundary)
      WHERE boundary IS NOT NULL AND centroid IS NULL
      RETURNING id
    `);
    console.log(`Calculated centroids for ${result.rowCount} units`);
  } catch (err) {
    console.log(`Centroid calculation warning: ${err.message}`);
  }
}

async function main() {
  console.log('=== Full Data Import from HuggingFace ===\n');
  
  // Download files
  const provinceFile = path.join(tempDir, 'provinces.json');
  const communeFile = path.join(tempDir, 'communes.json');
  
  console.log('Step 1: Downloading provinces...');
  downloadWithCurl(PROVINCE_GEOJSON_URL, provinceFile);
  
  console.log('\nStep 2: Downloading communes...');
  downloadWithCurl(COMMUNE_GEOJSON_URL, communeFile);
  
  // Parse files
  console.log('\nStep 3: Parsing GeoJSON files...');
  const provinceData = parseGeoJsonFile(provinceFile);
  const communeData = parseGeoJsonFile(communeFile);
  
  console.log(`Provinces: ${provinceData.features.length}`);
  console.log(`Communes: ${communeData.features.length}`);
  
  // Show samples
  console.log('\nSample province properties:');
  console.log(JSON.stringify(provinceData.features[0].properties, null, 2));
  
  console.log('\nSample commune properties:');
  console.log(JSON.stringify(communeData.features[0].properties, null, 2));
  
  // Connect to DB
  console.log('\nStep 4: Connecting to database...');
  const client = new Client(DB_CONFIG);
  await client.connect();
  
  try {
    // Truncate existing data
    console.log('\nStep 4.5: Clearing existing data...');
    await client.query('TRUNCATE TABLE administrative_units RESTART IDENTITY CASCADE');
    console.log('Cleared all existing data');
    
    // Insert provinces first
    console.log('\nStep 5: Inserting provinces...');
    await insertProvinces(client, provinceData.features);
    
    // Get province map
    const provinceResult = await client.query('SELECT id, code FROM administrative_units WHERE level = $1', ['PROVINCE']);
    const provinceMap = new Map();
    provinceResult.rows.forEach(row => {
      provinceMap.set(String(row.code).padStart(2, '0'), row.id);
      provinceMap.set(row.code, row.id);
    });
    console.log(`Province map: ${provinceMap.size} provinces`);
    
    // Show province codes in map
    console.log('Province codes:', [...provinceMap.keys()].slice(0, 10).join(', '), '...');
    
    // Insert communes
    console.log('\nStep 6: Inserting communes...');
    const result = await insertCommunes(client, communeData.features, provinceMap);
    
    // Calculate centroids
    await calculateCentroids(client);
    
    // Final stats
    console.log('\n=== Import Complete ===');
    console.log(`Provinces inserted: ${provinceResult.rows.length}`);
    console.log(`Communes inserted: ${result.inserted}`);
    console.log(`Communes skipped: ${result.skipped}`);
    
    const totalResult = await client.query('SELECT level, COUNT(*) FROM administrative_units GROUP BY level ORDER BY level');
    console.log('\nFinal counts:');
    totalResult.rows.forEach(row => {
      console.log(`  ${row.level}: ${row.count}`);
    });
    
  } finally {
    await client.end();
  }
  
  // Cleanup
  try {
    fs.unlinkSync(provinceFile);
    fs.unlinkSync(communeFile);
  } catch (e) {}
}

main().catch(err => {
  console.error('Fatal error:', err);
  process.exit(1);
});
