import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';

import '../../features/monitor/model/monitor_layout.dart';
import 'app_database.dart';
import 'sync/outbox.dart';
import 'sync/sync_queue.dart';

final class MonitorLayoutConflict implements Exception {
  const MonitorLayoutConflict();
  @override
  String toString() => 'Tata letak berubah. Muat ulang sebelum menyimpan.';
}

typedef StoredMonitorLayout = ({MonitorLayout layout, int revision});
typedef RemoteMonitorLayout = ({MonitorLayout layout, String token});

class MonitorLayoutRepository {
  MonitorLayoutRepository(this.database, {this.queue, this.fetchRemote});
  final AppDatabase database;
  final SyncQueue? queue;
  final Future<RemoteMonitorLayout?> Function()? fetchRemote;
  Object? cloudError;

  Future<StoredMonitorLayout?> load() async {
    final row = await (database.select(
      database.monitorLayouts,
    )..where((r) => r.id.equals(MonitorLayout.mainId))).getSingleOrNull();
    if (row == null) return null;
    if (row.revision < 1) {
      throw const FormatException('Revisi layout tidak valid');
    }
    return (layout: _decode(row.payload).layout, revision: row.revision);
  }

  ({MonitorLayout layout, String? token}) _decode(String payload) {
    final data = jsonDecode(payload);
    if (data is Map && data.containsKey('layout')) {
      if (data['token'] != null && data['token'] is! String) {
        throw const FormatException('Token layout tidak valid');
      }
      return (
        layout: MonitorLayout.fromJson(data['layout']),
        token: data['token'] as String?,
      );
    }
    return (layout: MonitorLayout.fromJson(data), token: null);
  }

  Future<List<SyncOutboxEntry>> pending() => (database.select(
    database.syncOutboxEntries,
  )..where((r) => r.entity.equals('layout'))).get();

  Future<void> refresh({bool discardPending = false}) async {
    final fetch = fetchRemote;
    if (fetch == null) return;
    try {
      final revision = database.localWriteRevision;
      if (!discardPending && (await pending()).isNotEmpty) return;
      final remote = await fetch().timeout(const Duration(seconds: 8));
      await database.localWrite(() async {
        // localWrite sendiri menambah revisi satu kali sebelum masuk transaksi.
        if (database.localWriteRevision != revision + 1) {
          throw const MonitorLayoutConflict();
        }
        if (!discardPending && (await pending()).isNotEmpty) return;
        if (discardPending) {
          await (database.delete(
            database.syncOutboxEntries,
          )..where((r) => r.entity.equals('layout'))).go();
        }
        if (remote == null) {
          if (discardPending) {
            final old = await load();
            await _applyLocations(MonitorLayout(), previous: old?.layout);
            await database.delete(database.monitorLayouts).go();
          }
          return;
        }
        final current = await load();
        if (current != null) {
          final row = await (database.select(
            database.monitorLayouts,
          )..where((r) => r.id.equals(MonitorLayout.mainId))).getSingle();
          final cached = _decode(row.payload);
          if (cached.token == remote.token &&
              jsonEncode(cached.layout.toJson()) ==
                  jsonEncode(remote.layout.toJson())) {
            return;
          }
        }
        await _applyLocations(remote.layout, previous: current?.layout);
        await database
            .into(database.monitorLayouts)
            .insertOnConflictUpdate(
              MonitorLayoutsCompanion.insert(
                id: MonitorLayout.mainId,
                revision: (current?.revision ?? 0) + 1,
                payload: jsonEncode({
                  'layout': remote.layout.toJson(),
                  'token': remote.token,
                }),
              ),
            );
      });
      cloudError = null;
    } catch (e) {
      cloudError = e;
    }
  }

  /// Penyimpanan layout+lokasi atomik; stok/harga/nota/keranjang tidak disalin.
  Future<StoredMonitorLayout> save(
    MonitorLayout layout, {
    required int expectedRevision,
    bool Function()? canSave,
  }) async {
    if (expectedRevision < 0) throw ArgumentError.value(expectedRevision);
    return database.localWrite(() async {
      final current = await load();
      if ((current?.revision ?? 0) != expectedRevision) {
        throw const MonitorLayoutConflict();
      }
      final products = await database.listProducts();
      if (layout.assignments.keys.any(
        (id) => !products.any((p) => p.id == id),
      )) {
        throw StateError(
          'Produk berubah atau dihapus. Periksa penempatan sebelum simpan.',
        );
      }
      // Layout-only caller lama tidak boleh menghapus lokasi produk terpakai.
      final oldIds =
          current?.layout.fixtures.map((f) => f.id).toSet() ?? <String>{};
      final newIds = layout.fixtures.map((f) => f.id).toSet();
      for (final p in products) {
        if (oldIds.contains(p.fixtureId) &&
            !newIds.contains(p.fixtureId) &&
            !current!.layout.assignments.containsKey(p.id)) {
          throw StateError(
            'Penempatan lama harus ditinjau sebelum objek dihapus',
          );
        }
      }
      if (canSave != null && !canSave()) {
        throw StateError('Hanya pemilik boleh menyimpan');
      }
      final row = await (database.select(
        database.monitorLayouts,
      )..where((r) => r.id.equals(MonitorLayout.mainId))).getSingleOrNull();
      final baseToken = row == null ? null : _decode(row.payload).token;
      final random = Random.secure();
      final token =
          'layout_${List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';
      final revision = expectedRevision + 1;
      await _applyLocations(layout, previous: current?.layout);
      await database
          .into(database.monitorLayouts)
          .insertOnConflictUpdate(
            MonitorLayoutsCompanion.insert(
              id: MonitorLayout.mainId,
              revision: revision,
              payload: jsonEncode({
                'layout': layout.toJson(),
                'token': queue == null ? baseToken : token,
              }),
            ),
          );
      if (queue != null) {
        final previous = current?.layout.assignments.keys.toSet() ?? <String>{};
        final changed = {...previous, ...layout.assignments.keys}.toList();
        if (changed.length > 450) {
          throw StateError(
            'Terlalu banyak perubahan lokasi; pecah perubahan menjadi beberapa simpan.',
          );
        }
        await queue!.enqueue(
          OutboxEntry(
            entity: SyncEntityType.layout,
            entityId: 'main',
            operation: SyncOperation.upsert,
            createdAt: DateTime.now(),
            payload: {
              'layout': layout.toJson(),
              'token': token,
              'baseToken': baseToken,
              'productIds': changed,
            },
          ),
        );
      }
      if (canSave != null && !canSave()) {
        throw StateError('Peran berubah; simpan dibatalkan');
      }
      return (layout: layout, revision: revision);
    });
  }

  Future<void> _applyLocations(
    MonitorLayout layout, {
    MonitorLayout? previous,
  }) async {
    final fixtures = {for (final f in layout.fixtures) f.id: f};
    for (final p in await database.listProducts()) {
      if (!layout.assignments.containsKey(p.id) &&
          !(previous?.assignments.containsKey(p.id) ?? false)) {
        continue;
      }
      final fixtureId = layout.assignments[p.id] ?? '';
      final label = fixtures[fixtureId]?.name ?? 'Belum ditentukan';
      if (p.fixtureId == fixtureId && p.locationLabel == label) continue;
      await (database.update(
        database.products,
      )..where((r) => r.id.equals(p.id))).write(
        ProductsCompanion(
          fixtureId: Value(fixtureId),
          locationLabel: Value(label),
        ),
      );
    }
  }
}
