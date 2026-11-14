import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ryangunshop/core/data/app_database.dart';
import 'package:ryangunshop/core/data/product_record.dart';
import 'package:ryangunshop/core/data/product_repository.dart';
import 'package:ryangunshop/core/data/transaction_repository.dart';
import 'package:ryangunshop/core/data/in_memory_transaction_repository.dart';
import 'package:ryangunshop/core/format/rupiah.dart';
import 'package:ryangunshop/features/dashboard/model/dashboard_period.dart';
import 'package:ryangunshop/core/session/app_session.dart';
import 'package:ryangunshop/core/session/user_role.dart';
import 'package:ryangunshop/core/theme/app_theme.dart';
import 'package:ryangunshop/features/catalog/model/catalog_product.dart';
import 'package:ryangunshop/features/catalog/view/product_form_screen.dart';
import 'package:ryangunshop/features/dashboard/model/dashboard_shortcut.dart';
import 'package:ryangunshop/features/dashboard/view/dashboard_screen.dart';

void main() {
  late AppSession session;

  setUp(() => session = AppSession());
  tearDown(() => session.dispose());

  Future<void> host(
    WidgetTester tester, {
    ValueChanged<DashboardShortcut>? select,
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
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          ),
          home: Scaffold(
            body: DashboardScreen(onShortcutSelected: select ?? (_) {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> reveal(WidgetTester tester, String text) async {
    await tester.scrollUntilVisible(
      find.text(text),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'kasir operasional tanpa agregat atau alat pemilik, role tidak menghapus data',
    (tester) async {
      await session.productRepository.save(
        const ProductRecord(id: 'p', name: 'Kopi', salePrice: 100, stock: 8),
      );
      session.selectRole(UserRole.cashier);
      DashboardShortcut? selected;
      await host(tester, select: (value) => selected = value);
      for (final label in [
        'Pindai Barcode',
        'Buka Kasir',
        'Stok',
        'Riwayat Nota',
      ]) {
        expect(find.text(label).first, findsOneWidget);
      }
      for (final label in [
        'Tambah Produk',
        'Kelola Stok',
        'Label Barcode',
        'Laporan',
        'Hari ini',
        'Perlu perhatian',
      ]) {
        expect(find.text(label), findsNothing);
      }
      expect(find.text('Omzet Hari Ini'), findsOneWidget);
      expect(find.text('Aksi Cepat'), findsOneWidget);
      expect(find.text('Penjualan harian'), findsNothing);
      final assets = tester
          .widgetList<Image>(find.byType(Image))
          .map((image) => (image.image as AssetImage).assetName);
      expect(
        assets,
        containsAll([
          'assets/icon/08_pindai_barcode.png',
          'assets/icon/02_keranjang.png',
          'assets/icon/09_stok_produk.png',
          'assets/icon/03_riwayat_transaksi.png',
        ]),
      );
      await tester.tap(find.text('Pindai Barcode'));
      expect(selected, DashboardShortcut.cashier);
      session.selectRole(UserRole.owner);
      await tester.pumpAndSettle();
      expect(find.text('Tambah Produk'), findsOneWidget);
      expect(find.text('Penjualan harian'), findsOneWidget);
      expect(find.text('Omzet Hari Ini'), findsNothing);
      expect(find.text('Aksi Cepat'), findsNothing);
      expect(
        (await session.productRepository.listProducts()).single.name,
        'Kopi',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'pemilik angka nyata, snapshot harian, stok dan tanpa barcode pada 360 skala 1.3',
    (tester) async {
      session.dispose();
      final database = AppDatabase(NativeDatabase.memory());
      session = AppSession(database: database);
      addTearDown(database.close);
      for (final product in [
        const ProductRecord(
          id: 'a',
          name: 'Nama katalog',
          salePrice: 5000,
          stock: 0,
        ),
        const ProductRecord(
          id: 'b',
          name: 'B',
          salePrice: 5000,
          stock: 2,
          barcode: '123',
        ),
        const ProductRecord(id: 'c', name: 'C', salePrice: 5000, stock: 20),
      ]) {
        await session.productRepository.save(product);
      }
      for (var i = 0; i < 2; i++) {
        await database
            .into(database.transactions)
            .insert(
              TransactionsCompanion.insert(
                id: 'n$i',
                createdAt: DateTime.now(),
                totalAmount: 9000 + i * 2000,
                discountAmount: const Value(1000),
                paymentMethod: 'cash',
              ),
            );
        await database
            .into(database.transactionItems)
            .insert(
              TransactionItemsCompanion.insert(
                transactionId: 'n$i',
                productId: 'a',
                productName: 'Snapshot Kopi',
                quantity: 2,
                unitPrice: 5000,
                subtotal: 10000,
              ),
            );
      }
      await host(tester);
      await reveal(tester, 'Penjualan bersih: Rp 20.000');
      expect(find.text('2 nota'), findsOneWidget);
      expect(find.text('Rata-rata per nota: Rp 10.000'), findsOneWidget);
      await reveal(tester, 'Stok kosong: 1 produk');
      expect(find.text('Stok menipis: 1 produk'), findsOneWidget);
      expect(find.text('Tanpa barcode: 2 produk'), findsOneWidget);
      await reveal(tester, 'Snapshot Kopi · 4 barang');
      expect(find.text('Nama katalog · 4 barang'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'tambah menerima hasil form dan menyimpan repository tanpa mengubah keranjang',
    (tester) async {
      session.cart.addProduct(
        const CatalogProduct(
          id: 'cart',
          name: 'Tetap di keranjang',
          price: 100,
          stock: 8,
          unit: 'pcs',
          fixtureId: '',
          locationLabel: '',
          category: 'Lainnya',
        ),
        quantity: 2,
      );
      await host(tester);
      await reveal(tester, 'Tambah Produk');
      await tester.tap(find.text('Tambah Produk'));
      await tester.pumpAndSettle();
      expect(find.byType(ProductFormScreen), findsOneWidget);
      Navigator.of(tester.element(find.byType(ProductFormScreen))).pop(
        const CatalogProduct(
          id: 'new',
          name: 'Baru',
          price: 500,
          stock: 3,
          unit: 'pcs',
          fixtureId: '',
          locationLabel: '',
          category: 'Lainnya',
        ),
      );
      await tester.pumpAndSettle();
      expect(
        (await session.productRepository.listProducts()).single.name,
        'Baru',
      );
      expect(session.cart.items.single.productName, 'Tetap di keranjang');
      expect(session.cart.items.single.quantity, 2);
    },
  );

  testWidgets('hasil form setelah role berubah tidak disimpan', (tester) async {
    await host(tester);
    await reveal(tester, 'Tambah Produk');
    await tester.tap(find.text('Tambah Produk'));
    await tester.pumpAndSettle();
    session.selectRole(UserRole.cashier);
    Navigator.of(tester.element(find.byType(ProductFormScreen))).pop(
      const CatalogProduct(
        id: 'new',
        name: 'Ditolak',
        price: 500,
        stock: 3,
        unit: 'pcs',
        fixtureId: '',
        locationLabel: '',
        category: 'Lainnya',
      ),
    );
    await tester.pumpAndSettle();
    expect(await session.productRepository.listProducts(), isEmpty);
  });

  testWidgets('periode mengubah query, ringkasan, grafik dan nota bersama', (
    tester,
  ) async {
    session.dispose();
    final semantics = tester.ensureSemantics();

    final source = _PeriodRepository();
    session = _PeriodSession(source);
    await host(tester);
    for (final days in [1, 7, 30]) {
      if (days != 1) {
        await tester.ensureVisible(find.text('$days hari'));
        await tester.tap(find.text('$days hari'));
        await tester.pumpAndSettle();
      }
      final expected = DashboardPeriod(DateTime.now(), days);
      expect(source.start, expected.start);
      expect(source.end, expected.end);
      expect(
        find.text('Penjualan bersih: ${formatRupiah(days * 100)}'),
        findsOneWidget,
      );
      expect(find.text('1 nota'), findsOneWidget);
      expect(find.text('Snapshot periode · $days barang'), findsOneWidget);
      expect(find.text('Kotor: ${formatRupiah(days * 200)}'), findsOneWidget);
      expect(find.text('nota-$days'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          '${expected.start.day}/${expected.start.month}/${expected.start.year}: ${formatRupiah(days * 100)}',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    }
    semantics.dispose();
  });

  testWidgets(
    'kasir gagal tidak menampilkan omzet nol dan retry memulihkan Hero',
    (tester) async {
      session.dispose();
      final failing = _FailingSession();
      session = failing;
      session.selectRole(UserRole.cashier);
      await host(tester);
      expect(
        find.text('Data beranda gagal dimuat. Angka belum tersedia.'),
        findsOneWidget,
      );
      expect(find.text('Omzet Hari Ini'), findsNothing);
      failing.fail = false;
      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();
      expect(find.text('Omzet Hari Ini'), findsOneWidget);
      expect(find.text('Belum ada transaksi hari ini'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('gagal tidak menjadi angka nol, retry dan kosong tersedia', (
    tester,
  ) async {
    session.dispose();
    final failing = _FailingSession();
    session = failing;
    await host(tester);
    await reveal(tester, 'Data beranda gagal dimuat. Angka belum tersedia.');
    expect(find.textContaining('Penjualan bersih:'), findsNothing);
    expect(find.textContaining('Stok kosong:'), findsNothing);
    failing.fail = false;
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    await reveal(tester, 'Katalog kosong. Tambahkan produk pertama.');
    expect(find.text('Tambah Produk pertama'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _PeriodSession extends AppSession {
  _PeriodSession(this.source);
  final TransactionRepository source;
  @override
  TransactionRepository get transactionRepository => source;
}

class _PeriodRepository extends InMemoryTransactionRepository {
  DateTime? start;
  DateTime? end;
  @override
  Future<List<TransactionRecord>> listForPeriod(
    DateTime start,
    DateTime endExclusive,
  ) async {
    this.start = start;
    end = endExclusive;
    final days = endExclusive.difference(start).inHours ~/ 24;
    return [
      TransactionRecord(
        id: 'nota-$days',
        createdAt: start,
        totalAmount: days * 100,
        discountAmount: days * 100,
        paymentMethod: 'cash',
        items: [
          TransactionItemSnapshot(
            productId: 'p',
            productName: 'Snapshot periode',
            quantity: days,
            unitPrice: 200,
            subtotal: days * 200,
          ),
        ],
      ),
    ];
  }
}

class _FailingSession extends AppSession {
  bool fail = true;
  @override
  ProductRepository get productRepository =>
      fail ? _FailedProducts() : super.productRepository;
}

class _FailedProducts implements ProductRepository {
  @override
  Future<List<ProductRecord>> listProducts() async => throw StateError('gagal');
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
