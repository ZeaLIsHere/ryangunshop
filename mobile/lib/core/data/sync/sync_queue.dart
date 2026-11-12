import 'outbox.dart';

/// Penyimpanan antrean tulis yang tahan terhadap aplikasi ditutup.
///
/// Implementasi produksi memakai tabel `sync_outbox_entries` pada SQLite
/// (lihat `drift_sync_queue.dart`), sedangkan implementasi memori dipakai
/// pengujian dan pratinjau web.
abstract interface class SyncQueue {
  Future<void> enqueue(OutboxEntry entry);

  /// Entri paling lama lebih dahulu agar urutan perubahan data terjaga.
  Future<List<OutboxEntry>> pending({int limit = 20});

  Future<int> pendingCount();

  /// Menghapus entri yang sudah diterima server.
  Future<void> markSynced(OutboxEntry entry);

  /// Mencatat kegagalan tanpa membuang entri, lalu mencoba lagi nanti.
  Future<void> markFailed(OutboxEntry entry, String error);
}

/// Antrean di memori. Entri hilang saat aplikasi ditutup, jadi hanya untuk
/// pengujian dan pratinjau.
class InMemorySyncQueue implements SyncQueue {
  InMemorySyncQueue([Iterable<OutboxEntry> seed = const []])
    : _entries = [...seed];

  final List<OutboxEntry> _entries;
  int _nextId = 1;

  @override
  Future<void> enqueue(OutboxEntry entry) async {
    _entries.add(entry.copyWith(id: entry.id ?? _nextId++));
  }

  @override
  Future<List<OutboxEntry>> pending({int limit = 20}) async =>
      _entries.take(limit).toList();

  @override
  Future<int> pendingCount() async => _entries.length;

  @override
  Future<void> markSynced(OutboxEntry entry) async {
    _entries.removeWhere((item) => item.id == entry.id);
  }

  @override
  Future<void> markFailed(OutboxEntry entry, String error) async {
    final index = _entries.indexWhere((item) => item.id == entry.id);
    if (index < 0) return;
    _entries[index] = _entries[index].copyWith(
      attempts: _entries[index].attempts + 1,
      lastError: error,
    );
  }
}
