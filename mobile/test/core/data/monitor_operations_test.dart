import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ryangunshop/core/data/app_database.dart';
import 'package:ryangunshop/core/data/monitor_layout_repository.dart';
import 'package:ryangunshop/core/data/drift_product_repository.dart';
import 'package:ryangunshop/core/data/product_record.dart';
import 'package:ryangunshop/core/data/sync/cloud_read_through.dart';
import 'package:ryangunshop/core/data/sync/drift_sync_queue.dart';
import 'package:ryangunshop/core/data/sync/firestore_schema.dart';
import 'package:ryangunshop/core/data/sync/monitor_sync.dart';
import 'package:ryangunshop/core/data/sync/outbox.dart';
import 'package:ryangunshop/core/data/sync/sync_engine.dart';
import 'package:ryangunshop/features/monitor/model/monitor_layout.dart';
import 'package:ryangunshop/features/monitor/view/monitor_canvas.dart';
import 'package:ryangunshop/features/monitor/view_model/monitor_view_model.dart';

const product = ProductRecord(
  id: 'p',
  name: 'Kopi',
  salePrice: 2000,
  stock: 10,
  costPrice: 1000,
);

class _ConflictingLayoutTarget implements SyncTarget {
  final processed = <String>[];
  @override
  Future<void> apply(OutboxEntry entry) async {
    if (entry.entity == SyncEntityType.layout) {
      throw const MonitorLayoutConflict();
    }
    processed.add(entry.entityId);
  }
}

void main() {
  test('respons stok terlambat tidak menimpa data terbaru', () async {
    final reads = <Completer<List<ProductRecord>>>[];
    final model = MonitorViewModel(
      loadLayout: () async => null,
      saveLayout: (l, r) async => (layout: l, revision: r + 1),
      canEdit: () => true,
      loadProducts: () {
        final read = Completer<List<ProductRecord>>();
        reads.add(read);
        return read.future;
      },
    );
    addTearDown(model.dispose);
    final older = model.refreshProducts();
    final newer = model.refreshProducts();
    reads[1].complete([product.copyWith(stock: 1)]);
    await newer;
    reads[0].complete([product.copyWith(stock: 10)]);
    await older;
    expect(model.products.single.stock, 1);
    final failed = model.refreshProducts();
    final fresh = model.refreshProducts();
    reads[3].complete([product.copyWith(stock: 2)]);
    await fresh;
    reads[2].completeError(StateError('old offline'));
    await failed;
    expect(model.products.single.stock, 2);
    expect(model.productsError, isNull);
  });

  test(
    'refresh remote identik tidak menaikkan revisi dan token tiap save unik',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final layout = MonitorTemplate.walls.create();
      final repo = MonitorLayoutRepository(
        db,
        queue: DriftSyncQueue(db),
        fetchRemote: () async => (layout: layout, token: 'server'),
      );
      await repo.refresh();
      final first = (await repo.load())!;
      await repo.refresh();
      expect((await repo.load())!.revision, first.revision);
      await repo.save(layout, expectedRevision: first.revision);
      await repo.save(layout, expectedRevision: first.revision + 1);
      final payloads = await DriftSyncQueue(db).pending();
      expect(payloads[0].payload['token'], isNot(payloads[1].payload['token']));
      expect(payloads[1].payload['baseToken'], payloads[0].payload['token']);
    },
  );
  test('banyak konflik layout tidak menghambat unggah nota POS', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final queue = DriftSyncQueue(db);
    for (var i = 0; i < 25; i++) {
      await queue.enqueue(
        OutboxEntry(
          entity: SyncEntityType.layout,
          entityId: 'main',
          operation: SyncOperation.upsert,
          payload: const {},
          createdAt: DateTime(2026),
        ),
      );
    }
    await queue.enqueue(
      OutboxEntry(
        entity: SyncEntityType.transaction,
        entityId: 'nota-baru',
        operation: SyncOperation.upsert,
        payload: const {'stockQueued': true},
        createdAt: DateTime(2026),
      ),
    );
    final target = _ConflictingLayoutTarget();
    final result = await SyncEngine(queue: queue, target: target).flush();
    expect(target.processed, ['nota-baru']);
    expect(result.failure, isNotNull);
    expect(await queue.pendingCount(), 25);
  });
  test('penempatan+layout atomik, hapus rak hanya melepas lokasi, harga/stok/nota tetap', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await DriftProductRepository(db).save(product);
    final queue = DriftSyncQueue(db);
    final repo = MonitorLayoutRepository(db, queue: queue);
    final base = MonitorTemplate.walls.create();
    final id = base.fixtures.first.id;
    final layout = base.copyWith(assignments: {'p': id});
    await repo.save(layout, expectedRevision: 0);
    final p = (await db.listProducts()).single;
    expect(p.fixtureId, id);
    expect(p.locationLabel, 'Rak 1');
    expect(p.stock, 10);
    expect(p.costPrice, 1000);
    final payload = MonitorSyncPayload((await queue.pending()).single.payload);
    expect(payload.location('p'), {'fixtureId': id, 'locationLabel': 'Rak 1'});
    expect(payload.location('p').containsKey('stock'), isFalse);
    final renamed = layout.copyWith(
      fixtures: layout.fixtures.map(
        (f) => f.id == id ? f.copyWith(name: 'Rak kopi') : f,
      ),
    );
    await repo.save(renamed, expectedRevision: 1);
    expect((await db.listProducts()).single.locationLabel, 'Rak kopi');
    final removed = renamed.copyWith(
      fixtures: renamed.fixtures.where((f) => f.id != id),
      assignments: {},
    );
    await repo.save(removed, expectedRevision: 2);
    expect((await db.listProducts()).single.fixtureId, '');
    expect((await db.listProducts()).single.stock, 10);
    expect(await db.select(db.transactions).get(), isEmpty);
    final before = (await repo.load())!.revision;
    await expectLater(
      repo.save(
        layout.copyWith(assignments: {'missing': id}),
        expectedRevision: before,
      ),
      throwsStateError,
    );
    expect((await repo.load())!.revision, before);
  });
  test(
    'cloud layout conflict dan retry token idempoten, payload rusak ditolak',
    () {
      final layout = MonitorTemplate.rows.create();
      final payload = MonitorSyncPayload({
        'layout': layout.toJson(),
        'token': 'new',
        'baseToken': 'old',
        'productIds': [],
      });
      payload.checkBase('old');
      payload.checkBase('new');
      expect(
        () => payload.checkBase('other'),
        throwsA(isA<MonitorLayoutConflict>()),
      );
      expect(
        () => MonitorSyncPayload({
          'layout': layout.toJson(),
          'token': 'bad token',
          'productIds': [],
        }),
        throwsFormatException,
      );
      expect(
        () => layout.copyWith(assignments: {'p': layout.fixtures.last.id}),
        throwsFormatException,
      );
      expect(
        () => MonitorSyncPayload({
          'layout': layout.toJson(),
          'token': 'new',
          'productIds': ['p', 'p'],
        }),
        throwsFormatException,
      );
    },
  );
  test(
    'cache produk cloud tidak menimpa lokasi pending tetapi stok tetap segar',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await DriftProductRepository(db).save(product);
      final repo = MonitorLayoutRepository(db, queue: DriftSyncQueue(db));
      final base = MonitorTemplate.walls.create();
      await repo.save(
        base.copyWith(assignments: {'p': base.fixtures.first.id}),
        expectedRevision: 0,
      );
      final cloud = CloudReadThrough(
        database: db,
        fetch: () async => CloudSnapshot(
          products: {
            'p': FirestoreSchema.productDocument(
              product.copyWith(stock: 4),
              updatedAt: DateTime(2026),
            ),
          },
          transactions: {},
        ),
      );
      addTearDown(cloud.dispose);
      await cloud.refresh();
      expect(cloud.lastError, isNull);
      final p = (await db.listProducts()).single;
      expect(p.stock, 4);
      expect(p.fixtureId, base.fixtures.first.id);
    },
  );
  test('refresh layout melindungi pending, load server tanpa echo dan error fallback', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await DriftProductRepository(db).save(product);
    var calls = 0;
    var fail = false;
    final remote = MonitorTemplate.rows.create();
    final repo = MonitorLayoutRepository(
      db,
      queue: DriftSyncQueue(db),
      fetchRemote: () async {
        calls++;
        if (fail) throw StateError('offline');
        return (
          layout: remote.copyWith(assignments: {'p': remote.fixtures.first.id}),
          token: 'remote',
        );
      },
    );
    await repo.refresh();
    expect(calls, 1);
    expect(repo.cloudError, isNull);
    expect(
      (await db.listProducts()).single.fixtureId,
      remote.fixtures.first.id,
    );
    expect(await db.select(db.syncOutboxEntries).get(), isEmpty);
    final stored = (await repo.load())!;
    await repo.save(stored.layout, expectedRevision: stored.revision);
    await repo.refresh();
    expect(calls, 1);
    await repo.refresh(discardPending: true);
    expect(calls, 2);
    expect(await db.select(db.syncOutboxEntries).get(), isEmpty);
    fail = true;
    await repo.refresh();
    expect(repo.cloudError, isNotNull);
    expect(await repo.load(), isNotNull);
  });
  test('stok alert segar tidak mengubah draft penempatan; hapus objek melepas produk', () async {
    var items = [product];
    final model = MonitorViewModel(
      loadLayout: () async => null,
      saveLayout: (l, r) async => (layout: l, revision: r + 1),
      canEdit: () => true,
      loadProducts: () async => items,
    );
    addTearDown(model.dispose);
    await model.load();
    model.chooseTemplate(MonitorTemplate.walls);
    final id = model.layout!.fixtures.first.id;
    model.select(id);
    model.assign({'p': id});
    expect(model.productsAt(id), hasLength(1));
    expect(model.counts(id).low, 0);
    items = [product.copyWith(stock: 2)];
    await model.refreshProducts();
    expect(model.counts(id).low, 1);
    expect(model.dirty, isTrue);
    items = [product.copyWith(stock: 0)];
    await model.refreshProducts();
    expect(model.counts(id).out, 1);
    model.remove();
    expect(model.layout!.assignments, isEmpty);
    expect(model.productsAt(null), hasLength(1));
    expect(model.products.single.stock, 0);
  });
  test(
    'proyeksi inverse dan hit test atap benar pada ukuran ponsel/tablet',
    () {
      final layout = MonitorTemplate.walls.create();
      for (final width in [328.0, 992.0]) {
        final p = MonitorProjection(layout, Size(width, width * .65 + 96));
        final f = layout.fixtures.first;
        final ground = p.project(4, 7);
        final inverse = p.inverse(ground);
        expect(inverse.dx, closeTo(4, 1e-6));
        expect(inverse.dy, closeTo(7, 1e-6));
        expect(
          p
              .hit(
                p.project(f.x + f.width / 2, f.y + f.height / 2, p.height(f)),
              )
              ?.id,
          f.id,
        );
        expect(p.hit(const Offset(-100, -100)), isNull);
      }
    },
  );
}
