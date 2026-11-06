import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ryangunshop/core/session/app_session.dart';
import 'package:ryangunshop/core/theme/app_theme.dart';
import 'package:ryangunshop/core/widgets/primary_action.dart';
import 'package:ryangunshop/features/floor_plan/sample/floor_plan_sample.dart';
import 'package:ryangunshop/features/floor_plan/view/fixture_tile.dart';
import 'package:ryangunshop/features/floor_plan/view/mode_switch.dart';
import 'package:ryangunshop/features/floor_plan/view/store_floor_plan.dart';
import 'package:ryangunshop/features/checkout/view/cart_checkout_screen.dart';

void main() {
  group('Audit Aksesibilitas RyanGunshop', () {
    testWidgets('Target sentuh PrimaryAction memenuhi batas minimum 48 dp', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Center(
              child: PrimaryAction(
                label: 'Tindakan Utama',
                onPressed: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final size = tester.getSize(find.byType(PrimaryAction));
      expect(size.height, greaterThanOrEqualTo(48.0));
      expect(size.width, greaterThanOrEqualTo(48.0));
    });

    testWidgets('ModeSwitch memiliki target sentuh dan opsi mode denah', (
      tester,
    ) async {
      ViewMode current = ViewMode.floorPlan2D;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Center(
              child: ModeSwitch(
                currentMode: current,
                onModeChanged: (mode) => current = mode,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ModeSwitch), findsOneWidget);
      expect(find.text('Denah 2D'), findsOneWidget);
      expect(find.text('360° Zona'), findsOneWidget);

      await tester.tap(find.text('360° Zona'));
      await tester.pumpAndSettle();
      expect(current, ViewMode.panorama360);
    });

    testWidgets(
      'StoreFloorPlan aman pada viewport sempit 360 dp dan text scale 1.3',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final session = AppSession();
        addTearDown(session.dispose);

        await tester.pumpWidget(
          AppSessionScope(
            session: session,
            child: MaterialApp(
              theme: AppTheme.light(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(1.3),
                ),
                child: child!,
              ),
              home: const Scaffold(
                body: StoreFloorPlan(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(StoreFloorPlan), findsOneWidget);
        expect(find.byType(FixtureTile), findsWidgets);
      },
    );

    testWidgets(
      'FixtureTile menyertakan informasi semantik lengkap untuk TalkBack',
      (tester) async {
        final fixture = FloorPlanSample.defaultFixtures.firstWhere(
          (f) => f.productCount > 0,
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 120,
                  height: 100,
                  child: FixtureTile(
                    fixture: fixture,
                    isSelected: false,
                    isHighlighted: false,
                    isEditMode: false,
                    onTap: () {},
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final semantics = tester.getSemantics(find.byType(FixtureTile));
        expect(semantics.label, contains(fixture.name));
        expect(semantics.label, contains('${fixture.productCount} produk'));
      },
    );

    testWidgets(
      'CartCheckoutScreen bebas overflow pada viewport 360 dp dan skala 1.3',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final session = AppSession();
        addTearDown(session.dispose);

        await tester.pumpWidget(
          AppSessionScope(
            session: session,
            child: MaterialApp(
              theme: AppTheme.light(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(1.3),
                ),
                child: child!,
              ),
              home: const Scaffold(
                body: CartCheckoutScreen(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Transaksi Kasir'), findsOneWidget);
      },
    );
  });
}
