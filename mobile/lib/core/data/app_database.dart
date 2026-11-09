import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class Products extends Table {
  TextColumn get id => text()();
  TextColumn get barcode => text().unique()();
  TextColumn get name => text()();
  IntColumn get salePrice => integer()();
  IntColumn get stock => integer()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [Products])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  Future<List<Product>> listProducts() => select(products).get();

  Future<Product?> findProductByBarcode(String barcode) =>
      (select(products)..where((row) => row.barcode.equals(barcode)))
          .getSingleOrNull();

  Future<void> saveProduct(ProductsCompanion product) =>
      into(products).insertOnConflictUpdate(product);

  Future<void> completeSale({required String productId, required int quantity}) {
    return transaction(() async {
      final product = await (select(products)
            ..where((row) => row.id.equals(productId)))
          .getSingle();
      if (product.stock < quantity) {
        throw StateError('Stok produk tidak mencukupi');
      }
      await (update(products)..where((row) => row.id.equals(productId))).write(
        ProductsCompanion(
          stock: Value(product.stock - quantity),
          updatedAt: Value(DateTime.now()),
        ),
      );
    });
  }
}

LazyDatabase openAppDatabase() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(p.join(directory.path, 'ryangunshop.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
