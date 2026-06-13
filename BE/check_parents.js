const { Client } = require('pg');
const c = new Client({
  host: 'localhost',
  port: 5432,
  database: 'vnmapdb',
  user: 'postgres',
  password: '123456'
});

c.connect()
  .then(() => c.query("SELECT code, name, parent_id FROM administrative_units WHERE level = 'COMMUNE' AND parent_id IS NOT NULL ORDER BY parent_id LIMIT 10"))
  .then(r => {
    console.log('Communes with parent_id (pgpool - has data):');
    r.rows.forEach(x => console.log(x));
    return c.end();
  })
  .catch(e => {
    console.error(e);
    c.end();
  });
