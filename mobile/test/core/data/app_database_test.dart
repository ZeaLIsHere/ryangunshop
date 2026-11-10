import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ryangunshop/core/data/app_database.dart';

void main() {
  late AppDatabase database;

  setUp(() => database = AppDatabase(NativeDatabase.memory()));
  tearDown(() => database.close());

  test('menyimpan produk dan mengurangi stok secara atomik', () async {
    await database.saveProduct(
      ProductsCompanion.insert(
        id: 'p-1',
        barcode: '8990001',
        name: 'Air Mineral',
        salePrice: 4000,
        stock: 3,
        updatedAt: DateTime(2026, 1, 1),
      ),
    );

    await database.completeSale(productId: 'p-1', quantity: 2);
    expect((await database.findProductByBarcode('8990001'))!.stock, 1);
    expect(
      () => database.completeSale(productId: 'p-1', quantity: 2),
      throwsStateError,
    );
  });

  test('checkout menyimpan nota dan mengurangi stok atomik', () async {
    await database.saveProduct(
      ProductsCompanion.insert(
        id: 'p-1',
        barcode: '8990001',
        name: 'Air Mineral',
        salePrice: 4000,
        stock: 3,
        updatedAt: DateTime(2026, 1, 1),
      ),
    );

    await database.completeCheckout(
      transactionId: 'TRX-0001',
      paymentMethod: 'cash',
      totalAmount: 8000,
      cashReceived: 10000,
      changeAmount: 2000,
      lines: const [
        CheckoutLine(
          productId: 'p-1',
          quantity: 2,
          unitPrice: 4000,
          subtotal: 8000,
        ),
      ],
    );

    expect((await database.select(database.transactions).get()).length, 1);
    expect((await database.select(database.transactionItems).get()).length, 1);
    expect((await database.findProductByBarcode('8990001'))!.stock, 1);
  });

  test('checkout gagal seluruhnya jika stok kurang', () async {
    await database.saveProduct(
      ProductsCompanion.insert(
        id: 'p-1',
        barcode: '8990001',
        name: 'Air Mineral',
        salePrice: 4000,
        stock: 1,
        updatedAt: DateTime(2026, 1, 1),
      ),
    );

    expect(
      () => database.completeCheckout(
        transactionId: 'TRX-0002',
        paymentMethod: 'cash',
        totalAmount: 8000,
        lines: const [
          CheckoutLine(
            productId: 'p-1',
            quantity: 2,
            unitPrice: 4000,
            subtotal: 8000,
          ),
        ],
      ),
      throwsStateError,
    );
    expect((await database.select(database.transactions).get()), isEmpty);
    expect((await database.findProductByBarcode('8990001'))!.stock, 1);
  });
}
