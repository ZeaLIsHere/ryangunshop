import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ryangunshop/core/data/app_database.dart';
import 'package:ryangunshop/core/data/cart_draft_repository.dart';
import 'package:ryangunshop/core/data/transaction_repository.dart';
import 'package:ryangunshop/core/session/app_session.dart';
import 'package:ryangunshop/features/catalog/model/catalog_product.dart';
import 'package:ryangunshop/features/checkout/view/cart_checkout_screen.dart';
import 'package:ryangunshop/features/payment/view/payment_success_screen.dart';

void main() {
  late AppDatabase database;
  late AppSession session;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    session = AppSession();
    await database.saveProduct(
      ProductsCompanion.insert(
        id: 'contoh-produk-1',
        barcode: const Value('CONTOH-001'),
        name: 'Beras pandan wangi 1 kg',
        salePrice: 16000,
        stock: 12,
        updatedAt: DateTime(2026, 1, 1),
      ),
    );
    await database.saveProduct(
      ProductsCompanion.insert(
        id: 'contoh-produk-4',
        name: 'Mi instan goreng',
        salePrice: 3500,
        stock: 24,
        updatedAt: DateTime(2026, 1, 1),
      ),
    );
  });
  tearDown(() async {
    session.dispose();
    await database.close();
  });

  Future<void> openPayment(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      AppSessionScope(
        session: session,
        child: MaterialApp(
          home: CartCheckoutScreen(
            transactionRepository: TransactionRepository(database),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Lanjut ke Pembayaran'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Uang Pas'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'tunai lokal menyimpan nota dan stok sebelum mengosongkan keranjang',
    (tester) async {
      await openPayment(tester);
      await tester.tap(find.text('Simpan Transaksi Tunai'));
      await tester.pumpAndSettle();

      expect(find.byType(PaymentSuccessScreen), findsOneWidget);
      expect(find.text('Transaksi Tunai Tersimpan'), findsOneWidget);
      expect(session.cart.isEmpty, isTrue);
      expect(
        (await database.select(database.transactions).get()),
        hasLength(1),
      );
      expect(
        (await database.select(database.transactionItems).get()),
        hasLength(2),
      );
      expect((await database.findProductByBarcode('CONTOH-001'))!.stock, 11);
    },
  );

  testWidgets('stok kurang mempertahankan keranjang dan tidak membuat nota', (
    tester,
  ) async {
    await database.saveProduct(
      ProductsCompanion.insert(
        id: 'contoh-produk-4',
        name: 'Mi instan goreng',
        salePrice: 3500,
        stock: 1,
        updatedAt: DateTime(2026, 1, 1),
      ),
    );
    await openPayment(tester);
    await tester.tap(find.text('Simpan Transaksi Tunai'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Transaksi gagal disimpan'), findsOneWidget);
    expect(session.cart.isEmpty, isFalse);
    expect((await database.select(database.transactions).get()), isEmpty);
    expect((await database.findProductByBarcode('CONTOH-001'))!.stock, 12);
  });

  testWidgets('kasir lokal menghapus draft setelah nota tersimpan', (
    tester,
  ) async {
    session.dispose();
    session = AppSession(database: database);
    await session.loadLocalCart();
    session.cart.addProduct(
      const CatalogProduct(
        id: 'contoh-produk-1',
        name: 'Beras pandan wangi 1 kg',
        price: 16000,
        stock: 12,
        unit: 'bungkus',
        fixtureId: '',
        locationLabel: 'Rak sembako',
        category: 'Sembako',
      ),
    );
    await session.flushCartDraft();
    expect((await CartDraftRepository(database).load()).items, hasLength(1));

    await openPayment(tester);
    await tester.tap(find.text('Simpan Transaksi Tunai'));
    await tester.pumpAndSettle();
    expect(find.byType(PaymentSuccessScreen), findsOneWidget);
    expect((await CartDraftRepository(database).load()).items, isEmpty);
    expect(session.cart.isEmpty, isTrue);
  });

  testWidgets('dialog diskon kasir dapat mengatur diskon custom', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      AppSessionScope(
        session: session,
        child: MaterialApp(
          home: CartCheckoutScreen(
            transactionRepository: TransactionRepository(database),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Voucher/Diskon'), findsOneWidget);
    await tester.tap(find.text('Voucher/Diskon'));
    await tester.pumpAndSettle();

    expect(find.text('Atur Diskon Transaksi'), findsOneWidget);
    await tester.tap(find.text('Rp 5.000'));
    await tester.pump();
    await tester.tap(find.text('Terapkan'));
    await tester.pumpAndSettle();

    expect(session.cart.discount, 5000);
    expect(find.text('Diskon Rp 5.000'), findsOneWidget);
  });

  testWidgets(
    'layar sukses pembayaran menampilkan tombol cetak struk untuk nota tersimpan',
    (tester) async {
      await openPayment(tester);
      await tester.tap(find.text('Simpan Transaksi Tunai'));
      await tester.pumpAndSettle();

      final printBtn = find.text('Cetak Struk (Bluetooth)');
      expect(printBtn, findsOneWidget);
      await tester.ensureVisible(printBtn);
      await tester.pumpAndSettle();
      await tester.tap(printBtn);
      await tester.pump();

      expect(find.textContaining('Mencetak nota'), findsOneWidget);
    },
  );
}
