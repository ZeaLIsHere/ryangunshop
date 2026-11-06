import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ryangunshop/core/session/app_session.dart';
import 'package:ryangunshop/core/theme/app_theme.dart';
import 'package:ryangunshop/features/floor_plan/view/fixture_product_sheet.dart';
import 'package:ryangunshop/features/floor_plan/view/fixture_tile.dart';
import 'package:ryangunshop/features/floor_plan/sample/floor_plan_sample.dart';
import 'package:ryangunshop/features/floor_plan/view/mode_switch.dart';
import 'package:ryangunshop/features/floor_plan/view/store_floor_plan.dart';
import 'package:ryangunshop/features/floor_plan/view/sync_pill.dart';
import 'package:ryangunshop/features/floor_plan/view_model/floor_plan_view_model.dart';

void main() {
  testWidgets('StoreFloorPlan merender objek warung dan kontrol navigasi', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    final session = AppSession();
    addTearDown(session.dispose);

    await tester.pumpWidget(
      AppSessionScope(
        session: session,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: StoreFloorPlan()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ModeSwitch), findsOneWidget);
    expect(find.byType(SyncPill), findsOneWidget);
    expect(find.byType(FixtureTile), findsWidgets);
    expect(find.text('PINTU MASUK'), findsOneWidget);
  });

  testWidgets('Mengetuk fixture membuka FixtureProductSheet', (tester) async {
    _usePhoneViewport(tester);
    final session = AppSession();
    addTearDown(session.dispose);

    await tester.pumpWidget(
      AppSessionScope(
        session: session,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: StoreFloorPlan()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final fixtureTile = find.text('Rak Sembako A');
    await tester.tap(fixtureTile);
    await tester.pumpAndSettle();

    expect(find.byType(FixtureProductSheet), findsOneWidget);
  });

  testWidgets('Pemilik dapat mengaktifkan mode edit denah', (tester) async {
    _usePhoneViewport(tester);
    final session = AppSession(); // default role is owner
    addTearDown(session.dispose);

    final vm = FloorPlanViewModel();
    addTearDown(vm.dispose);

    await tester.pumpWidget(
      AppSessionScope(
        session: session,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(body: StoreFloorPlan(viewModel: vm)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(vm.isEditMode, isFalse);

    final editButton = find.byTooltip('Edit Denah');
    expect(editButton, findsOneWidget);
    await tester.tap(editButton);
    await tester.pumpAndSettle();

    expect(vm.isEditMode, isTrue);
    expect(find.byTooltip('Tambah Objek'), findsOneWidget);
  });

  testWidgets('mode edit menampilkan kontrol ukuran dan duplikat', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    final session = AppSession();
    addTearDown(session.dispose);

    final vm = FloorPlanViewModel();
    addTearDown(vm.dispose);
    vm.setEditMode(true);
    vm.selectFixture(vm.fixtures.first.id);

    await tester.pumpWidget(
      AppSessionScope(
        session: session,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(body: StoreFloorPlan(viewModel: vm)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Perbesar Objek'), findsOneWidget);
    expect(find.byTooltip('Perkecil Objek'), findsOneWidget);
    expect(find.byTooltip('Duplikat Objek'), findsOneWidget);

    await tester.tap(find.byTooltip('Duplikat Objek'));
    await tester.pumpAndSettle();

    expect(vm.fixtures.length, FloorPlanSample.defaultFixtures.length + 1);
    expect(vm.selectedFixture?.name, contains('(salinan)'));
  });

  test('mengubah ukuran objek dibatasi ukuran minimum dan batas kanvas', () {
    final vm = FloorPlanViewModel();
    addTearDown(vm.dispose);

    final id = vm.fixtures.first.id;
    final before = vm.fixtures.first.width;
    vm.resizeFixture(id, delta: 0.05);
    expect(vm.fixtures.first.width, greaterThan(before));

    for (var i = 0; i < 50; i++) {
      vm.resizeFixture(id, delta: 0.5);
    }
    final enlarged = vm.fixtures.firstWhere((f) => f.id == id);
    expect(enlarged.width, lessThanOrEqualTo(1.0 - enlarged.x + 1e-9));

    for (var i = 0; i < 50; i++) {
      vm.resizeFixture(id, delta: -0.5);
    }
    final shrunk = vm.fixtures.firstWhere((f) => f.id == id);
    expect(shrunk.width, greaterThanOrEqualTo(0.1));
    expect(shrunk.height, greaterThanOrEqualTo(0.08));
  });

  test('menduplikasi objek menambah salinan yang terpilih', () {
    final vm = FloorPlanViewModel();
    addTearDown(vm.dispose);

    final original = vm.fixtures.first;
    final countBefore = vm.fixtures.length;

    vm.duplicateFixture(original.id);

    expect(vm.fixtures.length, countBefore + 1);
    expect(vm.selectedFixture?.id, isNot(original.id));
    expect(vm.selectedFixture?.name, '${original.name} (salinan)');
  });
}

void _usePhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}
