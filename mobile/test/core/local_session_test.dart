import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ryangunshop/core/data/app_database.dart';
import 'package:ryangunshop/core/data/cart_draft_repository.dart';
import 'package:ryangunshop/core/data/transaction_repository.dart';
import 'package:ryangunshop/core/session/app_session.dart';
import 'package:ryangunshop/features/catalog/model/catalog_product.dart';

void main() {
  test(
    'draft keranjang pulih pada sesi baru dengan perubahan terakhir',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final first = AppSession(database: database);
      await first.loadLocalCart();
      expect(first.isLocalCartReady, isTrue);
      first.cart.addProduct(
        const CatalogProduct(
          id: 'teh',
          name: 'Teh botol',
          price: 5000,
          stock: 8,
          unit: 'botol',
          fixtureId: '',
          locationLabel: 'Etalase',
          category: 'Minuman',
        ),
      );
      first.cart.updateQuantity('teh', 2);
      first.cart.setDiscount(1000);
      first.cart.setNote('Tanpa kantong');
      await first.flushCartDraft();
      first.dispose();

      final reopened = AppSession(database: database);
      addTearDown(reopened.dispose);
      await reopened.loadLocalCart();
      expect(reopened.cart.items.single.productId, 'teh');
      expect(reopened.cart.items.single.quantity, 2);
      expect(reopened.cart.discount, 1000);
      expect(reopened.cart.note, 'Tanpa kantong');
      expect(reopened.cart.total, 9000);
    },
  );

  test('sesi lokal memuat omzet dan nota dari database', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final session = AppSession(database: database);
    addTearDown(session.dispose);
    expect(session.cart.isEmpty, isTrue);
    expect(session.todayRevenue, 0);
    expect(session.recentTransactions, isEmpty);

    await database.saveProduct(
      ProductsCompanion.insert(
        id: 'produk-1',
        barcode: const Value('123'),
        name: 'Teh',
        salePrice: 5000,
        stock: 3,
        updatedAt: DateTime.now(),
      ),
    );
    await TransactionRepository(database).checkout(
      transactionId: 'TRX-LOCAL-1',
      paymentMethod: 'cash',
      totalAmount: 5000,
      cashReceived: 5000,
      changeAmount: 0,
      lines: const [
        CheckoutLine(
          productId: 'produk-1',
          quantity: 1,
          unitPrice: 5000,
          subtotal: 5000,
        ),
      ],
    );
    await session.loadLocalSummary();
    expect(session.todayRevenue, 5000);
    expect(session.todayTransactionCount, 1);
    expect(session.recentTransactions.single.id, 'TRX-LOCAL-1');
  });

  test(
    'nota dan omzet tetap terbaca pada sesi setelah database dibuka ulang',
    () async {
      final folder = await Directory.systemTemp.createTemp(
        'ryangunshop_session_',
      );
      addTearDown(() => folder.delete(recursive: true));
      final file = File('${folder.path}${Platform.pathSeparator}kasir.sqlite');
      final first = AppDatabase(NativeDatabase(file));
      await first.saveProduct(
        ProductsCompanion.insert(
          id: 'teh',
          name: 'Teh botol',
          salePrice: 5000,
          stock: 3,
          updatedAt: DateTime.now(),
        ),
      );
      await TransactionRepository(first).checkout(
        transactionId: 'TRX-SETELAH-BUKA',
        paymentMethod: 'cash',
        totalAmount: 5000,
        cashReceived: 5000,
        changeAmount: 0,
        lines: const [
          CheckoutLine(
            productId: 'teh',
            quantity: 1,
            unitPrice: 5000,
            subtotal: 5000,
          ),
        ],
      );
      await CartDraftRepository(first).save(
        const CartDraftSnapshot(
          items: [
            CartDraftLine(
              productId: 'teh',
              productName: 'Teh botol',
              unitPrice: 5000,
              quantity: 1,
              unit: 'botol',
            ),
          ],
          note: 'Lanjut nanti',
        ),
      );
      await first.close();

      final reopened = AppDatabase(NativeDatabase(file));
      addTearDown(reopened.close);
      final session = AppSession(database: reopened);
      addTearDown(session.dispose);
      await session.loadLocalSummary();
      await session.loadLocalCart();
      expect(session.todayRevenue, 5000);
      expect(session.todayTransactionCount, 1);
      expect(session.recentTransactions.single.id, 'TRX-SETELAH-BUKA');
      expect((await reopened.listProducts()).single.stock, 2);
      expect(session.cart.items.single.productId, 'teh');
      expect(session.cart.note, 'Lanjut nanti');
    },
  );
}
