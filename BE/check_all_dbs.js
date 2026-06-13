const { Client } = require('pg');

async function checkAllDBs() {
  const ports = [
    { name: 'pgpool (5432)', port: 5432 },
    { name: 'postgres_master (5433)', port: 5433 },
    { name: 'postgres_replica (5434)', port: 5434 },
  ];
  
  for (const db of ports) {
    const c = new Client({
      host: 'localhost',
      port: db.port,
      database: 'vnmapdb',
      user: 'postgres',
      password: '123456'
    });
    
    try {
      await c.connect();
      const r = await c.query("SELECT COUNT(*) as total, COUNT(*) FILTER (WHERE level = 'COMMUNE') as communes FROM administrative_units");
      console.log(`${db.name}: ${r.rows[0].total} total, ${r.rows[0].communes} communes`);
      await c.end();
    } catch (e) {
      console.log(`${db.name}: ERROR - ${e.message}`);
    }
  }
}

checkAllDBs();
