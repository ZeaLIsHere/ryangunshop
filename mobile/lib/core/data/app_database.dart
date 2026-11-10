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

class Transactions extends Table {
  TextColumn get id => text()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get totalAmount => integer()();
  TextColumn get paymentMethod => text()();
  IntColumn get cashReceived => integer().nullable()();
  IntColumn get changeAmount => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class TransactionItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get transactionId => text()();
  TextColumn get productId => text()();
  TextColumn get productName => text()();
  IntColumn get quantity => integer()();
  IntColumn get unitPrice => integer()();
  IntColumn get subtotal => integer()();
}

@DriftDatabase(tables: [Products, Transactions, TransactionItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  Future<List<Product>> listProducts() => select(products).get();

  Future<Product?> findProductByBarcode(String barcode) => (select(
    products,
  )..where((row) => row.barcode.equals(barcode))).getSingleOrNull();

  Future<void> saveProduct(ProductsCompanion product) =>
      into(products).insertOnConflictUpdate(product);

  Future<void> completeSale({
    required String productId,
    required int quantity,
  }) {
    return transaction(() async {
      final product = await (select(
        products,
      )..where((row) => row.id.equals(productId))).getSingle();
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

  Future<void> completeCheckout({
    required String transactionId,
    required String paymentMethod,
    required int totalAmount,
    required List<CheckoutLine> lines,
    int? cashReceived,
    int? changeAmount,
  }) {
    return transaction(() async {
      for (final line in lines) {
        final product = await (select(
          products,
        )..where((row) => row.id.equals(line.productId))).getSingle();
        if (product.stock < line.quantity) {
          throw StateError('Stok produk tidak mencukupi: ${product.name}');
        }
      }

      await into(transactions).insert(
        TransactionsCompanion.insert(
          id: transactionId,
          createdAt: DateTime.now(),
          totalAmount: totalAmount,
          paymentMethod: paymentMethod,
          cashReceived: Value(cashReceived),
          changeAmount: Value(changeAmount),
        ),
      );

      for (final line in lines) {
        final product = await (select(
          products,
        )..where((row) => row.id.equals(line.productId))).getSingle();
        await into(transactionItems).insert(
          TransactionItemsCompanion.insert(
            transactionId: transactionId,
            productId: line.productId,
            productName: product.name,
            quantity: line.quantity,
            unitPrice: line.unitPrice,
            subtotal: line.subtotal,
          ),
        );
        await (update(
          products,
        )..where((row) => row.id.equals(line.productId))).write(
          ProductsCompanion(
            stock: Value(product.stock - line.quantity),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }
    });
  }
}

class CheckoutLine {
  const CheckoutLine({
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  final String productId;
  final int quantity;
  final int unitPrice;
  final int subtotal;
}

LazyDatabase openAppDatabase() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(p.join(directory.path, 'ryangunshop.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
