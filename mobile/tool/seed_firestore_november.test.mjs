import test from 'node:test';
import assert from 'node:assert/strict';
import { buildDataset, validateRecord, summarize, localDay, applyDataset, runCli,
  PROJECT, STORE, BATCH } from './seed_firestore_november.mjs';

const env = { FIRESTORE_ACCESS_TOKEN: 'test-token-not-a-credential' };
const sleep = async () => {};
const root = `projects/${PROJECT}/databases/(default)/documents/stores/${STORE}`;
const nameOf = (record) => `${root}/${record.collection}/${record.id}`;
const json = (status, data) => new Response(JSON.stringify(data), { status });
const missing = () => json(404, { error: { status: 'NOT_FOUND' } });
const conflict = () => json(409, { error: { status: 'ALREADY_EXISTS' } });

function firestore({ race = false, ambiguous = false } = {}) {
  const docs = new Map();
  const calls = [];
  let commits = 0;
  let inject = true;
  async function fetchImpl(url, options) {
    assert.ok(url.startsWith(`https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents`));
    assert.equal(options.headers.Authorization, `Bearer ${env.FIRESTORE_ACCESS_TOKEN}`);
    assert.equal(options.redirect, 'error');
    assert.ok(options.signal instanceof AbortSignal);
    calls.push({ url, method: options.method });
    if (options.method === 'GET') {
      const name = url.slice('https://firestore.googleapis.com/v1/'.length);
      return docs.has(name) ? json(200, docs.get(name)) : missing();
    }
    commits++;
    assert.ok(url.endsWith('/documents:commit'));
    const body = JSON.parse(options.body);
    assert.equal(body.writes.length, 1);
    const write = body.writes[0];
    assert.deepEqual(Object.keys(write).sort(), ['currentDocument', 'update']);
    assert.deepEqual(write.currentDocument, { exists: false });
    if (docs.has(write.update.name)) return conflict();
    docs.set(write.update.name, structuredClone(write.update));
    if (inject && (race || ambiguous)) {
      inject = false;
      if (ambiguous) throw new Error(`sensitive ${env.FIRESTORE_ACCESS_TOKEN}`);
      return conflict();
    }
    return json(200, { writeResults: [{ updateTime: '2026-11-16T00:00:00Z' }] });
  }
  return { docs, calls, fetchImpl, get commits() { return commits; } };
}

test('dataset deterministik: 24 produk, 66 nota, 15 hari WIB, 3–6 nota/hari', () => {
  const records = buildDataset();
  assert.deepEqual(records, buildDataset());
  const summary = summarize(records);
  assert.equal(summary.products, 24);
  assert.equal(summary.receipts, 66);
  assert.equal(records.length, 90);
  assert.equal(new Set(records.map((record) => record.id)).size, 90);
  assert.deepEqual(Object.keys(summary.perDay), Array.from({ length: 15 }, (_, i) => `2026-11-${String(6 + i).padStart(2, '0')}`));
  for (const day of Object.values(summary.perDay)) assert.ok(day.receipts >= 3 && day.receipts <= 6);
  for (const record of records) {
    assert.equal(record.data.seedBatchId, BATCH);
    assert.equal(record.data.origin, 'synthetic');
    validateRecord(record);
    if (record.collection !== 'transactions') continue;
    assert.equal(localDay(record.data.createdAt), record.data.seedLocalDate);
    assert.equal(record.data.createdAt, Date.parse(new Date(record.data.createdAt + 7 * 3600000)
      .toISOString().replace('Z', '+07:00')));
    assert.match(record.id, new RegExp(`^TRX-${record.data.seedLocalDate.replaceAll('-', '')}-`));
  }
  assert.equal(localDay(Date.parse('2026-11-06T00:00:00+07:00')), '2026-11-06');
  assert.equal(localDay(Date.parse('2026-11-20T23:59:59+07:00')), '2026-11-20');
});

test('barcode RG unik, saldo stok akhir, harga modal dan snapshot nota konsisten', () => {
  const records = buildDataset();
  const products = records.filter((record) => record.collection === 'products');
  const sales = records.filter((record) => record.collection === 'transactions');
  assert.equal(new Set(products.map(({ data }) => data.barcode)).size, 24);
  assert.ok(products.some(({ data }) => data.stock === 0));
  assert.ok(products.some(({ data }) => data.stock > 0 && data.stock <= data.lowStockThreshold));
  assert.ok(products.some(({ data }) => data.stock > data.lowStockThreshold));
  for (const product of products) {
    const { data } = product;
    assert.match(data.barcode, /^RG\d+$/);
    assert.ok(data.costPrice > 0 && data.costPrice <= data.salePrice);
    assert.ok(!/sintetis|synthetic|demo|contoh/i.test(data.name));
    const units = sales.flatMap(({ data }) => data.items)
      .filter((item) => item.productId === product.id)
      .reduce((sum, item) => sum + item.quantity, 0);
    assert.ok(units > 0);
    assert.equal(data.seedUnitsSold, units);
    assert.equal(data.seedOpeningStock - units, data.stock);
  }
  for (const { data } of sales) {
    const cost = data.items.reduce((sum, item) => {
      const product = products.find((product) => product.id === item.productId);
      assert.equal(item.productName, product.data.name);
      assert.equal(item.unitPrice, product.data.salePrice);
      return sum + item.quantity * product.data.costPrice;
    }, 0);
    assert.ok(data.totalAmount >= cost);
    assert.ok(!/sintetis|synthetic|demo|contoh/i.test(data.summaryTitle));
  }
});

test('validasi menolak nominal, jumlah, timestamp dan QRIS tidak sah', () => {
  const records = buildDataset();
  const sale = records.find((record) => record.collection === 'transactions');
  for (const patch of [
    { totalAmount: sale.data.totalAmount + 1 }, { discountAmount: -1 }, { itemCount: 999 },
    { cashReceived: 0 }, { changeAmount: -1 }, { paymentMethod: 'qris' },
    { createdAt: NaN }, { createdAt: 8640000000000001 }, { items: [] },
    { items: [sale.data.items[0], sale.data.items[0]] },
    { items: [{ ...sale.data.items[0], subtotal: 1 }] },
  ]) assert.throws(() => validateRecord({ ...sale, data: { ...sale.data, ...patch } }));
  const product = records[0];
  for (const patch of [{ stock: -1 }, { costPrice: 999999 }, { salePrice: 0 },
    { updatedAt: '2026-11-24' }, { deletedAt: 1 }, { schemaVersion: 2 }]) {
    assert.throws(() => validateRecord({ ...product, data: { ...product.data, ...patch } }));
  }
});

test('default/check-only/dry-run tanpa token, jaringan atau penulisan', async () => {
  for (const args of [[], ['--check-only'], ['--dry-run']]) {
    const lines = [];
    await runCli(args, { env: {}, log: (line) => lines.push(line),
      fetchImpl: () => assert.fail('Tidak boleh mengakses jaringan') });
    assert.equal(lines.length, 1);
    const report = JSON.parse(lines[0]);
    assert.equal(report.mode, 'dry-run');
    assert.equal(report.project, PROJECT);
    assert.equal(report.store, `stores/${STORE}`);
    assert.equal(report.planned.receipts, 66);
    assert.equal(report.planned.products, 24);
  }
});

test('target terkunci dan opsi bertentangan ditolak sebelum jaringan', async () => {
  for (const args of [['--project=other'], ['--store=other'], ['--apply', '--dry-run'],
    ['--apply', '--apply'], ['--unknown']]) {
    await assert.rejects(runCli(args, { env, fetchImpl: () => assert.fail(), log: () => assert.fail() }));
  }
});

test('create-only, read-back seluruh dokumen, apply kedua tanpa overwrite', async () => {
  const server = firestore();
  const first = await applyDataset({ env, fetchImpl: server.fetchImpl, sleep });
  assert.equal(first.created, 90);
  assert.equal(first.skipped, 0);
  assert.equal(first.verified, 90);
  assert.deepEqual(first.observed, summarize(buildDataset()));
  assert.equal(server.commits, 90);
  const productName = nameOf(buildDataset()[0]);
  server.docs.get(productName).fields.stock = { integerValue: '999' };
  const snapshot = structuredClone(server.docs);
  const second = await applyDataset({ env, fetchImpl: server.fetchImpl, sleep });
  assert.equal(second.created, 0);
  assert.equal(second.skipped, 90);
  assert.equal(second.skippedDifferent, 1);
  assert.equal(second.verified, 90);
  assert.equal(server.commits, 90);
  assert.deepEqual(server.docs, snapshot);
});

test('race ALREADY_EXISTS dan timeout sesudah commit tetap aman diulang', async () => {
  for (const options of [{ race: true }, { ambiguous: true }]) {
    const server = firestore(options);
    const result = await applyDataset({ env, fetchImpl: server.fetchImpl, sleep });
    assert.equal(result.created, 89);
    assert.equal(result.skipped, 1);
    assert.equal(result.verified, 90);
    assert.equal(server.docs.size, 90);
  }
});

test('token hilang/invalid ditolak; alias OAuth diterima', async () => {
  for (const invalid of [{}, { FIRESTORE_ACCESS_TOKEN: 'bad\ntoken' }]) {
    await assert.rejects(applyDataset({ env: invalid, fetchImpl: () => assert.fail() }));
  }
  const server = firestore();
  const result = await applyDataset({ env: { GOOGLE_OAUTH_ACCESS_TOKEN: env.FIRESTORE_ACCESS_TOKEN },
    fetchImpl: server.fetchImpl, sleep });
  assert.equal(result.verified, 90);
});

test('HTTP 401/403 langsung gagal, tanpa retry atau rahasia dalam log/error', async () => {
  for (const status of [401, 403]) {
    const lines = [];
    let calls = 0;
    await assert.rejects(runCli(['--apply'], { env, sleep, log: (line) => lines.push(line),
      fetchImpl: async () => {
        calls++;
        return json(status, { error: { message: env.FIRESTORE_ACCESS_TOKEN } });
      } }), (error) => {
      assert.match(error.message, new RegExp(`HTTP ${status}`));
      assert.ok(!error.message.includes(env.FIRESTORE_ACCESS_TOKEN));
      return true;
    });
    assert.equal(calls, 1);
    assert.ok(!lines.join('').includes(env.FIRESTORE_ACCESS_TOKEN));
    assert.ok(!lines.join('').includes('read-back-verified'));
  }
});

test('retry transient/network dibatasi 3; pesan eksternal tidak bocor', async () => {
  for (const failure of [() => json(503, { secret: env.FIRESTORE_ACCESS_TOKEN }),
    () => { throw new Error(env.FIRESTORE_ACCESS_TOKEN); }]) {
    let calls = 0;
    await assert.rejects(applyDataset({ env, sleep, fetchImpl: async () => { calls++; return failure(); } }),
      (error) => {
        assert.ok(!error.message.includes(env.FIRESTORE_ACCESS_TOKEN));
        assert.match(error.message, /3 percobaan/);
        return true;
      });
    assert.equal(calls, 3);
  }
  const server = firestore();
  let calls = 0;
  const result = await applyDataset({ env, sleep, fetchImpl: async (...args) => {
    if (calls++ < 2) return json(429, {});
    return server.fetchImpl(...args);
  } });
  assert.equal(result.verified, 90);
});

test('read-back hilang/rusak/berbeda tidak pernah sukses terverifikasi', async () => {
  for (const kind of ['missing', 'invalid', 'different']) {
    const server = firestore();
    const firstName = nameOf(buildDataset()[0]);
    await assert.rejects(applyDataset({ env, sleep, fetchImpl: async (url, options) => {
      if (server.commits === 90 && options.method === 'GET' && url.endsWith(firstName)) {
        if (kind === 'missing') return missing();
        const doc = structuredClone(server.docs.get(firstName));
        doc.fields.stock = { integerValue: kind === 'invalid' ? '-1' : '1000' };
        return json(200, doc);
      }
      return server.fetchImpl(url, options);
    } }));
  }
});

test('dokumen lama tidak valid atau konflik tanpa GET sah menggagalkan verifikasi', async () => {
  const server = firestore();
  await applyDataset({ env, fetchImpl: server.fetchImpl, sleep });
  server.docs.get(nameOf(buildDataset()[0])).fields.salePrice = { integerValue: '0' };
  const snapshot = structuredClone(server.docs);
  await assert.rejects(applyDataset({ env, fetchImpl: server.fetchImpl, sleep }));
  assert.deepEqual(server.docs, snapshot);
  await assert.rejects(applyDataset({ env, sleep, fetchImpl: async (_url, options) =>
    options.method === 'POST' ? conflict() : missing() }));
});
