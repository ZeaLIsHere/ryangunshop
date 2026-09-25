import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ryangunshop/core/theme/app_theme.dart';
import 'package:ryangunshop/features/dashboard/model/dashboard_shortcut.dart';
import 'package:ryangunshop/features/dashboard/sample/dashboard_sample.dart';
import 'package:ryangunshop/features/dashboard/view/dashboard_screen.dart';

void main() {
  testWidgets('aksi utama memilih pintasan kasir', (tester) async {
    _usePhoneViewport(tester);

    DashboardShortcut? selected;
    await tester.pumpWidget(
      _host(DashboardScreen(onShortcutSelected: (value) => selected = value)),
    );

    await tester.tap(find.text(DashboardSample.mainActionLabel));

    expect(selected, DashboardShortcut.cashier);
  });

  testWidgets('setiap pintasan melaporkan pilihannya', (tester) async {
    _usePhoneViewport(tester);

    final selected = <DashboardShortcut>[];
    await tester.pumpWidget(
      _host(DashboardScreen(onShortcutSelected: selected.add)),
    );

    for (final shortcut in DashboardShortcut.values) {
      final tile = find.text(shortcut.description);
      await tester.ensureVisible(tile);
      await tester.pumpAndSettle();
      await tester.tap(tile);
      await tester.pump();
    }

    expect(selected, DashboardShortcut.values);
  });
}

Widget _host(Widget child) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(body: child),
  );
}

void _usePhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}
