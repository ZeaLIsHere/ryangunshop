import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ryangunshop/core/data/app_database.dart';
import 'package:ryangunshop/core/data/cart_draft_repository.dart';

void main() {
  test('draft keranjang menyimpan barang, diskon, dan catatan', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = CartDraftRepository(database);

    await repository.save(
      const CartDraftSnapshot(
        items: [
          CartDraftLine(
            productId: 'teh',
            productName: 'Teh botol',
            unitPrice: 5000,
            quantity: 2,
            unit: 'botol',
          ),
          CartDraftLine(
            productId: 'gula',
            productName: 'Gula',
            unitPrice: 12000,
            quantity: 1,
            unit: 'bungkus',
          ),
        ],
        discount: 2000,
        note: 'Tanpa kantong',
      ),
    );
    final restored = await repository.load();
    expect(restored.items.map((item) => item.productId), ['teh', 'gula']);
    expect(restored.items.first.quantity, 2);
    expect(restored.discount, 2000);
    expect(restored.note, 'Tanpa kantong');

    await repository.save(const CartDraftSnapshot());
    final empty = await repository.load();
    expect(empty.items, isEmpty);
    expect(empty.discount, 0);
    expect(empty.note, isEmpty);
  });

  test('draft tidak berubah jika data baru tidak valid', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = CartDraftRepository(database);
    const valid = CartDraftSnapshot(
      items: [
        CartDraftLine(
          productId: 'teh',
          productName: 'Teh',
          unitPrice: 5000,
          quantity: 1,
          unit: 'botol',
        ),
      ],
    );
    await repository.save(valid);
    await expectLater(
      repository.save(const CartDraftSnapshot(discount: 1000)),
      throwsArgumentError,
    );
    expect((await repository.load()).items.single.productId, 'teh');
  });
}
