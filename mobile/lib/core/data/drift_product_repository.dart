import 'app_database.dart';

import 'package:drift/drift.dart' show Value;

import 'product_record.dart';
import 'product_repository.dart';
import 'sync/firestore_schema.dart';
import 'sync/outbox.dart';
import 'sync/sync_queue.dart';

/// Sumber produk lokal untuk fitur yang sudah siap memakai data tersimpan.
///
/// Bila [queue] diisi, setiap perubahan produk ikut dicatat ke antrean
/// Firestore pada saat yang sama. Tanpa [queue], aplikasi tetap bekerja penuh
/// secara lokal.
class DriftProductRepository implements ProductRepository {
  const DriftProductRepository(this.database, {this.queue});

  final AppDatabase database;
  final SyncQueue? queue;

  @override
  Future<List<ProductRecord>> listProducts() async =>
      (await database.listProducts()).map(_toRecord).toList();

  @override
  Future<ProductRecord?> findByBarcode(String barcode) async {
    final product = await database.findProductByBarcode(barcode);
    return product == null ? null : _toRecord(product);
  }

  @override
  Future<void> save(ProductRecord product) async {
    if (product.id.trim().isEmpty ||
        (product.barcode != null && product.barcode!.trim().isEmpty) ||
        product.name.trim().isEmpty ||
        product.salePrice <= 0 ||
        product.costPrice < 0 ||
        product.stock < 0 ||
        product.lowStockThreshold < 0 ||
        product.category.trim().isEmpty ||
        product.unit.trim().isEmpty ||
        product.locationLabel.trim().isEmpty) {
      throw ArgumentError('Data produk tidak valid');
    }
    final updatedAt = DateTime.now();
    await database.saveProduct(
      ProductsCompanion.insert(
        id: product.id,
        barcode: Value(product.barcode?.trim()),
        name: product.name,
        salePrice: product.salePrice,
        stock: product.stock,
        costPrice: Value(product.costPrice),
        category: Value(product.category),
        unit: Value(product.unit),
        fixtureId: Value(product.fixtureId),
        locationLabel: Value(product.locationLabel),
        lowStockThreshold: Value(product.lowStockThreshold),
        updatedAt: updatedAt,
      ),
    );
    await queue?.enqueue(
      OutboxEntry(
        entity: SyncEntityType.product,
        entityId: product.id,
        operation: SyncOperation.upsert,
        payload: FirestoreSchema.productDocument(
          product,
          updatedAt: updatedAt,
        ),
        createdAt: updatedAt,
      ),
    );
  }

  @override
  Future<void> delete(String id) async {
    final deletedAt = DateTime.now();
    await database.deleteProduct(id);
    await queue?.enqueue(
      OutboxEntry(
        entity: SyncEntityType.product,
        entityId: id,
        operation: SyncOperation.delete,
        payload: FirestoreSchema.productDeletionDocument(
          deletedAt: deletedAt,
        ),
        createdAt: deletedAt,
      ),
    );
  }

  @override
  Future<void> seedIfEmpty(List<ProductRecord> starterRecords) async {
    final current = await listProducts();
    if (current.isEmpty) {
      for (final record in starterRecords) {
        await save(record);
      }
    }
  }

  ProductRecord _toRecord(Product product) => ProductRecord(
    id: product.id,
    barcode: product.barcode,
    name: product.name,
    salePrice: product.salePrice,
    stock: product.stock,
    costPrice: product.costPrice,
    category: product.category,
    unit: product.unit,
    fixtureId: product.fixtureId,
    locationLabel: product.locationLabel,
    lowStockThreshold: product.lowStockThreshold,
  );
}
