import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ryangunshop/app/routing/app_router.dart';
import 'package:ryangunshop/app/shell/app_shell.dart';
import 'package:ryangunshop/app/shell/shell_destination.dart';
import 'package:ryangunshop/app/shell/shell_placeholder_view.dart';
import 'package:ryangunshop/core/session/app_session.dart';
import 'package:ryangunshop/core/session/user_role.dart';
import 'package:ryangunshop/core/theme/app_theme.dart';
import 'package:ryangunshop/features/catalog/view/product_catalog.dart';
import 'package:ryangunshop/features/checkout/view/cart_checkout_screen.dart';
import 'package:ryangunshop/features/chatbot/view/chatbot_screen.dart';
import 'package:ryangunshop/features/statistics/view/statistics_screen.dart';

void main() {
  for (final width in [360.0, 1024.0]) {
    testWidgets(
      'lima navigasi berurutan, target dan state aktif pada $width dp skala 1,3',
      (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final session = AppSession();
        addTearDown(session.dispose);
        await tester.pumpWidget(
          AppSessionScope(
            session: session,
            child: MaterialApp(
              theme: AppTheme.light(),
              onGenerateRoute: AppRouter.onGenerateRoute,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(1.3)),
                child: child!,
              ),
              home: const AppShell(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final semantics = tester.ensureSemantics();
        try {
          double previous = -1;
          for (final label in [
            'Beranda',
            'Chatbot',
            'Kasir',
            'Produk',
            'Statistik',
          ]) {
            final button = find.byTooltip(label);
            expect(button, findsOneWidget);
            final size = tester.getSize(button);
            expect(size.width, greaterThanOrEqualTo(48));
            expect(size.height, greaterThanOrEqualTo(48));
            final x = tester.getCenter(button).dx;
            expect(x, greaterThan(previous));
            previous = x;
          }
          expect(
            tester.getCenter(find.byTooltip('Kasir')).dx,
            closeTo(width / 2, 0.1),
          );
          expect(
            tester.getTopLeft(find.byTooltip('Kasir')).dy,
            lessThan(tester.getTopLeft(find.byTooltip('Beranda')).dy),
          );
          expect(
            tester
                .getSemantics(find.byTooltip('Beranda'))
                .flagsCollection
                .isSelected,
            Tristate.isTrue,
          );
          await tester.tap(find.byTooltip('Produk'));
          await tester.pumpAndSettle();
          expect(find.byType(ProductCatalog), findsOneWidget);
          expect(
            tester
                .getSemantics(find.byTooltip('Produk'))
                .flagsCollection
                .isSelected,
            Tristate.isTrue,
          );
          await tester.tap(find.byTooltip('Chatbot'));
          await tester.pumpAndSettle();
          expect(find.byType(ChatbotScreen), findsOneWidget);
          await tester.pageBack();
          await tester.pumpAndSettle();
          expect(find.byType(ProductCatalog), findsOneWidget);
          await tester.tap(find.byTooltip('Statistik'));
          await tester.pumpAndSettle();
          expect(find.byType(StatisticsScreen), findsOneWidget);
          await tester.pageBack();
          await tester.pumpAndSettle();
          await tester.tap(find.byTooltip('Pengaturan'));
          await tester.pumpAndSettle();
          expect(
            tester.widget<IndexedStack>(find.byKey(AppShell.tabsKey)).index,
            ShellDestination.settings.index,
          );
          expect(tester.takeException(), isNull);
        } finally {
          semantics.dispose();
        }
      },
    );
  }

  testWidgets('Statistik dari nav kasir tetap riwayat tanpa laporan pemilik', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    final session = AppSession()..selectRole(UserRole.cashier);
    addTearDown(session.dispose);
    await tester.pumpWidget(
      AppSessionScope(
        session: session,
        child: MaterialApp(
          theme: AppTheme.light(),
          onGenerateRoute: AppRouter.onGenerateRoute,
          home: const AppShell(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Statistik'));
    await tester.pumpAndSettle();
    expect(find.text('Riwayat Nota'), findsOneWidget);
    expect(find.byType(StatisticsScreen), findsNothing);
    expect(find.text('Ringkasan harian'), findsNothing);
    expect(find.text('Bagikan PDF'), findsNothing);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byTooltip('Pengaturan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
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

  testWidgets('tombol pengaturan tetap dapat diakses dari beranda', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(_host(const AppShell()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Pengaturan'));
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

  testWidgets('rute laporan dan statistik kasir hanya membuka riwayat', (
    tester,
  ) async {
    final session = AppSession()..selectRole(UserRole.cashier);
    addTearDown(session.dispose);
    for (final route in [AppRoutes.reports, AppRoutes.statistics]) {
      await tester.pumpWidget(
        AppSessionScope(
          session: session,
          child: MaterialApp(home: AppRouter.pageFor(route)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Riwayat Nota'), findsOneWidget);
      expect(find.text('Ringkasan harian'), findsNothing);
      expect(find.text('Bagikan PDF'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    }
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
