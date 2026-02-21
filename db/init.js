// Run with: node db/init.js
// Initialises (or re-initialises) the database from schema.sql

const fs   = require('fs');
const path = require('path');
const pool = require('./pool');

async function init() {
  const sql = fs.readFileSync(path.join(__dirname, 'schema.sql'), 'utf8');
  const client = await pool.connect();
  try {
    console.log('Running schema.sql …');
    await client.query(sql);
    console.log('✓ Database initialised successfully.');
  } catch (err) {
    console.error('✗ Init failed:', err.message);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

init();
