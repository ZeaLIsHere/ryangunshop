import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ryangunshop/core/theme/app_theme.dart';
import 'package:ryangunshop/core/widgets/brand_spinner.dart';
import 'package:ryangunshop/features/catalog/model/catalog_scenario.dart';
import 'package:ryangunshop/features/catalog/view/product_catalog.dart';

void main() {
  testWidgets('katalog terbaca pada 360 dp dan skala teks 1,3', (tester) async {
    await _showCatalog(tester);

    expect(find.text('5 produk contoh'), findsOneWidget);
    expect(find.text('Beras pandan wangi 1 kg'), findsOneWidget);
    expect(find.text('Rp 16.000 / bungkus'), findsOneWidget);
    expect(find.text('Stok contoh: 12 bungkus'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Air mineral 600 ml'), 200);
    expect(find.text('Menipis (contoh): 5 botol'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('katalog kosong menyediakan tindakan pemulihan', (tester) async {
    await _showCatalog(tester);
    await _select(tester, CatalogScenario.empty);
    expect(find.text('Belum ada produk'), findsOneWidget);
    expect(find.text('5 produk contoh'), findsNothing);

    await tester.tap(find.text('Tampilkan contoh'));
    await tester.pumpAndSettle();
    expect(find.text('5 produk contoh'), findsOneWidget);
    expect(find.text('Daftar contoh'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('coba lagi memulihkan skenario gagal', (tester) async {
    await _showCatalog(tester);
    await _select(tester, CatalogScenario.failure);
    expect(find.text('Katalog contoh gagal dimuat'), findsOneWidget);

    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    expect(find.text('5 produk contoh'), findsOneWidget);
    expect(find.text('Daftar contoh'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('offline tetap menampilkan produk dengan penanda simulasi', (
    tester,
  ) async {
    await _showCatalog(tester);
    await _select(tester, CatalogScenario.offline);
    expect(find.text('Offline · simulasi'), findsOneWidget);
    expect(find.text('5 produk contoh'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Beras pandan wangi 1 kg'), 200);
    expect(find.text('Rp 16.000 / bungkus'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('memuat bisa dicoba dan dihentikan tanpa menunggu layanan', (
    tester,
  ) async {
    await _showCatalog(tester);
    await _select(tester, CatalogScenario.loading, settle: false);
    expect(find.byType(BrandSpinner), findsOneWidget);
    await tester.tap(find.text('Tampilkan contoh'));
    await tester.pumpAndSettle();
    expect(find.byType(BrandSpinner), findsNothing);
    expect(find.text('5 produk contoh'), findsOneWidget);
  });

  testWidgets('reduced motion tidak memutar spinner', (tester) async {
    await _showCatalog(tester, disableAnimations: true);
    await _select(tester, CatalogScenario.loading);
    expect(find.text('Memuat katalog contoh'), findsOneWidget);
    expect(find.byType(BrandSpinner), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('kontrol katalog memenuhi target sentuh Android', (tester) async {
    await _showCatalog(tester);
    await _select(tester, CatalogScenario.empty);
    final semantics = tester.ensureSemantics();
    try {
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    } finally {
      semantics.dispose();
    }
  });
}

Future<void> _showCatalog(
  WidgetTester tester, {
  bool disableAnimations = false,
}) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: const TextScaler.linear(1.3),
          disableAnimations: disableAnimations,
        ),
        child: child!,
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('Produk')),
        body: const SafeArea(child: ProductCatalog()),
      ),
    ),
  );
}

Future<void> _select(
  WidgetTester tester,
  CatalogScenario scenario, {
  bool settle = true,
}) async {
  await tester.tap(find.byType(DropdownButtonFormField<CatalogScenario>));
  await tester.pumpAndSettle();
  await tester.tap(find.text(scenario.label).last);
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }
}
