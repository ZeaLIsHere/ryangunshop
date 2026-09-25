import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ryangunshop/app/routing/app_router.dart';
import 'package:ryangunshop/app/shell/app_shell.dart';
import 'package:ryangunshop/app/shell/shell_destination.dart';
import 'package:ryangunshop/core/session/app_session.dart';
import 'package:ryangunshop/core/theme/app_theme.dart';
import 'package:ryangunshop/features/dashboard/model/dashboard_shortcut.dart';

void main() {
  testWidgets('kerangka utama menampilkan empat tab', (tester) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(_host(const AppShell()));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);

    final navigationBar = tester.widget<NavigationBar>(
      find.byType(NavigationBar),
    );
    expect(navigationBar.destinations.length, ShellDestination.values.length);
    expect(navigationBar.selectedIndex, ShellDestination.floorPlan.index);
  });

  testWidgets('memilih tab mengganti judul dan isi layar', (tester) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(_host(const AppShell()));
    await tester.pumpAndSettle();

    expect(_appBarTitle(ShellDestination.floorPlan.label), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(ShellDestination.catalog.label),
      ),
    );
    await tester.pumpAndSettle();

    expect(_appBarTitle(ShellDestination.catalog.label), findsOneWidget);
    expect(_appBarTitle(ShellDestination.floorPlan.label), findsNothing);

    final stack = tester.widget<IndexedStack>(find.byType(IndexedStack));
    expect(stack.index, ShellDestination.catalog.index);
  });

  testWidgets('pintasan dashboard memindahkan tab', (tester) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(_host(const AppShell()));
    await tester.pumpAndSettle();

    final tile = find.text(DashboardShortcut.settings.description);
    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();
    await tester.tap(tile);
    await tester.pumpAndSettle();

    final navigationBar = tester.widget<NavigationBar>(
      find.byType(NavigationBar),
    );
    expect(navigationBar.selectedIndex, ShellDestination.settings.index);
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
    expect(find.text('Kembali ke denah'), findsOneWidget);
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
