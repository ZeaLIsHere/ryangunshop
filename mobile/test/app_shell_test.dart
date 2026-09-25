import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ryangunshop/app/app.dart';
import 'package:ryangunshop/app/routing/app_router.dart';
import 'package:ryangunshop/app/shell/shell_destination.dart';

void main() {
  testWidgets('aplikasi membuka kerangka utama dengan empat tab', (
    tester,
  ) async {
    await tester.pumpWidget(const RyanGunshopApp());
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);

    final navigationBar = tester.widget<NavigationBar>(
      find.byType(NavigationBar),
    );
    expect(navigationBar.destinations.length, ShellDestination.values.length);
    expect(navigationBar.selectedIndex, ShellDestination.floorPlan.index);
  });

  testWidgets('memilih tab mengganti judul dan isi layar', (tester) async {
    await tester.pumpWidget(const RyanGunshopApp());
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

Finder _appBarTitle(String label) {
  return find.descendant(of: find.byType(AppBar), matching: find.text(label));
}
