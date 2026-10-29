/**
 * config/db.js – PostgreSQL connection pool (pg)
 *
 * Tương thích với interface của mysql2/promise ([rows], [r.insertId])
 * để tất cả models có thể chạy mượt mà trên PostgreSQL (AWS RDS / Local).
 */
'use strict';
require('dotenv').config();
const { Pool } = require('pg');

const NO_ID_TABLES = new Set([
  'message_reactions',
  'post_likes',
  'user_friends',
  'user_blocks'
]);

function buildSsl() {
  if (process.env.DB_SSL === 'true' || process.env.PGSSLMODE === 'require') {
    return { rejectUnauthorized: false };
  }
  return false;
}

const host     = process.env.DB_HOST || process.env.PGHOST || process.env.TIDB_HOST || 'localhost';
const port     = parseInt(process.env.DB_PORT || process.env.PGPORT || process.env.TIDB_PORT || '5432', 10);
const user     = process.env.DB_USER || process.env.PGUSER || process.env.TIDB_USER || 'postgres';
const password = String(process.env.DB_PASS ?? process.env.PGPASSWORD ?? process.env.TIDB_PASS ?? 'postgres');
const database = process.env.DB_NAME || process.env.PGDATABASE || process.env.TIDB_NAME || 'webchat';

const pool = new Pool({
  host,
  port,
  user,
  password,
  database,
  ssl: buildSsl(),
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 10000,
});

/**
 * Chuyển đổi cú pháp MySQL sang PostgreSQL tự động:
 * 1. Chuyển placeholder ? thành $1, $2, ...
 * 2. Hỗ trợ INSERT IGNORE -> ON CONFLICT DO NOTHING
 * 3. Hỗ trợ JSON_ARRAYAGG -> JSON_AGG, JSON_OBJECT -> JSON_BUILD_OBJECT
 * 4. Tự động thêm RETURNING id cho INSERT để lấy r.insertId
 */
function prepareSql(sql) {
  let modified = sql.trim();

  // 1. Chuyển INSERT IGNORE
  if (/^\s*INSERT\s+IGNORE\s+INTO\b/i.test(modified)) {
    modified = modified.replace(/^\s*INSERT\s+IGNORE\s+INTO\b/i, 'INSERT INTO');
    if (!/\bON\s+CONFLICT\b/i.test(modified)) {
      modified += ' ON CONFLICT DO NOTHING';
    }
  }

  // 2. Chuyển MySQL JSON functions sang Postgres
  modified = modified
    .replace(/\bJSON_ARRAYAGG\b/gi, 'JSON_AGG')
    .replace(/\bJSON_OBJECT\b/gi, 'JSON_BUILD_OBJECT');

  // 3. Tự động thêm RETURNING id cho INSERT
  const isInsert = /^\s*INSERT\s+INTO\b/i.test(modified);
  const hasReturning = /\bRETURNING\b/i.test(modified);
  let appendedReturning = false;

  if (isInsert && !hasReturning) {
    const tableMatch = modified.match(/^\s*INSERT\s+INTO\s+([a-zA-Z0-9_]+)/i);
    const tableName = tableMatch ? tableMatch[1].toLowerCase() : '';
    if (!NO_ID_TABLES.has(tableName)) {
      modified += ' RETURNING id';
      appendedReturning = true;
    }
  }

  // 4. Chuyển ? thành $1, $2...
  let paramIndex = 0;
  const pgSql = modified.replace(/\?/g, () => `$${++paramIndex}`);

  return { pgSql, isInsert, appendedReturning };
}

/**
 * Thực thi query và map kết quả tương tự mysql2:
 * SELECT -> [rows, fields]
 * INSERT -> [{ insertId, affectedRows }, fields]
 * UPDATE/DELETE -> [{ affectedRows }, fields]
 */
async function executeQuery(executor, sql, params = []) {
  const { pgSql, isInsert, appendedReturning } = prepareSql(sql);
  const cleanParams = Array.isArray(params) ? params : [];

  const res = await executor.query(pgSql, cleanParams);

  if (isInsert) {
    const insertId = appendedReturning && res.rows[0]?.id ? res.rows[0].id : null;
    const resultObj = {
      insertId,
      affectedRows: res.rowCount,
      ...(res.rows[0] || {})
    };
    return [resultObj, res.fields];
  }

  if (/^\s*(UPDATE|DELETE)\b/i.test(sql)) {
    return [{ affectedRows: res.rowCount }, res.fields];
  }

  return [res.rows, res.fields];
}

// ── Wrapper API ──────────────────────────────────────────────
const db = {
  async execute(sql, params = []) {
    return executeQuery(pool, sql, params);
  },

  async query(sql, params = []) {
    return executeQuery(pool, sql, params);
  },

  async getConnection() {
    const client = await pool.connect();
    return {
      async beginTransaction() {
        await client.query('BEGIN');
      },
      async execute(sql, params = []) {
        return executeQuery(client, sql, params);
      },
      async query(sql, params = []) {
        return executeQuery(client, sql, params);
      },
      async commit() {
        await client.query('COMMIT');
      },
      async rollback() {
        await client.query('ROLLBACK');
      },
      release() {
        client.release();
      }
    };
  },

  rawPool: pool
};

// ── Health check on startup ──────────────────────────────────
pool.query('SELECT NOW()')
  .then(() => {
    console.log(`✅ PostgreSQL connected  host=${host}:${port}  db=${database}`);
  })
  .catch(err => {
    console.error('❌ PostgreSQL connection failed:', err.message);
    console.error(`   Host: ${host}:${port} | Database: ${database} | User: ${user}`);
    console.error('   → Kiểm tra biến môi trường DB_HOST/DB_USER/DB_PASS/DB_NAME');
  });

module.exports = db;
