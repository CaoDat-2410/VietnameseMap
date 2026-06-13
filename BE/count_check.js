const { Client } = require('pg');
const c = new Client({
  host: 'localhost',
  port: 5432,
  database: 'vnmapdb',
  user: 'postgres',
  password: '123456'
});

c.connect()
  .then(() => c.query("SELECT COUNT(*) as total, COUNT(*) FILTER (WHERE level = 'COMMUNE') as communes, COUNT(*) FILTER (WHERE level = 'PROVINCE') as provinces FROM administrative_units"))
  .then(r => {
    console.log('Result:', r.rows[0]);
    return c.end();
  })
  .catch(e => {
    console.error(e);
    c.end();
  });
