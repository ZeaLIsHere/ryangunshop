import 'dart:convert';

import 'package:drift/drift.dart';

import '../app_database.dart';
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
    await (database.delete(
      database.syncOutboxEntries,
    )..where((row) => row.id.equals(id))).go();
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
