import 'outbox.dart';
import 'sync_queue.dart';

/// Tujuan tulis entri outbox, misalnya Firestore.
abstract interface class SyncTarget {
  Future<void> apply(OutboxEntry entry);
}

/// Kegagalan satu entri beserta pesannya.
class SyncFailure {
  const SyncFailure({required this.entry, required this.message});

  final OutboxEntry entry;
  final String message;
}

/// Hasil satu putaran sinkronisasi.
class SyncRunResult {
  const SyncRunResult({
    required this.status,
    this.processed = 0,
    this.remaining = 0,
    this.failure,
  });

  final SyncStatus status;

  /// Jumlah entri yang berhasil dikirim pada putaran ini.
  final int processed;

  /// Jumlah entri yang masih menunggu setelah putaran ini.
  final int remaining;
  final SyncFailure? failure;
}

/// Mesin penguras outbox.
///
/// Satu putaran mengirim entri sesuai urutan pembuatan. Bila satu entri gagal,
/// putaran berhenti agar perubahan berikutnya tidak mendahului perubahan yang
/// gagal, lalu entri itu dicoba lagi pada putaran berikutnya. Pemanggil yang
/// mengatur jadwal (misalnya saat kembali online) dan memberi jeda mundur.
class SyncEngine {
  SyncEngine({
    required this.queue,
    required this.target,
    this.batchSize = 20,
  });

  final SyncQueue queue;
  final SyncTarget target;
  final int batchSize;

  /// Diatur pemanggil berdasarkan koneksi perangkat. Selama `false`, tidak ada
  /// tulis jaringan yang dicoba dan status dilaporkan sebagai offline.
  bool isOnline = true;

  bool _running = false;

  bool get isRunning => _running;

  Future<SyncRunResult> flush() async {
    if (!isOnline) {
      return SyncRunResult(
        status: SyncStatus.offline,
        remaining: await queue.pendingCount(),
      );
    }
    if (_running) {
      return SyncRunResult(
        status: SyncStatus.pending,
        remaining: await queue.pendingCount(),
      );
    }

    _running = true;
    var processed = 0;
    try {
      final entries = await queue.pending(limit: batchSize);
      for (final entry in entries) {
        try {
          await target.apply(entry);
          await queue.markSynced(entry);
          processed++;
        } catch (error) {
          final message = error.toString();
          await queue.markFailed(entry, message);
          return SyncRunResult(
            status: SyncStatus.pending,
            processed: processed,
            remaining: await queue.pendingCount(),
            failure: SyncFailure(entry: entry, message: message),
          );
        }
      }
      final remaining = await queue.pendingCount();
      return SyncRunResult(
        status: remaining == 0 ? SyncStatus.synced : SyncStatus.pending,
        processed: processed,
        remaining: remaining,
      );
    } finally {
      _running = false;
    }
  }
}
