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
}
