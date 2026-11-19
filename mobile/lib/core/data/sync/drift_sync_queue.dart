import 'dart:convert';

import 'package:drift/drift.dart';

import '../app_database.dart';
import '../product_record.dart';
import 'firestore_schema.dart';
import 'outbox.dart';
import 'sync_queue.dart';

/// Antrean tulis yang disimpan di SQLite, sehingga tetap ada setelah aplikasi
/// ditutup dan perangkat menyala ulang.
class DriftSyncQueue implements SyncQueue {
  const DriftSyncQueue(this.database);

  final AppDatabase database;

  @override
  Future<void> enqueue(OutboxEntry entry) async {
    await database
        .into(database.syncOutboxEntries)
        .insert(
          SyncOutboxEntriesCompanion.insert(
            entity: entry.entity.name,
            entityId: entry.entityId,
            operation: entry.operation.name,
            payload: jsonEncode(entry.payload),
            createdAt: entry.createdAt,
          ),
        );
  }

  @override
  Future<List<OutboxEntry>> pending({int limit = 20}) async {
    final rows =
        await (database.select(database.syncOutboxEntries)
              ..orderBy([(row) => OrderingTerm.asc(row.id)])
              ..limit(limit))
            .get();
    return rows.map(_toEntry).toList();
  }

  @override
  Future<int> pendingCount() async {
    final count = database.syncOutboxEntries.id.count();
    final row = await (database.selectOnly(
      database.syncOutboxEntries,
    )..addColumns([count])).getSingle();
    return row.read(count) ?? 0;
  }

  @override
  Future<void> markSynced(OutboxEntry entry) async {
    final id = entry.id;
    if (id == null) return;
    await database.localWrite(() async {
      final stored = await (database.select(
        database.syncOutboxEntries,
      )..where((row) => row.id.equals(id))).getSingleOrNull();
      if (stored == null) return;
      final current = _toEntry(stored);
      if (current.entity == SyncEntityType.transaction &&
          current.payload['stockQueued'] != true) {
        await _reconcileLegacyStock(current.entityId);
      }
      await (database.delete(
        database.syncOutboxEntries,
      )..where((row) => row.id.equals(id))).go();
    });
  }

  // Ack nota lama dan rencana unggah stok harus commit bersama. Receipt-only
  // outbox tetap melindungi stok sampai entri produk ini diakui server.
  Future<void> _reconcileLegacyStock(String transactionId) async {
    final receipt = await (database.select(
      database.transactions,
    )..where((row) => row.id.equals(transactionId))).getSingleOrNull();
    if (receipt == null) return;
    final items = await (database.select(
      database.transactionItems,
    )..where((row) => row.transactionId.equals(transactionId))).get();
    if (items.isEmpty) throw StateError('Rincian nota lokal belum tersedia');
    for (final id in items.map((item) => item.productId).toSet()) {
      final pending =
          await (database.select(database.syncOutboxEntries)
                ..where(
                  (row) =>
                      row.entity.equals('product') & row.entityId.equals(id),
                )
                ..orderBy([(row) => OrderingTerm.asc(row.id)]))
              .get();
      if (pending.isNotEmpty && pending.last.operation == 'delete') continue;
      final p = await (database.select(
        database.products,
      )..where((row) => row.id.equals(id))).getSingleOrNull();
      if (p == null) {
        throw StateError('Stok lokal nota belum dapat direkonsiliasi');
      }
      if (pending.isNotEmpty &&
          _toEntry(pending.last).payload['stock'] == p.stock) {
        continue;
      }
      // Append snapshot lokal terbaru bila entri lama mendahului checkout.
      // Tidak mengubah/menghapus payload write asli yang masih tertunda.
      await enqueue(
        OutboxEntry(
          entity: SyncEntityType.product,
          entityId: id,
          operation: SyncOperation.upsert,
          payload: FirestoreSchema.productDocument(
            ProductRecord(
              id: p.id,
              barcode: p.barcode,
              name: p.name,
              salePrice: p.salePrice,
              costPrice: p.costPrice,
              stock: p.stock,
              category: p.category,
              unit: p.unit,
              fixtureId: p.fixtureId,
              locationLabel: p.locationLabel,
              lowStockThreshold: p.lowStockThreshold,
            ),
            updatedAt: p.updatedAt,
          ),
          createdAt: DateTime.now(),
        ),
      );
    }
  }

  @override
  Future<void> markFailed(OutboxEntry entry, String error) async {
    final id = entry.id;
    if (id == null) return;
    await (database.update(
      database.syncOutboxEntries,
    )..where((row) => row.id.equals(id))).write(
      SyncOutboxEntriesCompanion(
        attempts: Value(entry.attempts + 1),
        lastError: Value(error),
      ),
    );
  }

  OutboxEntry _toEntry(SyncOutboxEntry row) {
    final decoded = jsonDecode(row.payload);
    return OutboxEntry(
      id: row.id,
      entity: SyncEntityType.values.firstWhere(
        (entity) => entity.name == row.entity,
        orElse: () => SyncEntityType.product,
      ),
      entityId: row.entityId,
      operation: SyncOperation.values.firstWhere(
        (operation) => operation.name == row.operation,
        orElse: () => SyncOperation.upsert,
      ),
      payload: decoded is Map
          ? decoded.map((key, value) => MapEntry(key.toString(), value))
          : const {},
      createdAt: row.createdAt,
      attempts: row.attempts,
      lastError: row.lastError,
    );
  }
}
