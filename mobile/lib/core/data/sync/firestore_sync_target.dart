import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_schema.dart';
import 'outbox.dart';
import 'sync_engine.dart';
import 'monitor_sync.dart';

/// Penulis outbox ke Firestore.
///
/// Setiap entri menulis satu dokumen dengan ID yang sudah ditentukan perangkat
/// (`TRX-...` atau ID produk), sehingga pengiriman ulang setelah gangguan
/// jaringan tidak membuat nota ganda.
class FirestoreSyncTarget implements SyncTarget {
  FirestoreSyncTarget({
    required this.firestore,
    this.storeId = FirestoreSchema.defaultStoreId,
  });

  final FirebaseFirestore firestore;
  final String storeId;

  @override
  Future<void> apply(OutboxEntry entry) async {
    if (entry.entity == SyncEntityType.layout) {
      await writeMonitorLayout(firestore, storeId, entry.payload);
      return;
    }
    final path = switch (entry.entity) {
      SyncEntityType.layout => throw StateError(
        'Layout ditangani secara atomik',
      ),
      SyncEntityType.product => FirestoreSchema.productPath(
        storeId,
        entry.entityId,
      ),
      SyncEntityType.transaction => FirestoreSchema.transactionPath(
        storeId,
        entry.entityId,
      ),
    };
    final document = firestore.doc(path);

    if (entry.operation == SyncOperation.delete) {
      // Penghapusan produk memakai *soft delete* supaya perangkat lain
      // membuang salinannya alih-alih menghidupkannya kembali.
      await document.set(
        _withTimestamps(entry.payload),
        SetOptions(merge: true),
      );
      return;
    }

    if (entry.entity == SyncEntityType.product) {
      await firestore.runTransaction((tx) async {
        final current = await tx.get(document);
        final data = _withTimestamps(entry.payload);
        final remote = current.data();
        // Operasi stok tertunda tidak boleh mengembalikan lokasi sebelum Monitor.
        // Baca produk yang sama, bukan koleksi layout, agar izin layout tidak
        // menjadi prasyarat unggah transaksi kasir.
        if (remote?['monitorLocationToken'] is String) {
          data['fixtureId'] = remote!['fixtureId'];
          data['locationLabel'] = remote['locationLabel'];
        }
        tx.set(document, data, SetOptions(merge: true));
      });
      return;
    }
    // Produk memakai merge agar perubahan stok dari perangkat lain tidak
    // menghapus bidang yang tidak dikirim. Nota ditulis utuh karena bersifat
    // catatan permanen.
    await document.set(
      _withTimestamps(entry.payload),
      SetOptions(merge: entry.entity == SyncEntityType.product),
    );
  }

  /// Mengubah milidetik pada payload menjadi `Timestamp` Firestore.
  Map<String, dynamic> _withTimestamps(Map<String, Object?> payload) =>
      payload.map((key, value) => MapEntry(key, _convertField(key, value)));

  Object? _convertField(String field, Object? value) {
    if (value is int &&
        (field == 'createdAt' ||
            field == 'updatedAt' ||
            field == 'deletedAt')) {
      return Timestamp.fromMillisecondsSinceEpoch(value);
    }
    if (value is Map) {
      return value.map(
        (key, item) => MapEntry(key.toString(), _convertField('', item)),
      );
    }
    if (value is List) {
      return [for (final item in value) _convertField('', item)];
    }
    return value;
  }
}
