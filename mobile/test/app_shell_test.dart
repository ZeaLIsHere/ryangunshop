import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ryangunshop/app/routing/app_router.dart';
import 'package:ryangunshop/app/shell/app_shell.dart';
import 'package:ryangunshop/app/shell/shell_destination.dart';
import 'package:ryangunshop/app/shell/shell_placeholder_view.dart';
import 'package:ryangunshop/core/session/app_session.dart';
import 'package:ryangunshop/core/theme/app_theme.dart';
import 'package:ryangunshop/features/catalog/view/product_catalog.dart';
import 'package:ryangunshop/features/checkout/view/cart_checkout_screen.dart';
import 'package:ryangunshop/features/dashboard/model/dashboard_shortcut.dart';

void main() {
  testWidgets('kerangka utama menampilkan navigasi bawah dan pengaturan', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(_host(const AppShell()));
    await tester.pumpAndSettle();

    final stack = tester.widget<IndexedStack>(find.byKey(AppShell.tabsKey));
    expect(stack.index, ShellDestination.floorPlan.index);

    // Denah dan Katalog tampil di navigasi bawah.
    expect(find.text(ShellDestination.floorPlan.label), findsWidgets);
    expect(find.text(ShellDestination.catalog.label), findsOneWidget);
    // Kasir menjadi tombol waterdrop di tengah.
    expect(find.byTooltip(ShellDestination.cashier.label), findsOneWidget);
    // Pengaturan pindah ke app bar paling kanan.
    expect(find.byTooltip('Pengaturan'), findsOneWidget);
  });

  testWidgets('memilih tab mengganti judul dan isi layar', (tester) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(_host(const AppShell()));
    await tester.pumpAndSettle();

    expect(_appBarTitle(ShellDestination.floorPlan.label), findsOneWidget);

    await tester.tap(find.text(ShellDestination.catalog.label));
    await tester.pumpAndSettle();

    expect(_appBarTitle(ShellDestination.catalog.label), findsOneWidget);

    final stack = tester.widget<IndexedStack>(find.byKey(AppShell.tabsKey));
    expect(stack.index, ShellDestination.catalog.index);
  });

  testWidgets('pintasan dashboard berpindah ke pengaturan', (tester) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(_host(const AppShell()));
    await tester.pumpAndSettle();

    final tile = find.text(DashboardShortcut.settings.description);
    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();
    await tester.tap(tile);
    await tester.pumpAndSettle();

    final stack = tester.widget<IndexedStack>(find.byKey(AppShell.tabsKey));
    expect(stack.index, ShellDestination.settings.index);
  });

  testWidgets('tab katalog dan tombol kasir memakai fitur aslinya', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(_host(const AppShell()));
    await tester.pumpAndSettle();

    await tester.tap(find.text(ShellDestination.catalog.label));
    await tester.pumpAndSettle();

    expect(find.byType(ProductCatalog), findsOneWidget);
    expect(find.byType(ShellPlaceholderView), findsNothing);

    await tester.tap(find.byTooltip(ShellDestination.cashier.label));
    await tester.pumpAndSettle();

    expect(find.byType(ProductCatalog), findsNothing);
    expect(find.byType(CartCheckoutScreen), findsOneWidget);
    expect(find.byType(ShellPlaceholderView), findsNothing);
  });

  testWidgets('rute yang belum terdaftar menyediakan jalan kembali', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: AppRouter.onGenerateRoute,
        initialRoute: '/belum-terdaftar',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Layar tidak ditemukan'), findsOneWidget);
    expect(find.text('Kembali ke beranda'), findsOneWidget);
  });
}

Widget _host(Widget child) {
  // Tab pengaturan membaca AppSessionScope, jadi sesi dipasang di sini juga.
  return AppSessionScope(
    session: AppSession(),
    child: MaterialApp(theme: AppTheme.light(), home: child),
  );
}

Finder _appBarTitle(String label) {
  return find.descendant(of: find.byType(AppBar), matching: find.text(label));
}

void _usePhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}
