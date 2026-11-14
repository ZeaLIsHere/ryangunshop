import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ryangunshop/core/session/app_session.dart';
import 'package:ryangunshop/core/session/user_role.dart';
import 'package:ryangunshop/features/catalog/view/product_form_screen.dart';
import 'package:ryangunshop/core/theme/app_theme.dart';
import 'package:ryangunshop/core/widgets/brand_spinner.dart';
import 'package:ryangunshop/features/catalog/model/catalog_scenario.dart';
import 'package:ryangunshop/features/catalog/model/catalog_sort.dart';
import 'package:ryangunshop/features/catalog/sample/catalog_sample.dart';
import 'package:ryangunshop/features/catalog/view/product_catalog.dart';
import 'package:ryangunshop/features/catalog/view_model/catalog_view_model.dart';

void main() {
  testWidgets(
    'kasir tanpa tambah pada katalog kosong dan tetap bisa muat ulang',
    (tester) async {
      final session = AppSession()..selectRole(UserRole.cashier);
      addTearDown(session.dispose);
      await _showCatalog(tester, session: session);
      expect(find.text('Tambah Produk'), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(
        find.text('Minta pemilik menambahkan produk, lalu muat ulang katalog.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Muat Ulang'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('kasir dapat mencari dan masuk keranjang tanpa edit atau hapus', (
    tester,
  ) async {
    final session = AppSession()..selectRole(UserRole.cashier);
    addTearDown(session.dispose);
    await _showCatalog(
      tester,
      session: session,
      viewModel: CatalogViewModel(initialProducts: CatalogSample.products),
    );
    await tester.enterText(find.byType(TextField).first, 'Beras');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Beras pandan wangi 1 kg'));
    await tester.pumpAndSettle();
    expect(find.text('Edit Produk'), findsNothing);
    expect(find.byTooltip('Hapus Produk'), findsNothing);
    await tester.tap(find.text('+ Kasir'));
    await tester.pumpAndSettle();
    expect(session.cart.totalItems, 1);
  });

  testWidgets('hasil form lama tidak tersimpan setelah beralih ke kasir', (
    tester,
  ) async {
    final session = AppSession();
    addTearDown(session.dispose);
    final vm = CatalogViewModel();
    addTearDown(vm.dispose);
    await _showCatalog(tester, session: session, viewModel: vm);
    await tester.tap(find.text('Tambah Produk').last);
    await tester.pumpAndSettle();
    final formContext = tester.element(find.byType(ProductFormScreen));
    session.selectRole(UserRole.cashier);
    Navigator.of(formContext).pop(CatalogSample.products.first);
    await tester.pumpAndSettle();
    expect(vm.allProducts, isEmpty);
    expect(find.text('Tambah Produk'), findsNothing);
  });

  testWidgets('hapus menolak konfirmasi setelah peran berubah', (tester) async {
    final session = AppSession();
    addTearDown(session.dispose);
    final vm = CatalogViewModel(initialProducts: CatalogSample.products);
    addTearDown(vm.dispose);
    await _showCatalog(tester, session: session, viewModel: vm);
    await tester.ensureVisible(find.text('Beras pandan wangi 1 kg'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Beras pandan wangi 1 kg'));
    await tester.pumpAndSettle();
    expect(find.text('Edit Produk'), findsOneWidget);
    await tester.tap(find.byTooltip('Hapus Produk'));
    await tester.pumpAndSettle();
    session.selectRole(UserRole.cashier);
    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();
    expect(vm.allProducts.length, CatalogSample.products.length);
    expect(find.text('Edit Produk'), findsNothing);
  });
  testWidgets('katalog terbaca pada 360 dp dan skala teks 1,3', (tester) async {
    await _showCatalog(
      tester,
      viewModel: CatalogViewModel(initialProducts: CatalogSample.products),
    );

    expect(
      find.text('${CatalogSample.products.length} produk'),
      findsOneWidget,
    );
    expect(find.text('Beras pandan wangi 1 kg'), findsOneWidget);
    expect(find.text('Rp 16.000 / bungkus'), findsOneWidget);
    expect(find.text('Stok: 12 bungkus'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Air mineral 600 ml'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Menipis: 5 botol'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('katalog kosong menyediakan tindakan pemulihan', (tester) async {
    final vm = CatalogViewModel(initialProducts: CatalogSample.products);
    await _showCatalog(tester, viewModel: vm);
    vm.selectScenario(CatalogScenario.empty);
    await tester.pumpAndSettle();

    expect(find.text('Belum ada produk'), findsOneWidget);
    expect(find.text('${CatalogSample.products.length} produk'), findsNothing);

    await tester.tap(find.text('Tambah Produk').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('coba lagi memulihkan skenario gagal', (tester) async {
    final vm = CatalogViewModel(initialProducts: CatalogSample.products);
    await _showCatalog(tester, viewModel: vm);
    vm.selectScenario(CatalogScenario.failure);
    await tester.pumpAndSettle();

    expect(find.text('Katalog gagal dimuat'), findsOneWidget);

    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    expect(
      find.text('${CatalogSample.products.length} produk'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('offline tetap menampilkan produk', (tester) async {
    final vm = CatalogViewModel(initialProducts: CatalogSample.products);
    await _showCatalog(tester, viewModel: vm);
    vm.selectScenario(CatalogScenario.offline);
    await tester.pumpAndSettle();

    expect(find.text('Mode Offline'), findsOneWidget);
    expect(
      find.text('${CatalogSample.products.length} produk'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('Beras pandan wangi 1 kg'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Rp 16.000 / bungkus'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('memuat bisa dicoba dan dihentikan tanpa menunggu layanan', (
    tester,
  ) async {
    final vm = CatalogViewModel(initialProducts: CatalogSample.products);
    await _showCatalog(tester, viewModel: vm);
    vm.selectScenario(CatalogScenario.loading);
    await tester.pump();

    expect(find.byType(BrandSpinner), findsOneWidget);
    await tester.tap(find.text('Muat Ulang'));
    await tester.pumpAndSettle();
    expect(find.byType(BrandSpinner), findsNothing);
    expect(
      find.text('${CatalogSample.products.length} produk'),
      findsOneWidget,
    );
  });

  testWidgets('reduced motion tidak memutar spinner', (tester) async {
    final vm = CatalogViewModel(initialProducts: CatalogSample.products);
    await _showCatalog(tester, disableAnimations: true, viewModel: vm);
    vm.selectScenario(CatalogScenario.loading);
    await tester.pump();

    expect(find.text('Memuat katalog'), findsOneWidget);
    expect(find.byType(BrandSpinner), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('kontrol katalog memenuhi target sentuh Android', (tester) async {
    final vm = CatalogViewModel(initialProducts: CatalogSample.products);
    await _showCatalog(tester, viewModel: vm);
    vm.selectScenario(CatalogScenario.empty);
    await tester.pumpAndSettle();

    final semantics = tester.ensureSemantics();
    try {
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    } finally {
      semantics.dispose();
    }
  });

  test('urutkan harga dan stok mengikuti pilihan', () {
    final vm = CatalogViewModel(initialProducts: CatalogSample.products);
    addTearDown(vm.dispose);

    vm.setSort(CatalogSort.priceAsc);
    final prices = vm.filteredProducts.map((p) => p.price).toList();
    expect(prices, List<int>.of(prices)..sort());

    vm.setSort(CatalogSort.stockAsc);
    final stocks = vm.filteredProducts.map((p) => p.stock).toList();
    expect(stocks, List<int>.of(stocks)..sort());
  });

  testWidgets('mengurutkan katalog lewat menu urutkan', (tester) async {
    final vm = CatalogViewModel(initialProducts: CatalogSample.products);
    await _showCatalog(tester, viewModel: vm);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Urutkan: ${CatalogSort.nameAsc.label}'));
    await tester.pumpAndSettle();

    expect(find.text('Urutkan berdasarkan'), findsOneWidget);

    await tester.tap(find.text(CatalogSort.priceAsc.label));
    await tester.pumpAndSettle();

    expect(vm.sort, CatalogSort.priceAsc);
    expect(find.text(CatalogSort.priceAsc.label), findsOneWidget);
  });

  testWidgets('filter kategori menyaring daftar produk', (tester) async {
    final vm = CatalogViewModel(initialProducts: CatalogSample.products);
    await _showCatalog(tester, viewModel: vm);
    await tester.pumpAndSettle();

    final minuman = find.text('Minuman');
    await tester.ensureVisible(minuman);
    await tester.pumpAndSettle();
    await tester.tap(minuman);
    await tester.pumpAndSettle();

    expect(vm.selectedCategory, 'Minuman');
    expect(vm.filteredProducts, isNotEmpty);
    expect(vm.filteredProducts.every((p) => p.category == 'Minuman'), isTrue);
  });
}

Future<void> _showCatalog(
  WidgetTester tester, {
  bool disableAnimations = false,
  CatalogViewModel? viewModel,
  AppSession? session,
}) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    AppSessionScope(
      session: session ?? AppSession(),
      child: MaterialApp(
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
          body: SafeArea(child: ProductCatalog(viewModel: viewModel)),
        ),
      ),
    ),
  );
}
