import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ryangunshop/core/data/app_database.dart';
import 'package:ryangunshop/core/data/drift_product_repository.dart';
import 'package:ryangunshop/core/session/app_session.dart';
import 'package:ryangunshop/features/catalog/model/catalog_product.dart';
import 'package:ryangunshop/features/catalog/model/catalog_scenario.dart';
import 'package:ryangunshop/features/catalog/view/product_catalog.dart';
import 'package:ryangunshop/features/catalog/view_model/catalog_view_model.dart';

void main() {
  test('katalog memuat kembali produk lokal tanpa barcode', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final source = DriftProductRepository(database);
    final first = CatalogViewModel(repository: source);
    addTearDown(first.dispose);
    await first.loadProducts();
    expect(first.scenario, CatalogScenario.empty);
    await first.persistProduct(
      const CatalogProduct(
        id: 'lokal-1',
        name: 'Mi instan',
        price: 3500,
        stock: 12,
        unit: 'bungkus',
        fixtureId: '',
        locationLabel: 'Rak mi',
        category: 'Makanan',
        costPrice: 2800,
      ),
    );

    final reopened = CatalogViewModel(repository: source);
    addTearDown(reopened.dispose);
    await reopened.loadProducts();
    expect(reopened.scenario, CatalogScenario.withData);
    expect(reopened.products.single.name, 'Mi instan');
    expect(reopened.products.single.barcode, isNull);
    expect(reopened.products.single.costPrice, 2800);
    expect(reopened.categories, ['Semua', 'Makanan']);
  });

  testWidgets('tab katalog lokal menampilkan produk dari repository', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final source = DriftProductRepository(database);
    final viewModel = CatalogViewModel(repository: source);
    addTearDown(viewModel.dispose);
    final session = AppSession();
    addTearDown(session.dispose);
    await tester.pumpWidget(
      AppSessionScope(
        session: session,
        child: MaterialApp(
          home: Scaffold(body: ProductCatalog(viewModel: viewModel)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Belum ada produk'), findsOneWidget);
    await viewModel.persistProduct(
      const CatalogProduct(
        id: 'lokal-2',
        name: 'Air mineral lokal',
        price: 4000,
        stock: 5,
        unit: 'botol',
        fixtureId: '',
        locationLabel: 'Rak minuman',
        category: 'Minuman',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Air mineral lokal'), findsOneWidget);
    expect(find.text('Tersimpan di perangkat'), findsOneWidget);
  });

  testWidgets('form katalog menambah dan mengedit produk lokal', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final session = AppSession(database: database);
    addTearDown(session.dispose);
    await tester.pumpWidget(
      AppSessionScope(
        session: session,
        child: MaterialApp(
          home: Scaffold(
            body: ProductCatalog(repository: session.productRepository),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Produk lokal • foto contoh'), findsOneWidget);
    await _enterField(tester, 'Nama Produk *', 'Gula lokal');
    await _enterField(tester, 'Harga Jual *', '12000');
    await _enterField(tester, 'Stok Saat Ini *', '6');
    await tester.tap(find.text('Simpan Produk'));
    await tester.pumpAndSettle();

    final saved = (await database.listProducts()).single;
    expect(saved.name, 'Gula lokal');
    expect(saved.stock, 6);
    await tester.ensureVisible(find.text('Gula lokal'));
    await tester.tap(find.text('Gula lokal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit Produk'));
    await tester.pumpAndSettle();
    await _enterField(tester, 'Stok Saat Ini *', '9');
    await tester.tap(find.text('Simpan Perubahan'));
    await tester.pumpAndSettle();
    expect((await database.listProducts()).single.stock, 9);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'katalog lokal mendukung penambahan produk dari nol dan penghapusan produk',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final session = AppSession(database: database);
      addTearDown(session.dispose);

      await tester.pumpWidget(
        AppSessionScope(
          session: session,
          child: MaterialApp(
            home: Scaffold(
              body: ProductCatalog(repository: session.productRepository),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Belum ada produk'), findsOneWidget);
      expect(find.text('Tambah Produk'), findsWidgets);

      // Buka form tambah produk dari empty state
      await tester.tap(find.text('Tambah Produk').first);
      await tester.pumpAndSettle();

      await _enterField(tester, 'Nama Produk *', 'Kopi Lokal');
      await _enterField(tester, 'Harga Jual *', '5000');
      await _enterField(tester, 'Stok Saat Ini *', '10');
      await tester.tap(find.text('Simpan Produk'));
      await tester.pumpAndSettle();

      final allDbProducts = await database.listProducts();
      expect(allDbProducts, hasLength(1));
      expect(find.text('Belum ada produk'), findsNothing);
      expect(find.text('Kopi Lokal'), findsOneWidget);

      // Buka detail produk dan hapus
      await tester.tap(find.text('Kopi Lokal'));
      await tester.pumpAndSettle();

      // Tombol hapus ada untuk owner
      expect(find.byTooltip('Hapus Produk'), findsOneWidget);
      await tester.tap(find.byTooltip('Hapus Produk'));
      await tester.pumpAndSettle();

      // Dialog konfirmasi
      expect(find.text('Hapus Produk?'), findsOneWidget);
      await tester.tap(find.text('Hapus'));
      await tester.pumpAndSettle();

      final afterDeleteDb = await database.listProducts();
      expect(afterDeleteDb, isEmpty);
      expect(find.text('Belum ada produk'), findsOneWidget);
    },
  );
}

Future<void> _enterField(
  WidgetTester tester,
  String label,
  String value,
) async {
  final field = find.ancestor(
    of: find.text(label),
    matching: find.byType(TextFormField),
  );
  await tester.ensureVisible(field);
  await tester.pumpAndSettle();
  await tester.enterText(field, value);
  await tester.pump();
}
