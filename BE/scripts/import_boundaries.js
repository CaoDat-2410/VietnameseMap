#!/usr/bin/env node
/**
 * Import administrative boundaries from GeoJSON into PostgreSQL
 * 
 * Usage:
 *   node import_boundaries.js <geojson_path> [--communes-only] [--dry-run]
 */

// Load .env file if exists
try {
    const envPath = path.join(__dirname, '..', '.env');
    if (fs.existsSync(envPath)) {
        const envContent = fs.readFileSync(envPath, 'utf8');
        for (const line of envContent.split('\n')) {
            const match = line.match(/^([^=]+)=(.*)$/);
            if (match) process.env[match[1].trim()] = match[2].trim();
        }
    }
} catch (e) { /* ignore */ }

const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

// Type-to-level mapping
const TYPE_TO_LEVEL = {
    "Tỉnh": "PROVINCE",
    "Thành phố": "PROVINCE",
    "Thủ đô": "PROVINCE",
    "Xã": "COMMUNE",
    "Phường": "COMMUNE",
    "Thị trấn": "COMMUNE",
};

// DB config - use env vars with fallback to docker-compose defaults
const DB_CONFIG = {
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '5432'),
    database: process.env.DB_NAME || 'vnmapdb',
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD || '123456',
};

function parseArgs() {
    const args = process.argv.slice(2);
    const geojsonPath = args[0];
    const communesOnly = args.includes('--communes-only');
    const dryRun = args.includes('--dry-run');
    
    return { geojsonPath, communesOnly, dryRun };
}

function deriveLevel(props) {
    const level = TYPE_TO_LEVEL[props.type];
    if (level) return level;
    return props.parent_ma === null || props.parent_ma === undefined ? 'PROVINCE' : 'COMMUNE';
}

function cleanGeoJSON(content) {
    // Word-boundary regex prevents matching "NaN" inside strings
    return content
        .replace(/\bNaN\b/g, 'null')
        .replace(/\bInfinity\b/g, 'null')
        .replace(/\b-Infinity\b/g, 'null');
}

async function importBoundaries(geojsonPath, communesOnly = false, dryRun = false) {
    console.log(`Reading GeoJSON from: ${geojsonPath}`);
    
    const content = cleanGeoJSON(fs.readFileSync(geojsonPath, 'utf8'));
    const data = JSON.parse(content);
    const features = data.features;
    
    console.log(`Total features: ${features.length}`);
    
    // Build records
    const records = [];
    for (const feature of features) {
        const props = feature.properties;
        const geom = feature.geometry;
        
        if (!props.ma || !geom) {
            console.warn(`Skipping invalid record: ${JSON.stringify(props).substring(0, 100)}`);
            continue;
        }
        
        records.push({
            code: String(props.ma),
            name: props.ten || '',
            level: deriveLevel(props),
            parentCode: props.parent_ma === null || props.parent_ma === undefined ? null : String(props.parent_ma),
            geojson: JSON.stringify(geom),
        });
    }
    
    console.log(`Valid records: ${records.length}`);
    
    // Filter by level if communes-only
    let filteredRecords = records;
    if (communesOnly) {
        filteredRecords = records.filter(r => r.level === 'COMMUNE');
        console.log(`Filtered to communes only: ${filteredRecords.length}`);
    } else {
        console.log(`Provinces: ${records.filter(r => r.level === 'PROVINCE').length}`);
        console.log(`Communes: ${records.filter(r => r.level === 'COMMUNE').length}`);
    }
    
    if (dryRun) {
        console.log('\n=== DRY RUN - No changes will be made ===');
        console.log(`Would process ${filteredRecords.length} records`);
        
        const provinces = filteredRecords.filter(r => r.level === 'PROVINCE');
        const communes = filteredRecords.filter(r => r.level === 'COMMUNE');
        console.log(`  Provinces: ${provinces.length}`);
        console.log(`  Communes: ${communes.length}`);
        
        if (provinces.length > 0) {
            console.log('\nFirst 5 provinces:');
            provinces.slice(0, 5).forEach(p => {
                console.log(`  ${p.code}: ${p.name}`);
            });
        }
        
        if (communes.length > 0) {
            console.log('\nFirst 5 communes:');
            communes.slice(0, 5).forEach(c => {
                console.log(`  ${c.code}: ${c.name} (parent: ${c.parentCode})`);
            });
        }
        
        return;
    }
    
    // Connect to database
    console.log('\nConnecting to database...');
    const client = new Client(DB_CONFIG);
    
    try {
        await client.connect();
        console.log('Connected successfully');
        
        // Get existing provinces to build code->id mapping
        const existingProvinces = await client.query(
            "SELECT code, id FROM administrative_units WHERE level = 'PROVINCE'"
        );
        const codeToId = new Map(existingProvinces.rows.map(r => [r.code, r.id]));
        console.log(`Existing provinces in DB: ${codeToId.size}`);
        
        // Separate provinces and communes
        const provinces = filteredRecords.filter(r => r.level === 'PROVINCE');
        const communes = filteredRecords.filter(r => r.level === 'COMMUNE');
        
        // Check for orphaned communes before import
        const orphanedCommunes = communes.filter(c => c.parentCode && !codeToId.has(c.parentCode));
        if (orphanedCommunes.length > 0) {
            console.warn(`WARNING: ${orphanedCommunes.length} communes have no parent province in DB`);
            orphanedCommunes.slice(0, 5).forEach(c => {
                console.warn(`  - ${c.code} ${c.name} (parent: ${c.parentCode})`);
            });
        }
        
        // Begin transaction
        await client.query('BEGIN');
        
        // Insert provinces first (if not communes-only)
        let inserted = 0;
        let updated = 0;
        
        if (provinces.length > 0) {
            console.log(`Inserting ${provinces.length} provinces...`);
            
            const provinceSql = `
                INSERT INTO administrative_units (code, name, level, boundary)
                VALUES ($1, $2, $3, ST_SetSRID(ST_MakeValid(ST_Multi(ST_GeomFromGeoJSON($4))), 4326))
                ON CONFLICT (code) DO UPDATE SET
                    name = EXCLUDED.name,
                    level = EXCLUDED.level,
                    boundary = EXCLUDED.boundary
                RETURNING id, code
            `;
            
            for (const rec of provinces) {
                const result = await client.query(provinceSql, [rec.code, rec.name, rec.level, rec.geojson]);
                if (result.rowCount === 1) inserted++;
                if (result.rowCount === 2) { inserted++; updated++; }
                
                if (result.rows[0].id) {
                    codeToId.set(result.rows[0].code, result.rows[0].id);
                }
            }
        }
        
        // Insert communes with explicit parent lookup
        let successCount = 0;
        let errorCount = 0;
        const errors = [];
        const skipped = [];
        
        if (communes.length > 0) {
            console.log(`Inserting ${communes.length} communes...`);
            
            const communeSql = `
                INSERT INTO administrative_units (code, name, level, parent_id, boundary)
                VALUES ($1, $2, 'COMMUNE', $3, ST_SetSRID(ST_Multi(ST_CollectionExtract(ST_MakeValid(ST_GeomFromGeoJSON($4)), 3)), 4326)::geometry(MultiPolygon, 4326))
                ON CONFLICT (code) DO UPDATE SET
                    name = EXCLUDED.name,
                    level = EXCLUDED.level,
                    parent_id = EXCLUDED.parent_id,
                    boundary = EXCLUDED.boundary
                RETURNING id, code
            `;
            
            let firstResult = null;
            
            for (const rec of communes) {
                // Explicit parent lookup - misses go to skipped_communes.log
                const parentId = rec.parentCode ? codeToId.get(rec.parentCode) : null;
                
                if (parentId === undefined || parentId === null) {
                    skipped.push({
                        code: rec.code,
                        name: rec.name,
                        parent_ma: rec.parentCode
                    });
                    continue;
                }
                
                try {
                    const result = await client.query(communeSql, [rec.code, rec.name, parentId, rec.geojson]);
                    if (!firstResult && result.rows.length > 0) {
                        firstResult = result.rows[0];
                    }
                    successCount++;
                    if (successCount % 500 === 0) {
                        console.log(`  Progress: ${successCount}/${communes.length}`);
                    }
                } catch (err) {
                    errorCount++;
                    if (errors.length < 10) {
                        errors.push({ code: rec.code, name: rec.name, error: err.message });
                    }
                    if (errorCount === 1) {
                        console.error(`  First error at ${rec.code}: ${err.message}`);
                    }
                }
            }
            
            console.log(`  Success: ${successCount}, Errors: ${errorCount}`);
            if (firstResult) {
                console.log(`  First inserted record: ${JSON.stringify(firstResult)}`);
            }
            if (errors.length > 0) {
                fs.writeFileSync('commune_errors.log', JSON.stringify(errors, null, 2));
                console.warn(`  Errors logged to commune_errors.log`);
            }
        }
        
        const totalProcessed = skipped.length + successCount + errorCount;
        await client.query('COMMIT');
        
        // Verify after commit
        const verifyResult = await client.query('SELECT COUNT(*) FROM administrative_units WHERE level = $1', ['COMMUNE']);
        console.log(`  DB verification - COMMUNE count: ${verifyResult.rows[0].count}`);
        
        console.log(`\nImport complete: ${totalProcessed} records processed, ${successCount} inserted, ${errorCount} errors, ${skipped.length} skipped`);
        
        // Write skipped communes to log file (durable)
        if (skipped.length > 0) {
            const logPath = path.join(process.cwd(), 'skipped_communes.log');
            fs.writeFileSync(logPath, JSON.stringify(skipped, null, 2), 'utf8');
            console.warn(`\n${skipped.length} communes skipped - see skipped_communes.log`);
        }
        
    } catch (error) {
        await client.query('ROLLBACK');
        console.error('Import failed:', error.message);
        // Only throw if there are real errors
        if (errorCount === 0) {
            console.log('Transaction rolled back despite success - database may have an issue');
        }
    } finally {
        await client.end();
    }
}

// Main
const { geojsonPath, communesOnly, dryRun } = parseArgs();

if (!geojsonPath) {
    console.error('Usage: node import_boundaries.js <geojson_path> [--communes-only] [--dry-run]');
    console.error('  --communes-only: Only import COMMUNE level records');
    console.error('  --dry-run: Preview without making changes');
    process.exit(1);
}

if (!fs.existsSync(geojsonPath)) {
    console.error(`File not found: ${geojsonPath}`);
    process.exit(1);
}

importBoundaries(geojsonPath, communesOnly, dryRun)
    .then(() => {
        console.log('\nDone.');
        process.exit(0);
    })
    .catch(err => {
        console.error('\nFailed:', err);
        process.exit(1);
    });
