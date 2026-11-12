/// Kontrak dokumen Firestore RyanGunshop.
///
/// Semua data toko disimpan di bawah satu dokumen `stores/{storeId}` supaya
/// aturan keamanan cukup memeriksa satu cabang, dan agar beberapa warung dapat
/// memakai proyek Firebase yang sama tanpa saling melihat data.
///
/// Berkas ini sengaja tidak mengimpor paket Firebase. Pemetaan dapat diuji
/// tanpa emulator dan dipakai bersama oleh Drift, antrean outbox, serta adapter
/// Firestore.
library;

import '../product_record.dart';
import '../transaction_repository.dart';

/// Baris barang yang dibekukan ke dalam dokumen nota.
class SoldItem {
  const SoldItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  final String productId;
  final String productName;
  final int quantity;
  final int unitPrice;
  final int subtotal;

  Map<String, Object?> toJson() => {
    'productId': productId,
    'productName': productName,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'subtotal': subtotal,
  };

  factory SoldItem.fromJson(Map<String, Object?> json) => SoldItem(
    productId: '${json['productId']}',
    productName: '${json['productName']}',
    quantity: _intValue(json['quantity']),
    unitPrice: _intValue(json['unitPrice']),
    subtotal: _intValue(json['subtotal']),
  );
}

int _intValue(Object? value) => switch (value) {
  int() => value,
  num() => value.toInt(),
  String() => int.tryParse(value) ?? 0,
  _ => 0,
};

/// Nama koleksi, jalur dokumen, dan pemetaan data RyanGunshop.
abstract final class FirestoreSchema {
  /// Versi skema dokumen. Naikkan bila bentuk dokumen berubah dan tulis
  /// langkah migrasinya pada `docs/firestore-schema.md`.
  static const int version = 1;

  static const String storesCollection = 'stores';
  static const String productsCollection = 'products';
  static const String transactionsCollection = 'transactions';
  static const String metaCollection = 'meta';

  /// Toko bawaan untuk pemasangan satu warung.
  static const String defaultStoreId = 'toko-utama';

  /// Jalur koleksi produk, misalnya `stores/toko-utama/products`.
  static String productsPath(String storeId) {
    _requireSegment(storeId, 'storeId');
    return '$storesCollection/$storeId/$productsCollection';
  }

  /// Jalur dokumen produk.
  static String productPath(String storeId, String productId) {
    _requireSegment(productId, 'productId');
    return '${productsPath(storeId)}/$productId';
  }

  /// Jalur koleksi nota penjualan.
  static String transactionsPath(String storeId) {
    _requireSegment(storeId, 'storeId');
    return '$storesCollection/$storeId/$transactionsCollection';
  }

  /// Jalur dokumen nota penjualan.
  static String transactionPath(String storeId, String transactionId) {
    _requireSegment(transactionId, 'transactionId');
    return '${transactionsPath(storeId)}/$transactionId';
  }

  /// Jalur dokumen penanda sinkronisasi toko.
  static String metaPath(String storeId, String metaId) {
    _requireSegment(storeId, 'storeId');
    _requireSegment(metaId, 'metaId');
    return '$storesCollection/$storeId/$metaCollection/$metaId';
  }

  /// Dokumen produk yang siap ditulis ke Firestore.
  ///
  /// Seluruh nominal disimpan sebagai bilangan bulat rupiah, tanpa pecahan,
  /// agar tidak ada pembulatan yang bergeser antara perangkat.
  static Map<String, Object?> productDocument(
    ProductRecord product, {
    required DateTime updatedAt,
  }) {
    if (product.id.trim().isEmpty) {
      throw ArgumentError.value(product.id, 'product.id', 'wajib diisi');
    }
    if (product.name.trim().isEmpty) {
      throw ArgumentError.value(product.name, 'product.name', 'wajib diisi');
    }
    return {
      'schemaVersion': version,
      'name': product.name,
      'barcode': _emptyToNull(product.barcode),
      'salePrice': product.salePrice,
      'costPrice': product.costPrice,
      'stock': product.stock,
      'category': product.category,
      'unit': product.unit,
      'fixtureId': product.fixtureId,
      'locationLabel': product.locationLabel,
      'lowStockThreshold': product.lowStockThreshold,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'deletedAt': null,
    };
  }

  /// Dokumen produk yang sudah dihapus.
  ///
  /// Penghapusan dilakukan sebagai *soft delete* agar perangkat lain dapat
  /// membuang salinannya tanpa menghidupkan kembali data lama.
  static Map<String, Object?> productDeletionDocument({
    required DateTime deletedAt,
  }) => {
    'schemaVersion': version,
    'deletedAt': deletedAt.millisecondsSinceEpoch,
    'updatedAt': deletedAt.millisecondsSinceEpoch,
  };

  /// Membaca dokumen produk kembali menjadi [ProductRecord].
  static ProductRecord productFromDocument(
    String id,
    Map<String, Object?> data,
  ) {
    final name = _asString(data['name']);
    if (id.trim().isEmpty || name.isEmpty) {
      throw FormatException('Dokumen produk tidak lengkap: $id');
    }
    return ProductRecord(
      id: id,
      barcode: _emptyToNull(_asString(data['barcode'])),
      name: name,
      salePrice: _asInt(data['salePrice']),
      stock: _asInt(data['stock']),
      costPrice: _asInt(data['costPrice']),
      category: _asString(data['category'], fallback: 'Lainnya'),
      unit: _asString(data['unit'], fallback: 'pcs'),
      fixtureId: _asString(data['fixtureId']),
      locationLabel: _asString(data['locationLabel'], fallback: 'Belum ditentukan'),
      lowStockThreshold: _asInt(data['lowStockThreshold'], fallback: 5),
    );
  }

  /// Dokumen nota penjualan yang siap ditulis ke Firestore.
  ///
  /// Baris barang disimpan sebagai larik di dalam dokumen nota karena satu nota
  /// warung jarang melebihi puluhan baris. Bila kelak perlu kueri per barang,
  /// pecah menjadi subkoleksi dan naikkan [version].
  static Map<String, Object?> transactionDocument(
    TransactionRecord transaction,
    List<SoldItem> items,
  ) {
    if (transaction.id.trim().isEmpty) {
      throw ArgumentError.value(
        transaction.id,
        'transaction.id',
        'wajib diisi',
      );
    }
    return {
      'schemaVersion': version,
      'createdAt': transaction.createdAt.millisecondsSinceEpoch,
      'totalAmount': transaction.totalAmount,
      'discountAmount': transaction.discountAmount,
      'paymentMethod': transaction.paymentMethod,
      'cashReceived': transaction.cashReceived,
      'changeAmount': transaction.changeAmount,
      'itemCount': transaction.itemCount,
      'summaryTitle': transaction.summaryTitle,
      'items': [for (final item in items) item.toJson()],
    };
  }

  /// Membaca dokumen nota kembali menjadi [TransactionRecord].
  static TransactionRecord transactionFromDocument(
    String id,
    Map<String, Object?> data,
  ) {
    if (id.trim().isEmpty) {
      throw FormatException('Nomor nota tidak valid: $id');
    }
    return TransactionRecord(
      id: id,
      createdAt: _asDate(data['createdAt']) ?? DateTime.now(),
      totalAmount: _asInt(data['totalAmount']),
      discountAmount: _asInt(data['discountAmount']),
      paymentMethod: _asString(data['paymentMethod'], fallback: 'cash'),
      cashReceived: _asNullableInt(data['cashReceived']),
      changeAmount: _asNullableInt(data['changeAmount']),
      itemCount: _asInt(data['itemCount']),
      summaryTitle: _asString(data['summaryTitle'], fallback: 'Nota tunai'),
    );
  }

  /// Membaca baris barang pada dokumen nota.
  static List<SoldItem> soldItemsFromDocument(Map<String, Object?> data) {
    final rawItems = data['items'];
    if (rawItems is! List) return const [];
    return [
      for (final raw in rawItems)
        if (raw is Map)
          SoldItem.fromJson(
            raw.map((key, value) => MapEntry(key.toString(), value)),
          ),
    ];
  }

  static String _asString(Object? value, {String fallback = ''}) =>
      value is String ? value : fallback;

  static String? _emptyToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  static int _asInt(Object? value, {int fallback = 0}) =>
      _asNullableInt(value) ?? fallback;

  static int? _asNullableInt(Object? value) => switch (value) {
    int() => value,
    num() => value.toInt(),
    String() => int.tryParse(value),
    _ => null,
  };

  static DateTime? _asDate(Object? value) => switch (value) {
    int() => DateTime.fromMillisecondsSinceEpoch(value),
    num() => DateTime.fromMillisecondsSinceEpoch(value.toInt()),
    String() => DateTime.tryParse(value),
    DateTime() => value,
    _ => null,
  };

  static void _requireSegment(String value, String label) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(value, label, 'tidak boleh kosong');
    }
    if (trimmed.contains('/')) {
      throw ArgumentError.value(value, label, 'tidak boleh memuat "/"');
    }
  }
}
