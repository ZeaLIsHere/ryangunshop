import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ryangunshop/core/data/app_database.dart';
import 'package:ryangunshop/core/data/monitor_layout_repository.dart';
import 'package:ryangunshop/core/data/product_record.dart';
import 'package:ryangunshop/features/monitor/view/monitor_canvas.dart';
import 'package:ryangunshop/core/session/app_session.dart';
import 'package:ryangunshop/core/session/user_role.dart';
import 'package:ryangunshop/core/theme/app_theme.dart';
import 'package:ryangunshop/features/monitor/model/monitor_layout.dart';
import 'package:ryangunshop/features/monitor/view/monitor_screen.dart';
import 'package:ryangunshop/features/monitor/view_model/monitor_view_model.dart';

void main() {
  testWidgets('role berubah ketika sheet terbuka menutup sheet dan Monitor', (
    tester,
  ) async {
    final session = AppSession();
    addTearDown(session.dispose);
    final layout = MonitorTemplate.walls.create();
    final model = MonitorViewModel(
      loadLayout: () async => (layout: layout, revision: 1),
      saveLayout: (l, r) async => (layout: l, revision: r + 1),
      canEdit: () => session.role.canManageProducts,
      loadProducts: () async => [],
    );
    addTearDown(model.dispose);
    await tester.pumpWidget(
      AppSessionScope(
        session: session,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push<void>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MonitorScreen(viewModel: model),
                  ),
                ),
                child: const Text('Beranda uji'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Beranda uji'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('0 belum ditempatkan'));
    await tester.pumpAndSettle();
    expect(find.text('Belum ditempatkan'), findsOneWidget);
    session.selectRole(UserRole.cashier);
    await tester.pumpAndSettle();
    expect(find.text('Beranda uji'), findsOneWidget);
    expect(find.byType(MonitorScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('kanvas bisa dipilih, drag hanya Edit, zoom dan reset tersedia', (
    tester,
  ) async {
    var layout = MonitorLayout(
      fixtures: [
        MonitorFixture(
          id: 'rack',
          type: MonitorFixtureType.shelf,
          name: 'Rak',
          x: 5,
          y: 5,
        ),
      ],
    );
    String? selected;
    var moves = 0;
    var editing = false;
    late StateSetter rebuild;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SizedBox(
            width: 500,
            child: StatefulBuilder(
              builder: (context, setState) {
                rebuild = setState;
                return MonitorCanvas(
                  layout: layout,
                  selectedId: selected,
                  editing: editing,
                  counts: (_) => (low: 0, out: 0),
                  onSelect: (id) => selected = id,
                  onMove: (id, x, y) {
                    moves++;
                    layout = layout.copyWith(
                      fixtures: [layout.fixtures.single.copyWith(x: x, y: y)],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final canvas = find.byKey(const ValueKey('monitor-isometric-paint'));
    final size = tester.getSize(canvas);
    final projection = MonitorProjection(layout, size);
    final f = layout.fixtures.single;
    final point =
        tester.getTopLeft(canvas) +
        projection.project(
          f.x + f.width / 2,
          f.y + f.height / 2,
          projection.height(f),
        );
    await tester.tapAt(point);
    await tester.pumpAndSettle();
    expect(selected, 'rack');
    await tester.dragFrom(point, const Offset(40, 30));
    await tester.pumpAndSettle();
    expect(moves, 0);
    await tester.tap(find.text('Reset tampilan'));
    await tester.pumpAndSettle();
    rebuild(() => editing = true);
    await tester.pumpAndSettle();
    await tester.dragFrom(point, const Offset(60, 20));
    await tester.pumpAndSettle();
    expect(moves, greaterThan(0));
    await tester.tap(find.byTooltip('Perbesar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Perkecil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset tampilan'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  for (final width in [360.0, 1024.0]) {
    testWidgets('penempatan dan detail stok isometrik $width dp', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final session = AppSession();
      addTearDown(session.dispose);
      final initial = MonitorTemplate.walls.create();
      StoredMonitorLayout stored = (layout: initial, revision: 1);
      final model = MonitorViewModel(
        loadLayout: () async => stored,
        saveLayout: (layout, revision) async =>
            stored = (layout: layout, revision: revision + 1),
        canEdit: () => true,
        loadProducts: () async => [
          const ProductRecord(
            id: 'p',
            name: 'Kopi susu',
            salePrice: 2000,
            stock: 2,
            unit: 'sachet',
          ),
        ],
      );
      addTearDown(model.dispose);
      await tester.pumpWidget(
        AppSessionScope(
          session: session,
          child: MaterialApp(
            theme: AppTheme.light(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.3)),
              child: child!,
            ),
            home: MonitorScreen(viewModel: model),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(MonitorCanvas), findsOneWidget);
      await tester.tap(find.text('Edit tata letak'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('1. Rak 1'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text('1. Rak 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('1. Rak 1'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Tempatkan produk'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text('Tempatkan produk'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tempatkan produk'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kopi susu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Terapkan 1 produk'));
      await tester.pumpAndSettle();
      expect(model.layout!.assignments['p'], initial.fixtures.first.id);
      expect(model.counts(initial.fixtures.first.id).low, 1);
      await tester.scrollUntilVisible(
        find.text('Simpan'),
        -400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();
      expect(stored.layout.assignments['p'], initial.fixtures.first.id);
      await tester.ensureVisible(find.text('0 habis · 1 menipis'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('0 habis · 1 menipis'));
      await tester.pumpAndSettle();
      expect(find.text('Kopi susu'), findsOneWidget);
      expect(find.textContaining('2 sachet'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  test(
    'draft edit, batas grid, batal, retry dan konflik mempertahankan draft',
    () async {
      StoredMonitorLayout? stored;
      var fail = false;
      var owner = true;
      var conflict = false;
      final model = MonitorViewModel(
        loadLayout: () async => stored,
        saveLayout: (layout, revision) async {
          if (conflict) throw const MonitorLayoutConflict();
          if (fail) throw StateError('disk penuh');
          return stored = (layout: layout, revision: revision + 1);
        },
        canEdit: () => owner,
      );
      addTearDown(model.dispose);
      await model.load();
      model.chooseTemplate(MonitorTemplate.walls);
      expect(model.dirty, isTrue);
      model.select(model.layout!.fixtures.first.id);
      expect(model.change(dx: -2), isFalse);
      expect(model.selected!.x, 1);
      model.change(name: 'Rak baru');
      fail = true;
      expect(await model.save(), isFalse);
      expect(model.selected!.name, 'Rak baru');
      expect(model.dirty, isTrue);
      fail = false;
      expect(await model.save(), isTrue);
      expect(model.dirty, isFalse);
      model.edit();
      model.add(MonitorFixtureType.fridge);
      final count = model.layout!.fixtures.length;
      model.cancel();
      expect(model.layout!.fixtures.length, count - 1);
      model.edit();
      model.select(model.layout!.fixtures.first.id);
      model.change(name: 'Draft konflikt');
      conflict = true;
      expect(await model.save(), isFalse);
      expect(model.conflict, isTrue);
      expect(model.selected!.name, 'Draft konflikt');
      owner = false;
      expect(model.change(name: 'Dilarang'), isFalse);
      expect(await model.save(), isFalse);
      expect(stored!.layout.fixtures.first.name, 'Rak baru');
    },
  );

  test('repository membatalkan transaksi saat izin berubah', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = MonitorLayoutRepository(db);
    var checks = 0;
    await expectLater(
      repo.save(
        MonitorTemplate.rows.create(),
        expectedRevision: 0,
        canSave: () => ++checks < 2,
      ),
      throwsStateError,
    );
    expect(await repo.load(), isNull);
  });

  for (final width in [360.0, 1024.0]) {
    testWidgets('setup dan simpan editor $width dp skala 1,3', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final session = AppSession();
      addTearDown(session.dispose);
      StoredMonitorLayout? stored;
      final model = MonitorViewModel(
        loadLayout: () async => stored,
        saveLayout: (layout, revision) async =>
            stored = (layout: layout, revision: revision + 1),
        canEdit: () => session.role.canManageProducts,
      );
      addTearDown(model.dispose);
      await tester.pumpWidget(
        AppSessionScope(
          session: session,
          child: MaterialApp(
            theme: AppTheme.light(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.3)),
              child: child!,
            ),
            home: MonitorScreen(viewModel: model),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Atur tata letak toko'), findsOneWidget);
      await tester.tap(find.text('Rak dinding'));
      await tester.pumpAndSettle();
      expect(find.text('Simpan'), findsOneWidget);
      final save = find.widgetWithText(FilledButton, 'Simpan');
      expect(tester.getSize(save).height, greaterThanOrEqualTo(48));
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(find.text('Tata letak tersimpan'), findsOneWidget);
      expect(stored!.revision, 1);
      await tester.tap(find.text('Edit tata letak'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      expect(find.text('Tata letak tersimpan'), findsOneWidget);
      expect(tester.takeException(), isNull);
      session.selectRole(UserRole.cashier);
      await tester.pumpAndSettle();
      expect(find.text('Simpan'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'kembali dengan draft meminta konfirmasi dan buang tidak menyimpan',
    (tester) async {
      final session = AppSession();
      addTearDown(session.dispose);
      var writes = 0;
      final model = MonitorViewModel(
        loadLayout: () async => null,
        saveLayout: (layout, revision) async {
          writes++;
          return (layout: layout, revision: 1);
        },
        canEdit: () => session.role.canManageProducts,
      );
      addTearDown(model.dispose);
      await tester.pumpWidget(
        AppSessionScope(
          session: session,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => MonitorScreen(viewModel: model),
                    ),
                  ),
                  child: const Text('Buka Monitor'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Buka Monitor'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rak dinding'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Kembali'));
      await tester.pumpAndSettle();
      expect(find.text('Simpan perubahan?'), findsOneWidget);
      await tester.tap(find.text('Tetap edit'));
      await tester.pumpAndSettle();
      expect(model.dirty, isTrue);
      await tester.tap(find.byTooltip('Kembali'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Buang perubahan'));
      await tester.pumpAndSettle();
      expect(find.text('Buka Monitor'), findsOneWidget);
      expect(writes, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('kasir ditolak dan web tanpa database tidak mengaku menyimpan', (
    tester,
  ) async {
    final session = AppSession()..selectRole(UserRole.cashier);
    addTearDown(session.dispose);
    await tester.pumpWidget(
      AppSessionScope(
        session: session,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const MonitorScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Monitor hanya untuk pemilik.'), findsOneWidget);
    session.selectRole(UserRole.owner);
    await tester.pumpAndSettle();
    expect(find.textContaining('Editor tata letak tersedia'), findsOneWidget);
    expect(find.text('Simpan'), findsNothing);
  });
}
