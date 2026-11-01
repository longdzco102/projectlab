const test = require('node:test');
const assert = require('node:assert/strict');
const http = require('node:http');
const { app, server } = require('../src/app');

test('GET /health trả về HTTP 200 và status ok', async (t) => {
    t.after(() => {
        server.close();
    });

    const res = await fetch('http://localhost:3000/health');
    const data = await res.json();

    assert.equal(res.status, 200);
    assert.equal(data.status, 'ok');
});