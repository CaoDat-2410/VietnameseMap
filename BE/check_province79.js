const { Client } = require('pg');
const c = new Client({
  host: 'localhost',
  port: 5432,
  database: 'vnmapdb',
  user: 'postgres',
  password: '123456'
});

c.connect()
  .then(() => c.query("SELECT id, code, name FROM administrative_units WHERE level = 'PROVINCE' AND code = '79'"))
  .then(r => {
    console.log('Province 79 (pgpool):');
    console.log(r.rows);
    return c.end();
  })
  .catch(e => {
    console.error(e);
    c.end();
  });
