import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ryangunshop/core/theme/app_theme.dart';
import 'package:ryangunshop/features/catalog/model/catalog_product.dart';
import 'package:ryangunshop/features/catalog/sample/catalog_sample.dart';
import 'package:ryangunshop/features/catalog/view/product_form_screen.dart';

void main() {
  testWidgets('form tambah memvalidasi lalu mengembalikan produk contoh', (
    tester,
  ) async {
    CatalogProduct? saved;
    await _showForm(tester, onSaved: (product) => saved = product);

    expect(find.text('Pratinjau data contoh'), findsOneWidget);
    await tester.tap(find.text('Simpan Produk'));
    await tester.pumpAndSettle();
    expect(find.text('Nama produk wajib diisi'), findsOneWidget);
    expect(find.text('Harga jual wajib diisi'), findsOneWidget);
    expect(find.text('Stok wajib diisi'), findsOneWidget);
    expect(saved, isNull);

    await _enter(tester, 'Nama Produk *', 'Gula pasir 1 kg');
    await _enter(tester, 'Harga Jual *', '17500');
    await _enter(tester, 'Stok Saat Ini *', '0');
    await tester.ensureVisible(find.text('Gunakan pratinjau contoh'));
    await tester.tap(find.text('Gunakan pratinjau contoh'));
    await tester.pumpAndSettle();
    expect(find.text('Pratinjau foto contoh aktif'), findsOneWidget);

    await tester.tap(find.text('Simpan Produk'));
    await tester.pumpAndSettle();
    expect(saved?.name, 'Gula pasir 1 kg');
    expect(saved?.price, 17500);
    expect(saved?.stock, 0);
    expect(saved?.hasSamplePhoto, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'form edit menolak barcode produk lain tetapi menerima miliknya',
    (tester) async {
      CatalogProduct? saved;
      final original = CatalogSample.products.first;
      await _showForm(
        tester,
        initialProduct: original,
        existingProducts: CatalogSample.products,
        onSaved: (product) => saved = product,
      );

      await _enter(tester, 'Barcode / SKU (Opsional)', 'contoh-002');
      await tester.tap(find.text('Simpan Perubahan'));
      await tester.pumpAndSettle();
      expect(find.text('Barcode sudah dipakai produk lain'), findsOneWidget);
      expect(saved, isNull);

      await _enter(tester, 'Barcode / SKU (Opsional)', 'CONTOH-001');
      await tester.tap(find.text('Simpan Perubahan'));
      await tester.pumpAndSettle();
      expect(saved?.id, original.id);
      expect(saved?.barcode, original.barcode);
      expect(saved?.costPrice, original.costPrice);
      expect(tester.takeException(), isNull);
    },
  );
}

Finder _field(String label) => find.ancestor(
  of: find.text(label),
  matching: find.byType(TextFormField),
);

Future<void> _enter(WidgetTester tester, String label, String value) async {
  final field = _field(label);
  await tester.ensureVisible(field);
  await tester.pumpAndSettle();
  await tester.enterText(field, value);
  await tester.pump();
}

Future<void> _showForm(
  WidgetTester tester, {
  CatalogProduct? initialProduct,
  List<CatalogProduct> existingProducts = const [],
  ValueChanged<CatalogProduct>? onSaved,
}) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: const TextScaler.linear(1.3)),
        child: child!,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () async {
                final result = await Navigator.of(context).push<CatalogProduct>(
                  MaterialPageRoute(
                    builder: (_) => ProductFormScreen(
                      initialProduct: initialProduct,
                      existingProducts: existingProducts,
                    ),
                  ),
                );
                if (result != null) onSaved?.call(result);
              },
              child: const Text('Buka Formulir'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Buka Formulir'));
  await tester.pumpAndSettle();
}
