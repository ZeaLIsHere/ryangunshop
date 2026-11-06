import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ryangunshop/core/session/app_session.dart';
import 'package:ryangunshop/core/theme/app_theme.dart';
import 'package:ryangunshop/features/scanner/view/product_scanner_screen.dart';

void main() {
  testWidgets('ProductScannerScreen menampilkan kontrol dan tombol barcode manual', (
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
          home: const ProductScannerScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.byTooltip('Input Manual'), findsOneWidget);
    expect(find.byTooltip('Nyalakan Lampu'), findsOneWidget);

    // Buka input manual barcode dialog
    await tester.tap(find.byTooltip('Input Manual'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Input Barcode Manual'), findsOneWidget);
  });
}

void _usePhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}
