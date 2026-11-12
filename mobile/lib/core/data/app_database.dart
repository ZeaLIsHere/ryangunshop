import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class Products extends Table {
  TextColumn get id => text()();
  TextColumn get barcode => text().nullable().unique()();
  TextColumn get name => text()();
  IntColumn get salePrice => integer()();
  IntColumn get costPrice => integer().withDefault(const Constant(0))();
  IntColumn get stock => integer()();
  TextColumn get category => text().withDefault(const Constant('Lainnya'))();
  TextColumn get unit => text().withDefault(const Constant('pcs'))();
  TextColumn get fixtureId => text().withDefault(const Constant(''))();
  TextColumn get locationLabel =>
      text().withDefault(const Constant('Belum ditentukan'))();
  IntColumn get lowStockThreshold => integer().withDefault(const Constant(5))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Transactions extends Table {
  TextColumn get id => text()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get totalAmount => integer()();
  IntColumn get discountAmount => integer().withDefault(const Constant(0))();
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
  int get schemaVersion => 4;

  // Versi 1 di branch ini memiliki dua bentuk: hanya products, atau seluruh
  // tabel transaksi. Periksa tabel sebelum membuatnya agar kedua bentuk aman.
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      await transaction(() async {
        var createdTransactions = false;
        if (from < 2) {
          final existing = await customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table'",
          ).get();
          final names = existing.map((row) => row.read<String>('name')).toSet();
          if (!names.contains('transactions')) {
            await m.createTable(transactions);
            createdTransactions = true;
          }
          if (!names.contains('transaction_items')) {
            await m.createTable(transactionItems);
          }
        }
        if (from < 3 && !createdTransactions) {
          await m.addColumn(transactions, transactions.discountAmount);
        }
        if (from < 4) {
          await m.alterTable(
            TableMigration(
              products,
              newColumns: [
                products.costPrice,
                products.category,
                products.unit,
                products.fixtureId,
                products.locationLabel,
                products.lowStockThreshold,
              ],
            ),
          );
        }
      });
    },
  );

  Future<List<Product>> listProducts() => select(products).get();

  Future<Product?> findProductByBarcode(String barcode) => (select(
    products,
  )..where((row) => row.barcode.equals(barcode))).getSingleOrNull();

  Future<void> saveProduct(ProductsCompanion product) async {
    // Hanya ID yang boleh menyebabkan upsert; barcode milik produk lain harus
    // ditolak oleh constraint UNIQUE, bukan menimpa baris tersebut.
    await into(products).insert(
      product,
      onConflict: DoUpdate((_) => product, target: [products.id]),
    );
  }

  Future<void> completeCheckout({
    required String transactionId,
    required String paymentMethod,
    required int totalAmount,
    required List<CheckoutLine> lines,
    int discountAmount = 0,
    int? cashReceived,
    int? changeAmount,
  }) {
    if (transactionId.trim().isEmpty || lines.isEmpty) {
      throw ArgumentError('Nomor nota dan barang wajib diisi');
    }
    if (paymentMethod != 'cash') {
      throw ArgumentError.value(
        paymentMethod,
        'paymentMethod',
        'Hanya tunai yang terverifikasi secara lokal',
      );
    }
    if (cashReceived == null || cashReceived < 0 || totalAmount <= 0) {
      throw ArgumentError('Nominal tunai dan total harus valid');
    }
    final uniqueIds = lines.map((line) => line.productId).toSet();
    if (uniqueIds.length != lines.length ||
        lines.any(
          (line) =>
              line.productId.isEmpty ||
              line.quantity <= 0 ||
              line.unitPrice <= 0 ||
              line.subtotal != line.quantity * line.unitPrice,
        )) {
      throw ArgumentError('Rincian barang tidak valid atau berulang');
    }
    final subtotal = lines.fold<int>(0, (sum, line) => sum + line.subtotal);
    if (discountAmount < 0 ||
        discountAmount >= subtotal ||
        totalAmount != subtotal - discountAmount ||
        cashReceived < totalAmount ||
        changeAmount != cashReceived - totalAmount) {
      throw ArgumentError('Total atau kembalian tidak sesuai rincian');
    }
    return transaction(() async {
      final checkedProducts = <String, Product>{};
      for (final line in lines) {
        final product = await (select(
          products,
        )..where((row) => row.id.equals(line.productId))).getSingle();
        if (product.salePrice != line.unitPrice) {
          throw StateError('Harga produk berubah: ${product.name}');
        }
        if (product.stock < line.quantity) {
          throw StateError('Stok produk tidak mencukupi: ${product.name}');
        }
        checkedProducts[line.productId] = product;
      }

      await into(transactions).insert(
        TransactionsCompanion.insert(
          id: transactionId,
          createdAt: DateTime.now(),
          totalAmount: totalAmount,
          discountAmount: Value(discountAmount),
          paymentMethod: paymentMethod,
          cashReceived: Value(cashReceived),
          changeAmount: Value(changeAmount),
        ),
      );

      for (final line in lines) {
        final product = checkedProducts[line.productId]!;
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
        final changed =
            await (update(
              products,
            )..where((row) => row.id.equals(line.productId))).write(
              ProductsCompanion(
                stock: Value(product.stock - line.quantity),
                updatedAt: Value(DateTime.now()),
              ),
            );
        if (changed != 1) throw StateError('Gagal memperbarui stok');
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
