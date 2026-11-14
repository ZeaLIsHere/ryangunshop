import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ryangunshop/core/session/app_session.dart';
import 'package:ryangunshop/core/theme/app_theme.dart';
import 'package:ryangunshop/features/scanner/view/product_scanner_screen.dart';

void main() {
  testWidgets('Pratinjau pemindai menyediakan pencarian manual', (
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

    expect(find.byTooltip('Cari Produk Manual'), findsOneWidget);
    expect(find.byTooltip('Nyalakan Lampu Simulasi'), findsNothing);
    expect(find.text('Kamera Android tidak tersedia'), findsOneWidget);
    expect(find.text('Data contoh'), findsNothing);

    await tester.tap(find.byTooltip('Cari Produk Manual'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Cari Produk Manual'), findsWidgets);
  });
}

void _usePhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}
