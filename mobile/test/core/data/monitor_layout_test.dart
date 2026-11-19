import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ryangunshop/core/data/app_database.dart';
import 'package:ryangunshop/core/data/monitor_layout_repository.dart';
import 'package:ryangunshop/features/monitor/model/monitor_layout.dart';

MonitorFixture shelf({String id = 'a', int x = 0, int y = 0, int turns = 0}) =>
    MonitorFixture(
      id: id,
      type: MonitorFixtureType.shelf,
      name: 'Rak',
      x: x,
      y: y,
      quarterTurns: turns,
    );

void main() {
  test('tiga template deterministik, valid, immutable dan round-trip', () {
    for (final template in MonitorTemplate.values) {
      final layout = template.create();
      expect(layout.fixtures, isNotEmpty);
      expect(
        layout.fixtures.map((f) => f.type),
        containsAll(MonitorFixtureType.values),
      );
      final encoded = jsonEncode(layout.toJson());
      expect(jsonEncode(template.create().toJson()), encoded);
      expect(
        jsonEncode(MonitorLayout.fromJson(jsonDecode(encoded)).toJson()),
        encoded,
      );
      expect(() => layout.fixtures.clear(), throwsUnsupportedError);
    }
    final input = [shelf()];
    final layout = MonitorLayout(fixtures: input);
    input.clear();
    expect(layout.fixtures, hasLength(1));
  });

  test('rotasi footprint, overlap, batas dan ID berulang', () {
    final rotated = shelf(x: 3, y: 1, turns: 1);
    expect(rotated.width, 1);
    expect(rotated.height, 3);
    expect(
      MonitorLayout(gridWidth: 4, gridHeight: 4, fixtures: [rotated]),
      isNotNull,
    );
    expect(
      () => MonitorLayout(
        gridWidth: 4,
        gridHeight: 4,
        fixtures: [rotated.copyWith(y: 2)],
      ),
      throwsFormatException,
    );
    expect(
      () => MonitorLayout(
        fixtures: [
          shelf(),
          shelf(id: 'b', x: 2),
        ],
      ),
      throwsFormatException,
    );
    expect(
      () => MonitorLayout(fixtures: [shelf(), shelf(x: 5)]),
      throwsFormatException,
    );
    expect(
      MonitorLayout(
        fixtures: [
          shelf(),
          shelf(id: 'b', x: 3),
        ],
      ).fixtures,
      hasLength(2),
    );
  });

  test('payload salah tidak disetel ulang diam-diam', () {
    final data = MonitorTemplate.walls.create().toJson();
    expect(
      () => MonitorLayout.fromJson({...data, 'schemaVersion': 2}),
      throwsA(isA<UnsupportedMonitorLayoutVersion>()),
    );
    for (final changed in [
      {...data, 'schemaVersion': 1.0},
      {...data, 'id': 'lain'},
      {...data, 'gridWidth': -1},
      {...data, 'gridHeight': 65},
      {...data, 'fixtures': 'invalid'},
      {...data, 'unknown': true},
    ]) {
      expect(() => MonitorLayout.fromJson(changed), throwsFormatException);
    }
    expect(() => shelf(x: -1), throwsFormatException);
    expect(() => shelf(turns: 4), throwsFormatException);
    expect(
      () => MonitorFixture(
        id: 'bad/id',
        type: MonitorFixtureType.shelf,
        name: 'Rak',
        x: 0,
        y: 0,
      ),
      throwsFormatException,
    );
    expect(() => shelf().copyWith(name: '  '), throwsFormatException);
    expect(() => shelf().copyWith(name: 'Rak\nbaru'), throwsFormatException);
    expect(
      () => MonitorFixture.fromJson({...shelf().toJson(), 'type': 'robot'}),
      throwsFormatException,
    );
  });

  test('repository kosong, simpan, revisi konflik dan rollback', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = MonitorLayoutRepository(db);
    expect(await repo.load(), isNull);
    final first = await repo.save(
      MonitorTemplate.walls.create(),
      expectedRevision: 0,
    );
    expect(first.revision, 1);
    final edited = first.layout.copyWith(
      fixtures: [
        ...first.layout.fixtures.skip(1),
        first.layout.fixtures.first.copyWith(name: 'Rak baru'),
      ],
    );
    final results = await Future.wait([
      repo
          .save(edited, expectedRevision: 1)
          .then<Object>((v) => v, onError: (Object e) => e),
      repo
          .save(edited, expectedRevision: 1)
          .then<Object>((v) => v, onError: (Object e) => e),
    ]);
    expect(results.whereType<MonitorLayoutConflict>(), hasLength(1));
    expect((await repo.load())!.revision, 2);
    await expectLater(
      repo.save(first.layout, expectedRevision: 0),
      throwsA(isA<MonitorLayoutConflict>()),
    );
    expect((await repo.load())!.revision, 2);
  });

  test(
    'layout tidak menyentuh POS dan tidak melepas lokasi terpakai',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = MonitorLayoutRepository(db);
      final layout = MonitorTemplate.walls.create();
      final fixture = layout.fixtures.first;
      await db.saveProduct(
        ProductsCompanion.insert(
          id: 'p',
          name: 'Produk',
          salePrice: 1000,
          stock: 10,
          fixtureId: Value(fixture.id),
          updatedAt: DateTime(2026, 11, 19),
        ),
      );
      await db
          .into(db.cartDrafts)
          .insert(
            CartDraftsCompanion.insert(
              id: const Value(1),
              discount: 0,
              note: 'Tetap',
            ),
          );
      await db.completeCheckout(
        transactionId: 'nota',
        paymentMethod: 'cash',
        totalAmount: 1000,
        cashReceived: 1000,
        changeAmount: 0,
        clearCartDraft: false,
        lines: const [
          CheckoutLine(
            productId: 'p',
            quantity: 1,
            unitPrice: 1000,
            subtotal: 1000,
          ),
        ],
      );
      await repo.save(layout, expectedRevision: 0);
      await expectLater(
        repo.save(
          layout.copyWith(fixtures: layout.fixtures.skip(1)),
          expectedRevision: 1,
        ),
        throwsStateError,
      );
      expect((await repo.load())!.revision, 1);
      expect((await db.listProducts()).single.stock, 9);
      expect((await db.listProducts()).single.fixtureId, fixture.id);
      expect((await db.select(db.transactions).get()).single.id, 'nota');
      expect((await db.select(db.cartDrafts).get()).single.note, 'Tetap');
      expect(await db.select(db.syncOutboxEntries).get(), isEmpty);
    },
  );

  test(
    'layout tersimpan tahan reopen dan migrasi 6 ke 7 menjaga data',
    () async {
      final dir = await Directory.systemTemp.createTemp('monitor-test-');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/store.sqlite');
      var db = AppDatabase(NativeDatabase(file));
      await db.saveProduct(
        ProductsCompanion.insert(
          id: 'lama',
          name: 'Produk lama',
          stock: 7,
          salePrice: 1000,
          updatedAt: DateTime(2026),
        ),
      );
      // Simulasikan skema 6: seluruh tabel POS sama, tanpa tabel Monitor.
      await db.customStatement('DROP TABLE monitor_layouts');
      await db.customStatement('PRAGMA user_version = 6');
      await db.close();
      db = AppDatabase(NativeDatabase(file));
      expect((await db.listProducts()).single.stock, 7);
      expect(await MonitorLayoutRepository(db).load(), isNull);
      final layout = MonitorTemplate.rows.create();
      await MonitorLayoutRepository(db).save(layout, expectedRevision: 0);
      await db.close();
      db = AppDatabase(NativeDatabase(file));
      try {
        final stored = (await MonitorLayoutRepository(db).load())!;
        expect(stored.revision, 1);
        expect(stored.layout.toJson(), layout.toJson());
        expect((await db.listProducts()).single.stock, 7);
        expect(
          (await db.customSelect('PRAGMA user_version').getSingle()).read<int>(
            'user_version',
          ),
          7,
        );
      } finally {
        await db.close();
      }
    },
  );

  test('payload/revisi rusak ditolak tanpa reset atau overwrite', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = MonitorLayoutRepository(db);
    await db
        .into(db.monitorLayouts)
        .insert(
          MonitorLayoutsCompanion.insert(
            id: 'main',
            payload: '{invalid',
            revision: 1,
          ),
        );
    await expectLater(repo.load(), throwsFormatException);
    await expectLater(
      repo.save(MonitorLayout(), expectedRevision: 1),
      throwsFormatException,
    );
    expect(
      (await db.select(db.monitorLayouts).get()).single.payload,
      '{invalid',
    );
    await db.customStatement(
      'UPDATE monitor_layouts SET payload = ?, revision = 0',
      [jsonEncode(MonitorLayout().toJson())],
    );
    await expectLater(repo.load(), throwsFormatException);
  });
}
