// Copia los datos de una base origen a la base configurada en .env (destino),
// conservando los ids. Todo corre en una transacción en el destino: si algo falla, no se copia nada.
// Las filas cuyo id ya existe en el destino se omiten, así que se puede correr más de una vez.
//
// Uso:
//   SOURCE_DB_HOST=localhost SOURCE_DB_PORT=5432 SOURCE_DB_NAME=qroom \
//   SOURCE_DB_USERNAME=postgres SOURCE_DB_PASS=... yarn db:copy
require('dotenv').config();
const { Client } = require('pg');

// Orden de inserción según las llaves foráneas.
const TABLES = ['rol', 'area', 'room', 'user', 'cleaning_type', 'cleaning_check', 'permissions', 'cleaning_action'];

// cleaning_check es un árbol: los padres van antes que los hijos (menos segmentos en mpath primero).
const ORDER_BY = {
  cleaning_check: `length("mpath") - length(replace("mpath", '.', ''))`,
};

async function main() {
  const source = new Client({
    host: process.env.SOURCE_DB_HOST,
    port: +process.env.SOURCE_DB_PORT,
    database: process.env.SOURCE_DB_NAME,
    user: process.env.SOURCE_DB_USERNAME,
    password: process.env.SOURCE_DB_PASS,
  });
  const target = new Client({
    host: process.env.DB_HOST,
    port: +process.env.DB_PORT,
    database: process.env.DB_NAME,
    user: process.env.DB_USERNAME,
    password: process.env.DB_PASS,
  });

  console.log(`Origen:  ${process.env.SOURCE_DB_HOST}:${process.env.SOURCE_DB_PORT}/${process.env.SOURCE_DB_NAME}`);
  console.log(`Destino: ${process.env.DB_HOST}:${process.env.DB_PORT}/${process.env.DB_NAME}`);
  await source.connect();
  await target.connect();

  try {
    await target.query('BEGIN');
    for (const table of TABLES) {
      const orderBy = ORDER_BY[table] ? ` ORDER BY ${ORDER_BY[table]}` : '';
      const { rows, fields } = await source.query(`SELECT * FROM "${table}"${orderBy}`);
      const columns = fields.map((f) => `"${f.name}"`).join(', ');
      const placeholders = fields.map((_, i) => `$${i + 1}`).join(', ');
      const insert = `INSERT INTO "${table}" (${columns}) VALUES (${placeholders}) ON CONFLICT ("id") DO NOTHING`;

      let inserted = 0;
      for (const row of rows) {
        const result = await target.query(insert, fields.map((f) => row[f.name]));
        inserted += result.rowCount;
      }
      console.log(`${table.padEnd(16)} ${inserted}/${rows.length} insertadas`);
    }
    await target.query('COMMIT');
    console.log('Copia completada.');
  } catch (error) {
    await target.query('ROLLBACK');
    throw error;
  } finally {
    await source.end();
    await target.end();
  }
}

main().catch((error) => {
  console.error('Error copiando datos (no se copió nada):', error.message);
  process.exit(1);
});
