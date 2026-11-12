import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ryangunshop/core/data/app_database.dart';
import 'package:ryangunshop/core/data/drift_product_repository.dart';
import 'package:ryangunshop/core/data/product_record.dart';
import 'package:ryangunshop/core/data/sync/drift_sync_queue.dart';
import 'package:ryangunshop/core/data/sync/firestore_schema.dart';
import 'package:ryangunshop/core/data/sync/outbox.dart';
import 'package:ryangunshop/core/data/sync/sync_engine.dart';
import 'package:ryangunshop/core/data/sync/sync_queue.dart';
import 'package:ryangunshop/core/data/transaction_repository.dart';

const _product = ProductRecord(
  id: 'p-1',
  barcode: '8990001',
  name: 'Air Mineral',
  salePrice: 4000,
  stock: 12,
  costPrice: 2500,
  category: 'Minuman',
  unit: 'botol',
  locationLabel: 'Rak depan',
);

void main() {
  group('skema Firestore', () {
    test('menyusun jalur dokumen di bawah satu toko', () {
      expect(
        FirestoreSchema.productsPath('toko-utama'),
        'stores/toko-utama/products',
      );
      expect(
        FirestoreSchema.productPath('toko-utama', 'p-1'),
        'stores/toko-utama/products/p-1',
      );
      expect(
        FirestoreSchema.transactionPath('toko-utama', 'TRX-1'),
        'stores/toko-utama/transactions/TRX-1',
      );
    });

    test('menolak cabang toko kosong atau berisi garis miring', () {
      expect(() => FirestoreSchema.productPath('', 'p-1'), throwsArgumentError);
      expect(
        () => FirestoreSchema.productPath('toko/lain', 'p-1'),
        throwsArgumentError,
      );
    });

    test('dokumen produk dapat dibaca kembali tanpa kehilangan data', () {
      final payload = FirestoreSchema.productDocument(
        _product,
        updatedAt: DateTime(2026, 11, 13, 10),
      );
      final result = FirestoreSchema.productFromDocument('p-1', payload);

      expect(payload['schemaVersion'], FirestoreSchema.version);
      expect(payload['barcode'], '8990001');
      expect(payload['salePrice'], 4000);
      expect(payload['updatedAt'], DateTime(2026, 11, 13, 10).millisecondsSinceEpoch);
      expect(result.name, 'Air Mineral');
      expect(result.stock, 12);
      expect(result.category, 'Minuman');
      expect(result.unit, 'botol');
    });

    test('barcode kosong disimpan sebagai null', () {
      final payload = FirestoreSchema.productDocument(
        const ProductRecord(
          id: 'p-2',
          barcode: '  ',
          name: 'Gula',
          salePrice: 15000,
          stock: 4,
        ),
        updatedAt: DateTime(2026),
      );
      expect(payload['barcode'], isNull);
    });

    test('dokumen nota menyimpan nominal bulat dan baris barang', () {
      final payload = FirestoreSchema.transactionDocument(
        TransactionRecord(
          id: 'TRX-1',
          createdAt: DateTime(2026, 11, 13, 9, 30),
          totalAmount: 8000,
          discountAmount: 0,
          paymentMethod: 'cash',
          cashReceived: 10000,
          changeAmount: 2000,
          itemCount: 2,
          summaryTitle: 'Air Mineral',
        ),
        const [
          SoldItem(
            productId: 'p-1',
            productName: 'Air Mineral',
            quantity: 2,
            unitPrice: 4000,
            subtotal: 8000,
          ),
        ],
      );
      final record = FirestoreSchema.transactionFromDocument('TRX-1', payload);
      final items = FirestoreSchema.soldItemsFromDocument(payload);

      expect(payload['totalAmount'], 8000);
      expect(payload['paymentMethod'], 'cash');
      expect(record.createdAt, DateTime(2026, 11, 13, 9, 30));
      expect(record.summaryTitle, 'Air Mineral');
      expect(items, hasLength(1));
      expect(items.single.quantity, 2);
    });

    test('dokumen produk tidak lengkap ditolak', () {
      expect(
        () => FirestoreSchema.productFromDocument('p-1', const {'name': ''}),
        throwsFormatException,
      );
    });
  });

  group('antrean outbox', () {
    test('entri dapat disimpan sebagai JSON dan dibaca kembali', () {
      final entry = OutboxEntry(
        entity: SyncEntityType.product,
        entityId: 'p-1',
        operation: SyncOperation.upsert,
        payload: FirestoreSchema.productDocument(
          _product,
          updatedAt: DateTime(2026, 11, 13),
        ),
        createdAt: DateTime(2026, 11, 13),
      );
      final restored = OutboxEntry.fromJson(entry.toJson());

      expect(restored.entity, SyncEntityType.product);
      expect(restored.operation, SyncOperation.upsert);
      expect(restored.payload['name'], 'Air Mineral');
    });

    test('antrean memori menjaga urutan dan mencatat kegagalan', () async {
      final queue = InMemorySyncQueue();
      final now = DateTime(2026);
      for (final id in ['p-1', 'p-2']) {
        await queue.enqueue(
          OutboxEntry(
            entity: SyncEntityType.product,
            entityId: id,
            operation: SyncOperation.upsert,
            payload: {'name': id},
            createdAt: now,
          ),
        );
      }

      final pending = await queue.pending();
      expect(pending.map((entry) => entry.entityId), ['p-1', 'p-2']);

      await queue.markFailed(pending.first, 'jaringan putus');
      final retried = (await queue.pending()).first;
      expect(retried.attempts, 1);
      expect(retried.lastError, 'jaringan putus');
      expect(await queue.pendingCount(), 2);

      await queue.markSynced(retried);
      expect(await queue.pendingCount(), 1);
    });

    test('antrean SQLite bertahan setelah disimpan', () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final queue = DriftSyncQueue(database);

      await queue.enqueue(
        OutboxEntry(
          entity: SyncEntityType.transaction,
          entityId: 'TRX-1',
          operation: SyncOperation.upsert,
          payload: const {'totalAmount': 8000},
          createdAt: DateTime(2026),
        ),
      );

      final entry = (await queue.pending()).single;
      expect(entry.id, isNotNull);
      expect(entry.entityId, 'TRX-1');
      expect(entry.payload['totalAmount'], 8000);

      await queue.markFailed(entry, 'offline');
      expect((await queue.pending()).single.attempts, 1);

      await queue.markSynced(entry);
      expect(await queue.pendingCount(), 0);
    });
  });

  group('mesin sinkronisasi', () {
    test('mengirim seluruh entri lalu melaporkan tersinkron', () async {
      final queue = InMemorySyncQueue();
      final target = _RecordingTarget();
      await queue.enqueue(_entry('p-1'));
      await queue.enqueue(_entry('p-2'));
      final engine = SyncEngine(queue: queue, target: target);

      final result = await engine.flush();

      expect(target.applied, ['p-1', 'p-2']);
      expect(result.status, SyncStatus.synced);
      expect(result.processed, 2);
      expect(result.remaining, 0);
    });

    test('berhenti pada kegagalan pertama agar urutan terjaga', () async {
      final queue = InMemorySyncQueue();
      final target = _RecordingTarget(failingIds: {'p-1'});
      await queue.enqueue(_entry('p-1'));
      await queue.enqueue(_entry('p-2'));
      final engine = SyncEngine(queue: queue, target: target);

      final result = await engine.flush();

      expect(target.applied, isEmpty);
      expect(result.status, SyncStatus.pending);
      expect(result.failure?.entry.entityId, 'p-1');
      expect(result.remaining, 2);
      expect((await queue.pending()).first.attempts, 1);
    });

    test('tidak menulis saat perangkat offline', () async {
      final queue = InMemorySyncQueue([_entry('p-1')]);
      final target = _RecordingTarget();
      final engine = SyncEngine(queue: queue, target: target)..isOnline = false;

      final result = await engine.flush();

      expect(result.status, SyncStatus.offline);
      expect(result.remaining, 1);
      expect(target.applied, isEmpty);
    });
  });

  group('penulisan lokal mengisi outbox', () {
    late AppDatabase database;

    setUp(() => database = AppDatabase(NativeDatabase.memory()));
    tearDown(() => database.close());

    test('produk baru dan penghapusan masuk antrean', () async {
      final queue = InMemorySyncQueue();
      final repository = DriftProductRepository(database, queue: queue);

      await repository.save(_product);
      var entries = await queue.pending();
      expect(entries, hasLength(1));
      expect(entries.single.operation, SyncOperation.upsert);
      expect(entries.single.payload['stock'], 12);

      await repository.delete('p-1');
      entries = await queue.pending();
      expect(entries, hasLength(2));
      expect(entries.last.operation, SyncOperation.delete);
      expect(entries.last.payload['deletedAt'], isNotNull);
    });

    test('checkout tunai menitipkan nota beserta baris barang', () async {
      final queue = InMemorySyncQueue();
      final products = DriftProductRepository(database);
      await products.save(_product);
      final transactions = DriftTransactionRepository(
        database,
        queue: queue,
      );

      await transactions.checkout(
        transactionId: 'TRX-1',
        paymentMethod: 'cash',
        totalAmount: 8000,
        cashReceived: 10000,
        changeAmount: 2000,
        lines: const [
          CheckoutLine(
            productId: 'p-1',
            quantity: 2,
            unitPrice: 4000,
            subtotal: 8000,
          ),
        ],
      );

      final entry = (await queue.pending()).single;
      expect(entry.entity, SyncEntityType.transaction);
      expect(entry.entityId, 'TRX-1');
      expect(entry.payload['itemCount'], 2);
      expect(entry.payload['summaryTitle'], 'Air Mineral');
      expect(FirestoreSchema.soldItemsFromDocument(entry.payload), hasLength(1));
    });

    test('checkout batal bila antrean gagal, stok tidak berubah', () async {
      await database.saveProduct(
        ProductsCompanion.insert(
          id: 'p-1',
          barcode: const Value('8990001'),
          name: 'Air Mineral',
          salePrice: 4000,
          stock: 3,
          updatedAt: DateTime(2026),
        ),
      );

      await expectLater(
        database.completeCheckout(
          transactionId: 'TRX-GAGAL',
          paymentMethod: 'cash',
          totalAmount: 4000,
          cashReceived: 4000,
          changeAmount: 0,
          afterWrite: () async => throw StateError('disk penuh'),
          lines: const [
            CheckoutLine(
              productId: 'p-1',
              quantity: 1,
              unitPrice: 4000,
              subtotal: 4000,
            ),
          ],
        ),
        throwsStateError,
      );

      expect(await database.select(database.transactions).get(), isEmpty);
      expect((await database.listProducts()).single.stock, 3);
    });
  });
}

OutboxEntry _entry(String id) => OutboxEntry(
  entity: SyncEntityType.product,
  entityId: id,
  operation: SyncOperation.upsert,
  payload: {'name': id},
  createdAt: DateTime(2026),
);

class _RecordingTarget implements SyncTarget {
  _RecordingTarget({this.failingIds = const {}});

  final Set<String> failingIds;
  final List<String> applied = [];

  @override
  Future<void> apply(OutboxEntry entry) async {
    if (failingIds.contains(entry.entityId)) {
      throw StateError('gagal mengirim ${entry.entityId}');
    }
    applied.add(entry.entityId);
  }
}
