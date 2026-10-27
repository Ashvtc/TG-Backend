// Aplica db/schema.sql a la base configurada en .env (DB_HOST, DB_PORT, DB_NAME, DB_USERNAME, DB_PASS).
// Uso: yarn db:schema
// Es idempotente: solo crea las tablas que no existen.
require('dotenv').config();
const fs = require('fs');
const path = require('path');
const { Client } = require('pg');

async function main() {
  const client = new Client({
    host: process.env.DB_HOST,
    port: +process.env.DB_PORT,
    database: process.env.DB_NAME,
    user: process.env.DB_USERNAME,
    password: process.env.DB_PASS,
  });

  console.log(`Aplicando esquema en ${process.env.DB_HOST}:${process.env.DB_PORT}/${process.env.DB_NAME}`);
  await client.connect();
  try {
    const sql = fs.readFileSync(path.join(__dirname, '..', 'db', 'schema.sql'), 'utf8');
    await client.query(sql);

    const { rows } = await client.query(
      `SELECT table_name FROM information_schema.tables WHERE table_schema = current_schema() ORDER BY table_name`,
    );
    console.log('Tablas en la base:', rows.map((r) => r.table_name).join(', '));
  } finally {
    await client.end();
  }
}

main().catch((error) => {
  console.error('Error aplicando el esquema:', error.message);
  process.exit(1);
});
