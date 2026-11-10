import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ryangunshop/core/data/app_database.dart';
import 'package:ryangunshop/core/data/transaction_repository.dart';

void main() {
  late AppDatabase database;
  late TransactionRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = TransactionRepository(database);
  });

  tearDown(() => database.close());

  test('repository checkout dan membaca nota terbaru', () async {
    await database.saveProduct(
      ProductsCompanion.insert(
        id: 'p-1',
        barcode: '8990001',
        name: 'Air Mineral',
        salePrice: 4000,
        stock: 2,
        updatedAt: DateTime(2026, 1, 1),
      ),
    );

    await repository.checkout(
      transactionId: 'TRX-0001',
      paymentMethod: 'cash',
      totalAmount: 4000,
      cashReceived: 5000,
      changeAmount: 1000,
      lines: const [
        CheckoutLine(
          productId: 'p-1',
          quantity: 1,
          unitPrice: 4000,
          subtotal: 4000,
        ),
      ],
    );

    final records = await repository.listRecent();
    expect(records, hasLength(1));
    expect(records.single.id, 'TRX-0001');
    expect(records.single.changeAmount, 1000);
  });
}
