import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ryangunshop/core/data/app_database.dart';
import 'package:ryangunshop/core/data/cart_draft_repository.dart';
import 'package:ryangunshop/core/data/sync/outbox.dart';
import 'package:ryangunshop/core/data/sync/sync_queue.dart';
import 'package:ryangunshop/core/session/app_session.dart';
import 'package:ryangunshop/core/data/drift_product_repository.dart';
import 'package:ryangunshop/core/data/product_record.dart';
import 'package:ryangunshop/core/data/sync/cloud_read_through.dart';
import 'package:ryangunshop/core/data/sync/drift_sync_queue.dart';
import 'package:ryangunshop/core/data/sync/firestore_schema.dart';
import 'package:ryangunshop/core/data/transaction_repository.dart';

const product = ProductRecord(
  id: 'p',
  barcode: '123',
  name: 'Beras',
  salePrice: 100,
  stock: 10,
);
final date = DateTime(2026, 11, 16, 12);
Map<String, Object?> productData({int stock = 10}) => {
  ...FirestoreSchema.productDocument(product, updatedAt: date),
  'stock': stock,
  'updatedAt': Timestamp.fromDate(date),
};
Map<String, Object?> receiptData() => {
  ...FirestoreSchema.transactionDocument(
    TransactionRecord(
      id: 'r',
      createdAt: date,
      totalAmount: 200,
      discountAmount: 0,
      paymentMethod: 'cash',
      cashReceived: 300,
      changeAmount: 100,
      itemCount: 2,
    ),
    const [
      SoldItem(
        productId: 'p',
        productName: 'Beras',
        quantity: 2,
        unitPrice: 100,
        subtotal: 200,
      ),
    ],
  ),
  'createdAt': Timestamp.fromDate(date),
};
CloudSnapshot snapshot({int stock = 10}) => CloudSnapshot(
  products: {'p': productData(stock: stock)},
  transactions: {'r': receiptData()},
);

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('read repository selalu segar, dedup, impor nota tanpa stok/outbox/cart berubah', () async {
    await CartDraftRepository(db).save(
      const CartDraftSnapshot(
        note: 'Jangan hapus',
        items: [
          CartDraftLine(
            productId: 'p',
            productName: 'Beras',
            unitPrice: 100,
            quantity: 1,
            unit: 'pcs',
          ),
        ],
      ),
    );
    var calls = 0;
    var stock = 10;
    final cloud = CloudReadThrough(
      database: db,
      fetch: () async {
        calls++;
        return snapshot(stock: stock);
      },
    );
    addTearDown(cloud.dispose);
    final products = DriftProductRepository(db, beforeRead: cloud.refresh);
    final receipts = DriftTransactionRepository(db, beforeRead: cloud.refresh);
    await Future.wait<Object>([
      products.listProducts(),
      receipts.summaryForDay(date),
    ]);
    expect(calls, 1);
    expect((await db.listProducts()).single.stock, 10);
    expect((await receipts.listForDay(date)).single.items.single.quantity, 2);
    expect(await db.select(db.transactionItems).get(), hasLength(1));
    expect(await db.select(db.syncOutboxEntries).get(), isEmpty);
    stock = 8;
    await cloud.refresh(force: true);
    expect((await products.findByBarcode('123'))!.stock, 8);
    expect((await receipts.listRecent()).single.totalAmount, 200);
    expect(await db.select(db.transactionItems).get(), hasLength(1));
    expect(cloud.lastError, isNull);
    final draft = await CartDraftRepository(db).load();
    expect(draft.note, 'Jangan hapus');
    expect(draft.items.single.quantity, 1);
  });

  test('snapshot rusak tidak mengimpor sebagian; offline fallback', () async {
    await DriftProductRepository(db).save(product);
    var fail = false;
    final cloud = CloudReadThrough(
      database: db,
      fetch: () async {
        if (fail) throw StateError('offline');
        return CloudSnapshot(
          products: {'p': productData(stock: 3)},
          transactions: {
            'r': {...receiptData(), 'totalAmount': 1.5},
          },
        );
      },
    );
    addTearDown(cloud.dispose);
    final repo = DriftProductRepository(db, beforeRead: cloud.refresh);
    expect((await repo.listProducts()).single.stock, 10);
    expect(cloud.lastError, isA<FormatException>());
    expect(await db.select(db.transactions).get(), isEmpty);
    fail = true;
    await cloud.refresh(force: true);
    expect((await repo.listProducts()).single.stock, 10);
    expect(cloud.lastError, isA<StateError>());
  });

  test(
    'pending save/delete tetap terlindung walau outbox dikuras saat fetch',
    () async {
      final queue = DriftSyncQueue(db);
      final repo = DriftProductRepository(db, queue: queue);
      await repo.save(product);
      final gate = Completer<CloudSnapshot>();
      final started = Completer<void>();
      final cloud = CloudReadThrough(
        database: db,
        fetch: () {
          if (!started.isCompleted) started.complete();
          return gate.future;
        },
      );
      addTearDown(cloud.dispose);
      final reading = cloud.refresh();
      await started.future;
      for (final entry in await queue.pending()) {
        await queue.markSynced(entry);
      }
      gate.complete(snapshot(stock: 1));
      await reading;
      expect((await db.listProducts()).single.stock, 10);
      await repo.delete('p');
      await cloud.refresh();
      expect(await db.listProducts(), isEmpty);
    },
  );

  test(
    'write berjalan selama fetch membatalkan snapshot lama termasuk delete',
    () async {
      final gate = Completer<CloudSnapshot>();
      final started = Completer<void>();
      final cloud = CloudReadThrough(
        database: db,
        fetch: () {
          started.complete();
          return gate.future;
        },
      );
      addTearDown(cloud.dispose);
      final reading = cloud.refresh();
      await started.future;
      await DriftProductRepository(db).save(product);
      await DriftProductRepository(db).delete('p');
      gate.complete(snapshot());
      await reading;
      expect(await db.listProducts(), isEmpty);
      expect(cloud.lastError, isA<StateError>());
    },
  );

  test(
    'timeout tidak mengimpor hasil terlambat; read berikutnya dapat pulih',
    () async {
      final gate = Completer<CloudSnapshot>();
      var late = true;
      final cloud = CloudReadThrough(
        database: db,
        timeout: const Duration(milliseconds: 10),
        fetch: () => late ? gate.future : Future.value(snapshot()),
      );
      addTearDown(cloud.dispose);
      await cloud.refresh();
      expect(cloud.lastError, isA<TimeoutException>());
      gate.complete(snapshot());
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(await db.listProducts(), isEmpty);
      late = false;
      await cloud.refresh(force: true);
      expect(cloud.lastError, isNull);
      expect(await db.listProducts(), hasLength(1));
    },
  );

  test(
    'tombstone saja menghapus; dokumen absen tidak menghapus lokal',
    () async {
      await DriftProductRepository(db).save(product);
      var deleted = false;
      final cloud = CloudReadThrough(
        database: db,
        fetch: () async => CloudSnapshot(
          products: deleted
              ? {'p': FirestoreSchema.productDeletionDocument(deletedAt: date)}
              : {},
          transactions: const {},
        ),
      );
      addTearDown(cloud.dispose);
      await cloud.refresh();
      expect(await db.listProducts(), hasLength(1));
      deleted = true;
      await cloud.refresh(force: true);
      expect(await db.listProducts(), isEmpty);
    },
  );

  test(
    'constraint konflik rollback header, items, produk seluruh snapshot',
    () async {
      await DriftProductRepository(db).save(product);
      final cloud = CloudReadThrough(
        database: db,
        fetch: () async => CloudSnapshot(
          products: {'p': productData(stock: 3), 'other': productData()},
          transactions: {'r': receiptData()},
        ),
      );
      addTearDown(cloud.dispose);
      await cloud.refresh();
      expect(cloud.lastError, isNotNull);
      expect((await db.listProducts()).single.stock, 10);
      expect(await db.select(db.transactions).get(), isEmpty);
    },
  );

  test('pending checkout melindungi nota dan stok; impor tidak mengulang pengurangan', () async {
    final queue = DriftSyncQueue(db);
    await DriftProductRepository(db).save(product);
    final repo = DriftTransactionRepository(db, queue: queue);
    await repo.checkout(
      transactionId: 'r',
      paymentMethod: 'cash',
      totalAmount: 100,
      cashReceived: 100,
      changeAmount: 0,
      lines: const [
        CheckoutLine(
          productId: 'p',
          quantity: 1,
          unitPrice: 100,
          subtotal: 100,
        ),
      ],
    );
    // Kompatibilitas outbox versi lama: hanya nota, tanpa entri produk.
    for (final entry in await queue.pending()) {
      if (entry.entity == SyncEntityType.product) await queue.markSynced(entry);
    }
    final cloud = CloudReadThrough(database: db, fetch: () async => snapshot());
    addTearDown(cloud.dispose);
    await cloud.refresh();
    expect((await db.listProducts()).single.stock, 9);
    expect((await repo.findById('r'))!.totalAmount, 100);
    expect((await db.select(db.transactionItems).get()).single.quantity, 1);
    expect(await queue.pendingCount(), 1);
  });

  test('save dan delete rollback bila outbox gagal', () async {
    final repo = DriftProductRepository(db, queue: _FailingQueue());
    await expectLater(repo.save(product), throwsStateError);
    expect(await db.listProducts(), isEmpty);
    await DriftProductRepository(db).save(product);
    await expectLater(repo.delete('p'), throwsStateError);
    expect((await db.listProducts()).single.stock, 10);
  });

  test('session getter dan summary memakai cloud, tanpa memulihkan keranjang dari cloud', () async {
    final cloud = CloudReadThrough(database: db, fetch: () async => snapshot());
    final session = AppSession(database: db, cloudReadThrough: cloud);
    addTearDown(session.dispose);
    addTearDown(cloud.dispose);
    await session.loadLocalCart();
    await session.loadLocalSummary();
    expect(
      (await session.productRepository.listProducts()).single.name,
      'Beras',
    );
    expect(
      (await session.transactionRepository.findById('r'))!.totalAmount,
      200,
    );
    expect(session.recentTransactions.single.amount, 200);
    expect(session.cart.items, isEmpty);
    await session.finishLocalWrites();
  });

  test(
    'TTL sukses, backoff gagal dan force membatasi read berurutan',
    () async {
      var clock = date;
      var calls = 0;
      var offline = false;
      final cloud = CloudReadThrough(
        database: db,
        now: () => clock,
        fetch: () async {
          calls++;
          if (offline) throw StateError('offline');
          return snapshot();
        },
      );
      addTearDown(cloud.dispose);
      final repo = DriftProductRepository(db, beforeRead: cloud.refresh);
      await repo.listProducts();
      await repo.findByBarcode('123');
      await DriftTransactionRepository(
        db,
        beforeRead: cloud.refresh,
      ).listRecent();
      expect(calls, 1);
      clock = clock.add(const Duration(seconds: 15));
      await repo.listProducts();
      expect(calls, 2);
      offline = true;
      await cloud.refresh(force: true);
      for (var i = 0; i < 5; i++) {
        await repo.listProducts();
      }
      expect(calls, 3);
      clock = clock.add(const Duration(seconds: 29));
      await cloud.refresh();
      expect(calls, 3);
      clock = clock.add(const Duration(seconds: 1));
      await cloud.refresh();
      expect(calls, 4);
      offline = false;
      await cloud.refresh(force: true);
      expect(calls, 5);
      expect(cloud.lastError, isNull);
    },
  );

  test('timeout tetap satu raw fetch walau force dan backoff lewat', () async {
    var clock = date;
    var calls = 0;
    final gate = Completer<CloudSnapshot>();
    final cloud = CloudReadThrough(
      database: db,
      now: () => clock,
      timeout: const Duration(milliseconds: 1),
      fetch: () {
        calls++;
        return gate.future;
      },
    );
    addTearDown(cloud.dispose);
    await cloud.refresh();
    clock = clock.add(const Duration(minutes: 1));
    await cloud.refresh(force: true);
    await cloud.refresh();
    expect(calls, 1);
    gate.complete(snapshot());
    await Future<void>.delayed(Duration.zero);
    expect(await db.listProducts(), isEmpty);
    await cloud.refresh(force: true);
    expect(calls, 2);
    expect(await db.listProducts(), hasLength(1));
  });

  test('legacy ack simpan stok atomik sampai ack produk; pending delete tidak ditimpa', () async {
    await DriftProductRepository(db).save(product);
    final queue = DriftSyncQueue(db);
    await DriftTransactionRepository(db).checkout(
      transactionId: 'legacy',
      paymentMethod: 'cash',
      totalAmount: 100,
      cashReceived: 100,
      changeAmount: 0,
      lines: const [
        CheckoutLine(
          productId: 'p',
          quantity: 1,
          unitPrice: 100,
          subtotal: 100,
        ),
      ],
    );
    Future<void> legacy() => queue.enqueue(
      OutboxEntry(
        entity: SyncEntityType.transaction,
        entityId: 'legacy',
        operation: SyncOperation.upsert,
        payload: {...receiptData(), 'createdAt': date.millisecondsSinceEpoch},
        createdAt: date,
      ),
    );
    await legacy();
    final before = db.localWriteRevision;
    final receipt = (await queue.pending()).single;
    await queue.markSynced(receipt);
    await queue.markSynced(receipt); // ack ulang tidak duplikasi
    expect(db.localWriteRevision, greaterThan(before));
    var pending = await queue.pending();
    expect(pending.single.entity, SyncEntityType.product);
    expect(pending.single.payload['stock'], 9);
    final cloud = CloudReadThrough(database: db, fetch: () async => snapshot());
    addTearDown(cloud.dispose);
    await cloud.refresh();
    expect((await db.listProducts()).single.stock, 9);
    await queue.markSynced(pending.single);
    await cloud.refresh(force: true);
    expect((await db.listProducts()).single.stock, 10);
    await DriftProductRepository(db, queue: queue).delete('p');
    await legacy();
    pending = await queue.pending();
    await queue.markSynced(
      pending.singleWhere((e) => e.entity == SyncEntityType.transaction),
    );
    expect((await queue.pending()).single.operation, SyncOperation.delete);
  });

  test('legacy ack menambah stok terbaru setelah pending upsert lama tanpa menimpanya', () async {
    final queue = DriftSyncQueue(db);
    await DriftProductRepository(db, queue: queue).save(product);
    await DriftTransactionRepository(db).checkout(
      transactionId: 'legacy',
      paymentMethod: 'cash',
      totalAmount: 100,
      cashReceived: 100,
      changeAmount: 0,
      lines: const [
        CheckoutLine(
          productId: 'p',
          quantity: 1,
          unitPrice: 100,
          subtotal: 100,
        ),
      ],
    );
    await queue.enqueue(
      OutboxEntry(
        entity: SyncEntityType.transaction,
        entityId: 'legacy',
        operation: SyncOperation.upsert,
        payload: {...receiptData(), 'createdAt': date.millisecondsSinceEpoch},
        createdAt: date,
      ),
    );
    final original = (await queue.pending()).first;
    await queue.markSynced((await queue.pending()).last);
    final pending = await queue.pending();
    expect(pending.length, 2);
    expect(pending.first.id, original.id);
    expect(pending.first.payload['stock'], 10);
    expect(pending.last.payload['stock'], 9);
  });

  test('legacy ack gagal tidak menghapus receipt bila stok hilang', () async {
    await DriftProductRepository(db).save(product);
    await DriftTransactionRepository(db).checkout(
      transactionId: 'legacy',
      paymentMethod: 'cash',
      totalAmount: 100,
      cashReceived: 100,
      changeAmount: 0,
      lines: const [
        CheckoutLine(
          productId: 'p',
          quantity: 1,
          unitPrice: 100,
          subtotal: 100,
        ),
      ],
    );
    await DriftProductRepository(db).delete('p');
    final queue = DriftSyncQueue(db);
    await queue.enqueue(
      OutboxEntry(
        entity: SyncEntityType.transaction,
        entityId: 'legacy',
        operation: SyncOperation.upsert,
        payload: {...receiptData(), 'createdAt': date.millisecondsSinceEpoch},
        createdAt: date,
      ),
    );
    await expectLater(
      queue.markSynced((await queue.pending()).single),
      throwsStateError,
    );
    expect(await queue.pendingCount(), 1);
  });

  test(
    'session revision berubah untuk stok saja dan nota lama, tanpa fetch loop',
    () async {
      var calls = 0;
      var stock = 10;
      final cloud = CloudReadThrough(
        database: db,
        fetch: () async {
          calls++;
          return snapshot(stock: stock);
        },
      );
      final session = AppSession(database: db, cloudReadThrough: cloud);
      addTearDown(session.dispose);
      addTearDown(cloud.dispose);
      await session.loadLocalCart();
      await session.loadLocalSummary();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final revision = session.dataRevision;
      final count = session.todayTransactionCount;
      stock = 2;
      await session.refreshCloud(force: true);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(session.dataRevision, greaterThan(revision));
      expect(session.lowStockCount, 1);
      expect(session.todayTransactionCount, count);
      expect(calls, 2);
      await session.productRepository.listProducts();
      await session.transactionRepository.listRecent();
      expect(calls, 2);
      await session.finishLocalWrites();
    },
  );

  test(
    'dataset seed 24 produk 66 nota lolos decoder dan impor tanpa stok ulang',
    () async {
      final result = await Process.run('node', [
        '--input-type=module',
        '-e',
        "import {buildDataset} from './tool/seed_firestore_november.mjs'; console.log(JSON.stringify(buildDataset()));",
      ]).timeout(const Duration(seconds: 10));
      expect(result.exitCode, 0);
      final records = jsonDecode(result.stdout as String) as List;
      final products = <String, Map<String, Object?>>{};
      final receipts = <String, Map<String, Object?>>{};
      for (final raw in records.cast<Map<String, dynamic>>()) {
        final data = Map<String, Object?>.from(raw['data'] as Map);
        (raw['collection'] == 'products' ? products : receipts)[raw['id']
                as String] =
            data;
      }
      expect(products.length, 24);
      expect(receipts.length, 66);
      final cloud = CloudReadThrough(
        database: db,
        fetch: () async =>
            CloudSnapshot(products: products, transactions: receipts),
      );
      addTearDown(cloud.dispose);
      await cloud.refresh();
      expect(cloud.lastError, isNull);
      expect(await db.select(db.transactions).get(), hasLength(66));
      for (final product in await db.listProducts()) {
        expect(product.stock, products[product.id]!['stock']);
      }
      expect(await db.select(db.syncOutboxEntries).get(), isEmpty);
    },
  );

  test(
    'checkout setelah seed tetap tersimpan saat refresh lama dan impor ulang',
    () async {
      final result = await Process.run('node', [
        '--input-type=module',
        '-e',
        "import {buildDataset} from './tool/seed_firestore_november.mjs'; console.log(JSON.stringify(buildDataset()));",
      ]).timeout(const Duration(seconds: 10));
      expect(result.exitCode, 0);
      final records = jsonDecode(result.stdout as String) as List;
      final products = <String, Map<String, Object?>>{};
      final receipts = <String, Map<String, Object?>>{};
      for (final raw in records.cast<Map<String, dynamic>>()) {
        final data = Map<String, Object?>.from(raw['data'] as Map);
        (raw['collection'] == 'products' ? products : receipts)[raw['id']
                as String] =
            data;
      }
      expect(products, hasLength(24));
      expect(receipts, hasLength(66));
      var calls = 0;
      final cloud = CloudReadThrough(
        database: db,
        now: () => date,
        fetch: () async {
          calls++;
          return CloudSnapshot(products: products, transactions: receipts);
        },
      );
      addTearDown(cloud.dispose);
      final queue = DriftSyncQueue(db);
      final productRepo = DriftProductRepository(db, beforeRead: cloud.refresh);
      final repo = DriftTransactionRepository(
        db,
        queue: queue,
        beforeRead: cloud.refresh,
      );
      final seeded = await productRepo.listProducts();
      expect(cloud.lastError, isNull);
      expect(seeded, hasLength(24));
      expect(await repo.listRecent(limit: 100), hasLength(66));
      expect(await queue.pendingCount(), 0);
      for (final item in seeded) {
        expect(item.stock, products[item.id]!['stock']);
      }
      final sold = seeded.firstWhere((item) => item.stock >= 2);
      const saleId = 'TRX-POS-AFTER-SEED';
      const quantity = 2;
      const discount = 500;
      final subtotal = sold.salePrice * quantity;
      final total = subtotal - discount;
      final cash = subtotal + 1000;
      final seedTotal = receipts.values.fold<int>(
        0,
        (amount, receipt) => amount + (receipt['totalAmount'] as int),
      );
      final seedItemCount = receipts.values.fold<int>(
        0,
        (itemTotal, receipt) => itemTotal + (receipt['items'] as List).length,
      );
      await repo.checkout(
        transactionId: saleId,
        paymentMethod: 'cash',
        totalAmount: total,
        discountAmount: discount,
        cashReceived: cash,
        changeAmount: cash - total,
        lines: [
          CheckoutLine(
            productId: sold.id,
            quantity: quantity,
            unitPrice: sold.salePrice,
            subtotal: subtotal,
          ),
        ],
      );
      final pending = await queue.pending();
      expect(pending, hasLength(2));
      final stockWrite = pending.singleWhere(
        (entry) => entry.entity == SyncEntityType.product,
      );
      expect(stockWrite.entityId, sold.id);
      expect(stockWrite.operation, SyncOperation.upsert);
      expect(stockWrite.payload['stock'], sold.stock - quantity);
      final saleWrite = pending.singleWhere(
        (entry) => entry.entity == SyncEntityType.transaction,
      );
      expect(saleWrite.entityId, saleId);
      expect(saleWrite.operation, SyncOperation.upsert);
      expect(saleWrite.payload, containsPair('totalAmount', total));
      expect(saleWrite.payload, containsPair('discountAmount', discount));
      expect(saleWrite.payload, containsPair('cashReceived', cash));
      expect(saleWrite.payload, containsPair('changeAmount', cash - total));
      expect(saleWrite.payload, containsPair('paymentMethod', 'cash'));
      expect(saleWrite.payload, containsPair('itemCount', quantity));
      expect(saleWrite.payload, containsPair('stockQueued', true));
      expect(saleWrite.payload['items'], [
        {
          'productId': sold.id,
          'productName': sold.name,
          'quantity': quantity,
          'unitPrice': sold.salePrice,
          'subtotal': subtotal,
        },
      ]);

      // Snapshot tetap sebelum penjualan; dua refresh wajib benar-benar impor.
      for (var pass = 0; pass < 3; pass++) {
        if (pass > 0) await cloud.refresh(force: true);
        expect(cloud.lastError, isNull);
        expect(calls, pass + 1);
        final currentProducts = await productRepo.listProducts();
        expect(currentProducts, hasLength(24));
        for (final item in currentProducts) {
          expect(
            item.stock,
            (products[item.id]!['stock'] as int) -
                (item.id == sold.id ? quantity : 0),
          );
        }
        final currentReceipts = await repo.listRecent(limit: 100);
        expect(currentReceipts, hasLength(67));
        expect(
          currentReceipts.map((receipt) => receipt.id),
          unorderedEquals([...receipts.keys, saleId]),
        );
        expect(
          currentReceipts.fold<int>(
            0,
            (amount, receipt) => amount + receipt.totalAmount,
          ),
          seedTotal + total,
        );
        final sale = currentReceipts.singleWhere(
          (receipt) => receipt.id == saleId,
        );
        expect(sale.totalAmount, total);
        expect(sale.discountAmount, discount);
        expect(sale.cashReceived, cash);
        expect(sale.changeAmount, cash - total);
        expect(sale.paymentMethod, 'cash');
        expect(sale.itemCount, quantity);
        final items = await db.select(db.transactionItems).get();
        expect(items, hasLength(seedItemCount + 1));
        final line = items.singleWhere((item) => item.transactionId == saleId);
        expect(line.productId, sold.id);
        expect(line.productName, sold.name);
        expect(line.quantity, quantity);
        expect(line.unitPrice, sold.salePrice);
        expect(line.subtotal, subtotal);
        expect(
          (await queue.pending()).map((entry) => entry.toJson()).toList(),
          pending.map((entry) => entry.toJson()).toList(),
        );
      }
    },
  );

  test('validasi angka waktu item dan pembayaran ketat', () {
    for (final bad in <Object?>[
      -1,
      1.2,
      double.nan,
      double.infinity,
      '100',
      null,
      9007199254740992,
    ]) {
      expect(
        () => FirestoreSchema.productFromDocument('p', {
          ...productData(),
          'salePrice': bad,
        }),
        throwsFormatException,
      );
    }
    for (final patch in <Map<String, Object?>>[
      {'createdAt': null},
      {'createdAt': -1},
      {'createdAt': 'bad'},
      {'paymentMethod': 'qris'},
      {'itemCount': 1},
      {'changeAmount': 0},
      {'items': []},
      {
        'items': [null],
      },
      {'schemaVersion': 999},
      {
        'items': [
          const SoldItem(
            productId: 'p',
            productName: 'Beras',
            quantity: 2,
            unitPrice: 100,
            subtotal: 199,
          ).toJson(),
        ],
      },
    ]) {
      expect(
        () => FirestoreSchema.transactionFromDocument('r', {
          ...receiptData(),
          ...patch,
        }),
        throwsFormatException,
      );
    }
    final record = FirestoreSchema.transactionFromDocument('r', receiptData());
    expect(record.createdAt, date);
    expect(record.items.single.subtotal, 200);
  });
}

class _FailingQueue extends InMemorySyncQueue {
  @override
  Future<void> enqueue(OutboxEntry entry) async =>
      throw StateError('disk penuh');
}
