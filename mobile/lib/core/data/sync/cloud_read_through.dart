import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';

import '../app_database.dart';
import '../product_record.dart';

import 'firestore_schema.dart';

/// Snapshot mentah sengaja divalidasi seluruhnya sebelum cache diubah.
class CloudSnapshot {
  const CloudSnapshot({required this.products, required this.transactions});

  final Map<String, Map<String, Object?>> products;
  final Map<String, Map<String, Object?>> transactions;
}

class FirestoreReadSource {
  const FirestoreReadSource(this.firestore, {required this.storeId});

  final FirebaseFirestore firestore;
  final String storeId;

  Future<CloudSnapshot> fetch() async {
    final deadline = DateTime.now().add(const Duration(seconds: 8));
    // Koleksi/halaman bukan snapshot server atomik lintas kueri.
    final collections = await Future.wait([
      _collection(FirestoreSchema.productsPath(storeId), deadline),
      _collection(FirestoreSchema.transactionsPath(storeId), deadline),
    ]);
    return CloudSnapshot(
      products: collections[0],
      transactions: collections[1],
    );
  }

  Future<Map<String, Map<String, Object?>>> _collection(
    String path,
    DateTime deadline,
  ) async {
    final result = <String, Map<String, Object?>>{};
    QueryDocumentSnapshot<Map<String, dynamic>>? cursor;
    // ponytail: maksimum 10000 dokumen/koleksi; gunakan kueri rentang + cursor
    // persisten bila toko melampaui batas, jangan impor snapshot terpotong.
    for (var page = 0; page <= 20; page++) {
      if (!DateTime.now().isBefore(deadline)) {
        throw TimeoutException('Batas waktu pembacaan cloud terlampaui');
      }
      Query<Map<String, dynamic>> query = firestore
          .collection(path)
          .orderBy(FieldPath.documentId)
          .limit(500);
      if (cursor != null) query = query.startAfterDocument(cursor);
      final snapshot = await query.get(const GetOptions(source: Source.server));
      if (snapshot.metadata.isFromCache || snapshot.metadata.hasPendingWrites) {
        throw StateError('Snapshot belum dikonfirmasi server');
      }
      if (result.length + snapshot.docs.length > 10000) {
        throw StateError('Batas pembacaan cloud terlampaui');
      }
      for (final document in snapshot.docs) {
        result[document.id] = document.data();
      }
      if (snapshot.docs.length < 500) return result;
      cursor = snapshot.docs.last;
    }
    throw StateError('Snapshot cloud tidak lengkap');
  }
}

/// Read memakai hasil server 15 detik; kegagalan dicoba ulang setelah 30 detik.
/// Fetch native tidak dapat dibatalkan; hasil terlambat dibuang tanpa overlap.
/// Gagal/timeout tetap memakai SQLite, tanpa menganggap cache tersinkron.
class CloudReadThrough extends ChangeNotifier {
  CloudReadThrough({
    required this.database,
    required this.fetch,
    this.timeout = const Duration(seconds: 8),
    this.successTtl = const Duration(seconds: 15),
    this.failureBackoff = const Duration(seconds: 30),
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  final AppDatabase database;
  final Future<CloudSnapshot> Function() fetch;
  final Duration timeout;
  final Duration successTtl;
  final Duration failureBackoff;
  final DateTime Function() now;
  DateTime? _nextRead;
  Future<CloudSnapshot>? _rawFetch;
  Future<void>? _reading;
  bool _disposed = false;
  Object? lastError;
  DateTime? lastServerRead;

  Future<void> refresh({bool force = false}) {
    if (_disposed) return Future.value();
    if (_reading != null) return _reading!;
    // Force melewati TTL, bukan membuat request baru selagi SDK masih tertahan.
    if (_rawFetch != null ||
        (!force && _nextRead != null && now().isBefore(_nextRead!))) {
      return Future.value();
    }
    return _reading = _refresh().whenComplete(() => _reading = null);
  }

  Future<Set<String>> _pending() async {
    final result = <String>{};
    for (final entry
        in await database.select(database.syncOutboxEntries).get()) {
      result.add('${entry.entity}/${entry.entityId}');
      // Outbox versi lama hanya menyimpan nota, tetapi stoknya tetap lokal.
      if (entry.entity == 'transaction') {
        final items = await (database.select(
          database.transactionItems,
        )..where((row) => row.transactionId.equals(entry.entityId))).get();
        result.addAll(items.map((item) => 'product/${item.productId}'));
      }
    }
    return result;
  }

  Future<void> _refresh() async {
    try {
      final revision = database.localWriteRevision;
      final pending = await _pending();
      final raw = Future<CloudSnapshot>.sync(fetch);
      _rawFetch = raw;
      unawaited(
        raw.then<void>(
          (_) {
            if (identical(_rawFetch, raw)) _rawFetch = null;
          },
          onError: (Object _, StackTrace _) {
            if (identical(_rawFetch, raw)) _rawFetch = null;
          },
        ),
      );
      final snapshot = await raw.timeout(timeout);
      if (_disposed) return;
      final products = <String, ProductRecord>{};
      final dates = <String, DateTime>{};
      final deleted = <String>{};
      for (final entry in snapshot.products.entries) {
        FirestoreSchema.validateDocument(entry.key, entry.value);
        dates[entry.key] = FirestoreSchema.documentDate(
          entry.value['updatedAt'],
        );
        if (entry.value['deletedAt'] != null) {
          final date = FirestoreSchema.documentDate(entry.value['deletedAt']);
          if (date != dates[entry.key]) {
            throw const FormatException('Waktu tombstone tidak sesuai');
          }
          deleted.add(entry.key);
        } else {
          products[entry.key] = FirestoreSchema.productFromDocument(
            entry.key,
            entry.value,
          );
        }
      }
      final transactions = [
        for (final entry in snapshot.transactions.entries)
          FirestoreSchema.transactionFromDocument(entry.key, entry.value),
      ];
      await database.transaction(() async {
        if (_disposed) return;
        // Termasuk write yang sudah diunggah/dihapus dari outbox saat fetch.
        if (database.activeLocalWrites != 0 ||
            revision != database.localWriteRevision) {
          throw StateError(
            'Cache lokal berubah selama pembacaan cloud; coba lagi',
          );
        }
        pending.addAll(await _pending());
        if (database.activeLocalWrites != 0 ||
            revision != database.localWriteRevision) {
          throw StateError('Penulisan lokal sedang berlangsung; coba lagi');
        }
        for (final id in deleted) {
          if (!pending.contains('product/$id')) {
            await database.deleteProduct(id);
          }
        }
        // Tidak ada penghapusan berdasarkan absennya dokumen dari snapshot.
        for (final product in products.values) {
          if (pending.contains('product/${product.id}')) continue;
          await database.saveProduct(
            ProductsCompanion.insert(
              id: product.id,
              barcode: Value(product.barcode),
              name: product.name,
              salePrice: product.salePrice,
              costPrice: Value(product.costPrice),
              stock: product.stock,
              category: Value(product.category),
              unit: Value(product.unit),
              fixtureId: Value(product.fixtureId),
              locationLabel: Value(product.locationLabel),
              lowStockThreshold: Value(product.lowStockThreshold),
              updatedAt: dates[product.id]!,
            ),
          );
        }
        for (final record in transactions) {
          if (pending.contains('transaction/${record.id}')) continue;
          await database
              .into(database.transactions)
              .insertOnConflictUpdate(
                TransactionsCompanion.insert(
                  id: record.id,
                  createdAt: record.createdAt,
                  totalAmount: record.totalAmount,
                  discountAmount: Value(record.discountAmount),
                  paymentMethod: record.paymentMethod,
                  cashReceived: Value(record.cashReceived),
                  changeAmount: Value(record.changeAmount),
                ),
              );
          await (database.delete(
            database.transactionItems,
          )..where((row) => row.transactionId.equals(record.id))).go();
          for (final item in record.items) {
            await database
                .into(database.transactionItems)
                .insert(
                  TransactionItemsCompanion.insert(
                    transactionId: record.id,
                    productId: item.productId,
                    productName: item.productName,
                    quantity: item.quantity,
                    unitPrice: item.unitPrice,
                    subtotal: item.subtotal,
                  ),
                );
          }
        }
      });
      if (_disposed) return;
      lastError = null;
      lastServerRead = now();
      _nextRead = now().add(successTtl);
    } catch (error) {
      if (_disposed) return;
      lastError = error;
      _nextRead = now().add(failureBackoff);
    }
    if (!_disposed) notifyListeners();
  }

  Future<void> finish() async {
    await _reading;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
