import 'package:cloud_firestore/cloud_firestore.dart';

import '../product_record.dart';
import 'firestore_schema.dart';
import 'outbox.dart';
import 'sync_engine.dart';

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
    final path = switch (entry.entity) {
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
      payload.map(
        (key, value) => MapEntry(key, _convertField(key, value)),
      );

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

/// Membaca seluruh produk dari Firestore, dipakai saat memulihkan data pada
/// perangkat baru.
Future<List<ProductRecord>> fetchProductsFromFirestore({
  required FirebaseFirestore firestore,
  String storeId = FirestoreSchema.defaultStoreId,
}) async {
  final snapshot = await firestore
      .collection(FirestoreSchema.productsPath(storeId))
      .where('deletedAt', isNull: true)
      .get();
  return [
    for (final document in snapshot.docs)
      FirestoreSchema.productFromDocument(document.id, document.data()),
  ];
}
