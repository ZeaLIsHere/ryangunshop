import { isDeepStrictEqual } from 'node:util';
import { setTimeout as delay } from 'node:timers/promises';
import { pathToFileURL } from 'node:url';

export const PROJECT = 'iyangunshop';
export const STORE = 'toko-utama';
export const BATCH = 'RG-20261106-20261120-v1';
const ROOT = `projects/${PROJECT}/databases/(default)/documents`;
const API = `https://firestore.googleapis.com/v1/${ROOT}`;
const WIB = 7 * 60 * 60 * 1000;
const metadata = { seedBatchId: BATCH, origin: 'synthetic' };

class SeedError extends Error {}
const requireValid = (condition) => {
  if (!condition) throw new SeedError('Validasi dokumen gagal; tidak boleh dianggap terverifikasi.');
};
const integer = (value, minimum = 0) => Number.isSafeInteger(value) && value >= minimum;
const text = (value) => typeof value === 'string' && value.trim().length > 0;
const segment = (value) => text(value) && !value.includes('/');
const timestamp = (value) => integer(value, 1) && Number.isFinite(new Date(value).getTime());
export const localDay = (epoch) => new Date(epoch + WIB).toISOString().slice(0, 10);

export function buildDataset() {
  // Stok akhir snapshot, bukan checkout; impor tidak mengurangi stok produk mana pun.
  const catalog = [
    ['Beras Ramos 1 kg', 'Sembako', 'bungkus', 16000, 14000, 48],
    ['Minyak Goreng 1 L', 'Sembako', 'pouch', 19000, 17000, 36],
    ['Gula Pasir 1 kg', 'Sembako', 'bungkus', 18000, 16000, 18],
    ['Tepung Terigu 1 kg', 'Sembako', 'bungkus', 13000, 11000, 24],
    ['Garam Beryodium 250 g', 'Sembako', 'bungkus', 3000, 2200, 20],
    ['Kecap Manis 135 ml', 'Bumbu', 'pouch', 7500, 6000, 3],
    ['Saus Sambal 135 ml', 'Bumbu', 'botol', 6500, 5000, 16],
    ['Santan Instan 65 ml', 'Bumbu', 'kotak', 4000, 3200, 0],
    ['Mi Instan Goreng 85 g', 'Makanan', 'bungkus', 3500, 2900, 28],
    ['Mi Instan Soto 75 g', 'Makanan', 'bungkus', 3300, 2700, 5],
    ['Biskuit Kelapa 90 g', 'Makanan', 'bungkus', 7000, 5500, 22],
    ['Wafer Cokelat 100 g', 'Makanan', 'bungkus', 8500, 6800, 12],
    ['Keripik Singkong 60 g', 'Makanan', 'bungkus', 5000, 3800, 18],
    ['Kopi Hitam 7 g', 'Minuman', 'sachet', 1500, 1000, 30],
    ['Kopi Susu 20 g', 'Minuman', 'sachet', 2000, 1500, 2],
    ['Teh Celup 25 Kantong', 'Minuman', 'kotak', 8500, 7000, 40],
    ['Susu UHT Cokelat 200 ml', 'Minuman', 'kotak', 6000, 4800, 15],
    ['Air Mineral 600 ml', 'Minuman', 'botol', 3500, 2500, 0],
    ['Teh Melati 350 ml', 'Minuman', 'botol', 4500, 3500, 10],
    ['Sabun Mandi 75 g', 'Kebutuhan Rumah', 'batang', 4500, 3500, 24],
    ['Detergen Bubuk 800 g', 'Kebutuhan Rumah', 'bungkus', 18000, 15000, 1],
    ['Sabun Cuci Piring 250 ml', 'Kebutuhan Rumah', 'pouch', 6500, 5000, 8],
    ['Pasta Gigi 75 g', 'Kebutuhan Rumah', 'tube', 12000, 9500, 20],
    ['Tisu Wajah 200 Lembar', 'Kebutuhan Rumah', 'bungkus', 11000, 8500, 6],
  ];
  const products = catalog.map(([name, category, unit, salePrice, costPrice, stock], i) => ({
    collection: 'products',
    id: `RG-P-202611-${String(i + 1).padStart(3, '0')}`,
    data: {
      schemaVersion: 1, name, barcode: `RG202611${String(i + 1).padStart(6, '0')}`,
      salePrice, costPrice, stock, category, unit, fixtureId: '',
      locationLabel: category === 'Minuman' ? 'Rak minuman' : `Rak ${category.toLowerCase()}`,
      lowStockThreshold: 5, updatedAt: Date.parse('2026-11-20T21:00:00+07:00'),
      deletedAt: null, ...metadata, seedOpeningStock: stock, seedUnitsSold: 0,
    },
  }));
  const transactions = [];
  const times = ['07:15', '09:40', '11:55', '14:20', '17:10', '20:05'];
  for (let day = 6; day <= 20; day++) {
    const dayStr = String(day).padStart(2, '0');
    const date = `2026-11-${dayStr}`;
    const offset = day - 6;
    for (let receipt = 0; receipt < 3 + offset % 4; receipt++) {
      const items = [];
      for (let line = 0; line < 1 + (day + receipt) % 5; line++) {
        const product = products[(offset * 3 + receipt * 5 + line * 7) % products.length];
        const quantity = 1 + (day + receipt + line) % 3;
        items.push({ productId: product.id, productName: product.data.name, quantity,
          unitPrice: product.data.salePrice, subtotal: quantity * product.data.salePrice });
        product.data.seedUnitsSold += quantity;
        product.data.seedOpeningStock += quantity;
      }
      const subtotal = items.reduce((sum, item) => sum + item.subtotal, 0);
      const discountAmount = (day + receipt) % 5 === 0 ? 500 : 0;
      const totalAmount = subtotal - discountAmount;
      const cashReceived = receipt % 3 === 0 ? totalAmount
        : Math.ceil(totalAmount / (totalAmount <= 50000 ? 10000 : 50000))
          * (totalAmount <= 50000 ? 10000 : 50000);
      transactions.push({
        collection: 'transactions', id: `TRX-202611${dayStr}-${String(receipt + 1).padStart(3, '0')}-RG1`,
        data: {
          schemaVersion: 1, createdAt: Date.parse(`${date}T${times[receipt]}:00+07:00`),
          totalAmount, discountAmount, paymentMethod: 'cash', cashReceived,
          changeAmount: cashReceived - totalAmount,
          itemCount: items.reduce((sum, item) => sum + item.quantity, 0),
          summaryTitle: items[0].productName + (items.length > 1 ? ` +${items.length - 1} barang` : ''),
          items, ...metadata, seedLocalDate: date,
        },
      });
    }
  }
  const records = [...products, ...transactions];
  records.forEach(validateRecord);
  return records;
}

export function validateRecord({ collection, id, data }) {
  requireValid(segment(id) && data?.schemaVersion === 1);
  if (collection === 'products') {
    requireValid(text(data.name) && (data.barcode === null || text(data.barcode))
      && integer(data.salePrice, 1) && integer(data.costPrice) && data.costPrice <= data.salePrice
      && integer(data.stock) && integer(data.lowStockThreshold) && timestamp(data.updatedAt)
      && data.deletedAt === null && text(data.category) && text(data.unit)
      && typeof data.fixtureId === 'string' && text(data.locationLabel));
    return;
  }
  requireValid(collection === 'transactions' && timestamp(data.createdAt)
    && text(data.summaryTitle) && data.paymentMethod === 'cash'
    && integer(data.totalAmount, 1) && integer(data.discountAmount)
    && integer(data.cashReceived) && integer(data.changeAmount) && integer(data.itemCount, 1)
    && Array.isArray(data.items) && data.items.length > 0 && data.items.length <= 1000);
  const ids = new Set();
  let subtotal = 0;
  let count = 0;
  for (const item of data.items) {
    requireValid(item && segment(item.productId) && !ids.has(item.productId)
      && text(item.productName) && integer(item.quantity, 1) && integer(item.unitPrice, 1)
      && integer(item.subtotal, 1) && item.subtotal === item.quantity * item.unitPrice);
    ids.add(item.productId);
    subtotal += item.subtotal;
    count += item.quantity;
  }
  requireValid(integer(subtotal, 1) && integer(count, 1) && data.discountAmount < subtotal
    && data.totalAmount === subtotal - data.discountAmount && data.itemCount === count
    && data.cashReceived >= data.totalAmount && data.changeAmount === data.cashReceived - data.totalAmount);
}

export function summarize(records) {
  const perDay = {};
  let products = 0;
  let totalAmount = 0;
  let units = 0;
  for (const { collection, data } of records) {
    if (collection === 'products') { products++; continue; }
    const day = localDay(data.createdAt);
    perDay[day] ??= { receipts: 0, units: 0, totalAmount: 0 };
    perDay[day].receipts++;
    perDay[day].units += data.itemCount;
    perDay[day].totalAmount += data.totalAmount;
    totalAmount += data.totalAmount;
    units += data.itemCount;
  }
  return { products, receipts: records.length - products, units, totalAmount, perDay };
}

function toValue(value) {
  if (value === null) return { nullValue: null };
  if (typeof value === 'string') return { stringValue: value };
  if (Number.isSafeInteger(value)) return { integerValue: String(value) };
  if (Array.isArray(value)) return { arrayValue: { values: value.map(toValue) } };
  if (value && typeof value === 'object') return { mapValue: { fields: toFields(value) } };
  throw new SeedError('Nilai dokumen tidak didukung.');
}
function toFields(data) {
  return Object.fromEntries(Object.entries(data).map(([key, value]) => [key, toValue(value)]));
}
function fromValue(value) {
  if ('nullValue' in value) return null;
  if ('stringValue' in value) return value.stringValue;
  if ('integerValue' in value) {
    const number = Number(value.integerValue);
    requireValid(Number.isSafeInteger(number));
    return number;
  }
  if ('timestampValue' in value) {
    const epoch = Date.parse(value.timestampValue);
    requireValid(timestamp(epoch));
    return epoch;
  }
  if ('arrayValue' in value) return (value.arrayValue.values ?? []).map(fromValue);
  if ('mapValue' in value) return fromFields(value.mapValue.fields ?? {});
  throw new SeedError('Bentuk nilai Firestore tidak didukung; verifikasi gagal.');
}
function fromFields(fields) {
  return Object.fromEntries(Object.entries(fields).map(([key, value]) => [key, fromValue(value)]));
}
function tokenFrom(env) {
  const token = (env.FIRESTORE_ACCESS_TOKEN || env.GOOGLE_OAUTH_ACCESS_TOKEN || '').trim();
  if (!token) throw new SeedError('Apply perlu FIRESTORE_ACCESS_TOKEN atau GOOGLE_OAUTH_ACCESS_TOKEN lokal.');
  if (!/^[A-Za-z0-9._~+\/-]+=*$/.test(token) || token.length > 8192) {
    throw new SeedError('Format access token tidak valid. Jangan kirim token melalui chat.');
  }
  return token;
}

export async function applyDataset({ env = process.env, fetchImpl = globalThis.fetch, sleep = delay } = {}) {
  const token = tokenFrom(env);
  const records = buildDataset();
  const transient = new Set([408, 429, 500, 502, 503, 504]);
  async function request(url, body) {
    for (let attempt = 0; attempt < 3; attempt++) {
      try {
        const response = await fetchImpl(url, {
          method: body ? 'POST' : 'GET', redirect: 'error', signal: AbortSignal.timeout(10000),
          headers: { Authorization: `Bearer ${token}`, ...(body ? { 'Content-Type': 'application/json' } : {}) },
          ...(body ? { body: JSON.stringify(body) } : {}),
        });
        if (response.status === 401 || response.status === 403) {
          throw new SeedError(`Firestore HTTP ${response.status}: autentikasi/izin gagal; apply dihentikan.`);
        }
        if (transient.has(response.status)) {
          await response.body?.cancel();
          if (attempt === 2) throw new SeedError(`Firestore HTTP ${response.status}: batas 3 percobaan; hasil belum terverifikasi.`);
        } else {
          let data;
          try { data = await response.json(); } catch {
            throw new SeedError('Respons Firestore bukan JSON valid; hasil belum terverifikasi.');
          }
          return { status: response.status, data };
        }
      } catch (error) {
        if (error instanceof SeedError) throw error;
        // Jangan teruskan pesan fetch/server: pesan dapat memuat header atau kredensial.
        if (attempt === 2) throw new SeedError('Jaringan/timeout Firestore gagal setelah 3 percobaan; hasil belum terverifikasi.');
      }
      await sleep(250 * (attempt + 1));
    }
  }
  const nameOf = ({ collection, id }) => `${ROOT}/stores/${STORE}/${collection}/${id}`;
  const urlOf = (record) => `https://firestore.googleapis.com/v1/${nameOf(record)}`;
  const createdIds = new Set();
  let skipped = 0;
  for (const record of records) {
    const existing = await request(urlOf(record));
    if (existing.status === 200) { skipped++; continue; }
    if (existing.status !== 404 || existing.data?.error?.status !== 'NOT_FOUND') {
      throw new SeedError(`Firestore HTTP ${existing.status}: pemeriksaan dokumen gagal; apply dihentikan.`);
    }
    const result = await request(`${API}:commit`, {
      writes: [{ update: { name: nameOf(record), fields: toFields(record.data) },
        currentDocument: { exists: false } }],
    });
    if (result.status === 200 && result.data?.writeResults?.length === 1) {
      createdIds.add(record.id);
    } else if (result.status === 409
      && ['ALREADY_EXISTS', 'FAILED_PRECONDITION'].includes(result.data?.error?.status)) {
      const raced = await request(urlOf(record));
      if (raced.status !== 200 || raced.data?.name !== nameOf(record)) {
        throw new SeedError('Konflik create-only tanpa dokumen terbaca; hasil belum terverifikasi.');
      }
      skipped++;
    } else {
      throw new SeedError(`Firestore HTTP ${result.status}: create-only gagal; hasil belum terverifikasi.`);
    }
  }
  const verified = [];
  let skippedDifferent = 0;
  for (const record of records) {
    const result = await request(urlOf(record));
    if (result.status !== 200 || result.data?.name !== nameOf(record) || !result.data?.fields) {
      throw new SeedError('Read-back dokumen gagal; apply belum terverifikasi.');
    }
    const data = fromFields(result.data.fields);
    validateRecord({ ...record, data });
    const matches = Object.entries(record.data).every(([key, value]) => isDeepStrictEqual(data[key], value));
    if (!matches && createdIds.has(record.id)) {
      throw new SeedError('Read-back dokumen baru berbeda dari rencana; apply belum terverifikasi.');
    }
    if (!matches) skippedDifferent++;
    verified.push({ ...record, data });
  }
  requireValid(createdIds.size + skipped === records.length && verified.length === records.length);
  return { created: createdIds.size, skipped, skippedDifferent, verified: verified.length,
    observed: summarize(verified) };
}

export async function runCli(args, { env = process.env, fetchImpl = globalThis.fetch,
  sleep = delay, log = console.log } = {}) {
  const allowed = new Set(['--apply', '--dry-run', '--check-only', '--help']);
  if (args.some((arg) => !allowed.has(arg)) || new Set(args).size !== args.length
    || args.length > 1) throw new SeedError('Gunakan satu opsi: --dry-run, --check-only, --apply, atau --help. Target tidak dapat diubah.');
  if (args[0] === '--help') {
    log('Node >=18. node mobile/tool/seed_firestore_november.mjs [--dry-run|--check-only|--apply]');
    log('Default/check-only: validasi lokal, tanpa jaringan/berkas. Apply: token OAuth lokal melalui env, create-only, read-back wajib.');
    return;
  }
  const apply = args[0] === '--apply';
  if (apply) tokenFrom(env);
  log(JSON.stringify({ mode: apply ? 'apply-pending-verification' : 'dry-run',
    project: PROJECT, store: `stores/${STORE}`, seedBatchId: BATCH,
    paths: [`stores/${STORE}/products`, `stores/${STORE}/transactions`],
    timezone: 'UTC+07:00', origin: 'synthetic',
    note: 'Rencana data sintetis tunai, termasuk tanggal mendatang; bukan bukti pembayaran nyata. Stok lama tidak diubah.',
    planned: summarize(buildDataset()) }, null, 2));
  if (apply) log(JSON.stringify({ status: 'read-back-verified',
    ...await applyDataset({ env, fetchImpl, sleep }) }, null, 2));
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  runCli(process.argv.slice(2)).catch((error) => {
    console.error(error instanceof SeedError ? error.message : 'Tool gagal; hasil belum terverifikasi. Detail eksternal disembunyikan untuk melindungi kredensial.');
    process.exitCode = 1;
  });
}
