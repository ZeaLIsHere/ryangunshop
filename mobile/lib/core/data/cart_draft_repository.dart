import 'package:drift/drift.dart';

import 'app_database.dart';

class CartDraftLine {
  const CartDraftLine({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.unit,
  });

  final String productId;
  final String productName;
  final int unitPrice;
  final int quantity;
  final String unit;
}

class CartDraftSnapshot {
  const CartDraftSnapshot({
    this.items = const [],
    this.discount = 0,
    this.note = '',
  });

  final List<CartDraftLine> items;
  final int discount;
  final String note;
}

class CartDraftRepository {
  const CartDraftRepository(this.database);

  final AppDatabase database;

  Future<CartDraftSnapshot> load() async {
    final state = await (database.select(
      database.cartDrafts,
    )..where((row) => row.id.equals(1))).getSingleOrNull();
    final items = await (database.select(
      database.cartDraftItems,
    )..orderBy([(row) => OrderingTerm.asc(row.position)])).get();
    return CartDraftSnapshot(
      discount: state?.discount ?? 0,
      note: state?.note ?? '',
      items: [
        for (final item in items)
          CartDraftLine(
            productId: item.productId,
            productName: item.productName,
            unitPrice: item.unitPrice,
            quantity: item.quantity,
            unit: item.unit,
          ),
      ],
    );
  }

  Future<void> save(CartDraftSnapshot draft) async {
    final subtotal = draft.items.fold<int>(
      0,
      (sum, item) => sum + item.unitPrice * item.quantity,
    );
    final ids = draft.items.map((item) => item.productId).toSet();
    if (draft.discount < 0 ||
        draft.discount > subtotal ||
        ids.length != draft.items.length ||
        draft.items.any(
          (item) =>
              item.productId.trim().isEmpty ||
              item.productName.trim().isEmpty ||
              item.unit.trim().isEmpty ||
              item.unitPrice <= 0 ||
              item.quantity <= 0,
        )) {
      throw ArgumentError('Draft keranjang tidak valid');
    }

    await database.transaction(() async {
      await database.delete(database.cartDraftItems).go();
      await database.delete(database.cartDrafts).go();
      await database
          .into(database.cartDrafts)
          .insert(
            CartDraftsCompanion.insert(
              id: const Value(1),
              discount: draft.discount,
              note: draft.note,
            ),
          );
      for (var index = 0; index < draft.items.length; index++) {
        final item = draft.items[index];
        await database
            .into(database.cartDraftItems)
            .insert(
              CartDraftItemsCompanion.insert(
                productId: item.productId,
                productName: item.productName,
                unitPrice: item.unitPrice,
                quantity: item.quantity,
                unit: item.unit,
                position: index,
              ),
            );
      }
    });
  }
}
