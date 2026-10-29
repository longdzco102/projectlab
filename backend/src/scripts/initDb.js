/**
 * scripts/initDb.js
 * Khởi tạo cơ sở dữ liệu PostgreSQL cho Xianxia Chat.
 * Tạo database nếu chưa có, sau đó chạy schema.sql.
 */
'use strict';
require('dotenv').config();
const { Client } = require('pg');
const fs   = require('fs');
const path = require('path');

async function initDb() {
  const host     = process.env.DB_HOST || process.env.PGHOST || 'localhost';
  const port     = parseInt(process.env.DB_PORT || process.env.PGPORT || '5432', 10);
  const user     = process.env.DB_USER || process.env.PGUSER || 'postgres';
  const password = String(process.env.DB_PASS ?? process.env.PGPASSWORD ?? 'postgres');
  const dbName   = process.env.DB_NAME || process.env.PGDATABASE || 'webchat';
  const ssl      = process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false;

  console.log(`🔌 Đang kết nối tới PostgreSQL (${host}:${port})...`);

  // ── Bước 1: Kết nối tới db mặc định (postgres) để kiểm tra/tạo database ──
  const adminClient = new Client({
    host,
    port,
    user,
    password,
    database: 'postgres',
    ssl,
    connectionTimeoutMillis: 10000,
  });

  try {
    await adminClient.connect();
    console.log('✅ Kết nối PostgreSQL thành công');

    const checkRes = await adminClient.query(
      'SELECT 1 FROM pg_database WHERE datname = $1',
      [dbName]
    );

    if (checkRes.rowCount === 0) {
      console.log(`🔨 Đang tạo database "${dbName}"...`);
      await adminClient.query(`CREATE DATABASE "${dbName}"`);
      console.log(`✅ Đã tạo database "${dbName}"`);
    } else {
      console.log(`ℹ️  Database "${dbName}" đã tồn tại`);
    }
  } catch (err) {
    console.warn(`⚠️  Không thể kiểm tra/tạo database tự động: ${err.message}`);
    console.warn('   (Có thể tài khoản không có quyền admin hoặc database đã tồn tại. Tiếp tục kết nối...)');
  } finally {
    await adminClient.end().catch(() => {});
  }

  // ── Bước 2: Kết nối vào database chính và chạy schema.sql ────────────────
  const appClient = new Client({
    host,
    port,
    user,
    password,
    database: dbName,
    ssl,
    connectionTimeoutMillis: 10000,
  });

  try {
    await appClient.connect();
    console.log(`✅ Đã kết nối vào database "${dbName}"`);

    const schemaPath = path.join(__dirname, '../../schema.sql');
    if (!fs.existsSync(schemaPath)) {
      console.error('❌ Không tìm thấy schema.sql tại:', schemaPath);
      process.exit(1);
    }

    const rawSql = fs.readFileSync(schemaPath, 'utf-8');
    console.log('📜 Đang thực thi schema.sql...');

    await appClient.query(rawSql);
    console.log('🎉 Khởi tạo bảng và trigger thành công 100%!');
  } catch (err) {
    console.error('❌ Lỗi khi thực thi schema:', err.message);
    process.exit(1);
  } finally {
    await appClient.end().catch(() => {});
  }

  process.exit(0);
}

initDb();
