import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ryangunshop/core/session/app_session.dart';
import 'package:ryangunshop/core/theme/app_theme.dart';
import 'package:ryangunshop/features/scanner/model/scanner_scenario.dart';
import 'package:ryangunshop/features/scanner/view/product_scanner_screen.dart';
import 'package:ryangunshop/features/scanner/view_model/scanner_view_model.dart';

void main() {
  testWidgets(
    'simulasi perlu tindakan dan konfirmasi sebelum masuk keranjang',
    (tester) async {
      final session = AppSession();
      final viewModel = ScannerViewModel();
      addTearDown(session.dispose);
      addTearDown(viewModel.dispose);
      await _showScanner(tester, session: session, viewModel: viewModel);

      final initialItems = session.cart.totalItems;
      await tester.pump(const Duration(seconds: 1));
      expect(viewModel.scenario, ScannerScenario.ready);
      expect(session.cart.totalItems, initialItems);

      await tester.tap(find.byTooltip('Nyalakan Lampu Simulasi'));
      await tester.pumpAndSettle();
      expect(find.text('Lampu simulasi aktif'), findsOneWidget);

      await tester.tap(find.text('Coba Pindai Contoh'));
      await tester.pump();
      expect(find.text('Mencari produk contoh'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pumpAndSettle();
      expect(find.text('Hasil simulasi'), findsOneWidget);
      expect(find.text('Keyakinan simulasi: 92%'), findsOneWidget);
      expect(session.cart.totalItems, initialItems);

      await tester.tap(find.text('Konfirmasi ke Keranjang'));
      await tester.pumpAndSettle();
      expect(session.cart.totalItems, initialItems + 1);
      expect(find.text('Produk contoh masuk keranjang'), findsOneWidget);

      await tester.tap(find.text('Pindai Lagi'));
      await tester.pumpAndSettle();
      expect(viewModel.scenario, ScannerScenario.ready);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('izin ditolak tetap memberi pencarian manual tanpa hasil palsu', (
    tester,
  ) async {
    final session = AppSession();
    final viewModel = ScannerViewModel();
    addTearDown(session.dispose);
    addTearDown(viewModel.dispose);
    await _showScanner(tester, session: session, viewModel: viewModel);

    viewModel.selectScenario(ScannerScenario.permissionDenied);
    await tester.pumpAndSettle();
    expect(find.text('Izin kamera belum tersedia'), findsOneWidget);
    await tester.tap(find.text('Cari Produk Manual'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'tidak-ada-produk');
    await tester.pumpAndSettle();
    expect(find.text('Produk tidak ditemukan'), findsOneWidget);
    expect(viewModel.detectedProduct, isNull);

    await tester.enterText(find.byType(TextField), 'contoh-002');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Minyak goreng 1 liter'));
    await tester.pumpAndSettle();
    expect(find.text('Dipilih manual'), findsOneWidget);
    expect(viewModel.confidence, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('state error dan offline dapat dicoba pada layar sempit', (
    tester,
  ) async {
    final session = AppSession();
    final viewModel = ScannerViewModel();
    addTearDown(session.dispose);
    addTearDown(viewModel.dispose);
    await _showScanner(tester, session: session, viewModel: viewModel);

    await tester.tap(find.byTooltip('Pilih Skenario Contoh'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kamera gagal'));
    await tester.pumpAndSettle();
    expect(find.text('Pratinjau kamera gagal'), findsOneWidget);

    await tester.tap(find.byTooltip('Pilih Skenario Contoh'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mode offline'));
    await tester.pumpAndSettle();
    expect(find.text('Mode offline contoh'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('kontrol pemindai memenuhi target sentuh Android', (
    tester,
  ) async {
    final session = AppSession();
    final viewModel = ScannerViewModel();
    addTearDown(session.dispose);
    addTearDown(viewModel.dispose);
    await _showScanner(tester, session: session, viewModel: viewModel);

    final semantics = tester.ensureSemantics();
    try {
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    } finally {
      semantics.dispose();
    }
  });
}

Future<void> _showScanner(
  WidgetTester tester, {
  required AppSession session,
  required ScannerViewModel viewModel,
}) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    AppSessionScope(
      session: session,
      child: MaterialApp(
        theme: AppTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!,
        ),
        home: ProductScannerScreen(viewModel: viewModel),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
