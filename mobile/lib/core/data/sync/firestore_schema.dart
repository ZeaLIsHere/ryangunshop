/// Kontrak dokumen Firestore RyanGunshop.
///
/// Semua data toko disimpan di bawah satu dokumen `stores/{storeId}` supaya
/// aturan keamanan cukup memeriksa satu cabang, dan agar beberapa warung dapat
/// memakai proyek Firebase yang sama tanpa saling melihat data.
///
/// Pemetaan dapat diuji tanpa emulator; Timestamp native dibaca di batas cloud.
library;

import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

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
    productId: FirestoreSchema._text(json['productId']),
    productName: FirestoreSchema._text(json['productName']),
    quantity: FirestoreSchema._integer(json['quantity'], minimum: 1),
    unitPrice: FirestoreSchema._integer(json['unitPrice'], minimum: 1),
    subtotal: FirestoreSchema._integer(json['subtotal'], minimum: 1),
  );
}

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
    validateDocument(id, data);
    documentDate(data['updatedAt']);
    final name = _text(data['name']);
    if (data['deletedAt'] != null) {
      throw const FormatException('Produk sudah dihapus');
    }
    return ProductRecord(
      id: id,
      barcode: data['barcode'] == null
          ? null
          : _emptyToNull(_text(data['barcode'])),
      name: name,
      salePrice: _integer(data['salePrice'], minimum: 1),
      stock: _integer(data['stock']),
      costPrice: _integer(data['costPrice'] ?? 0),
      category: _text(data['category'] ?? 'Lainnya'),
      unit: _text(data['unit'] ?? 'pcs'),
      fixtureId: _text(data['fixtureId'] ?? '', allowEmpty: true),
      locationLabel: _text(data['locationLabel'] ?? 'Belum ditentukan'),
      lowStockThreshold: _integer(data['lowStockThreshold'] ?? 5),
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
    validateDocument(id, data);
    final items = soldItemsFromDocument(data);
    final total = _integer(data['totalAmount'], minimum: 1);
    final discount = _integer(data['discountAmount']);
    final cash = _integer(data['cashReceived']);
    final change = _integer(data['changeAmount']);
    final count = items.fold<int>(0, (sum, item) => sum + item.quantity);
    final subtotal = items.fold<int>(0, (sum, item) => sum + item.subtotal);
    if (data['paymentMethod'] != 'cash' ||
        subtotal > maxInteger ||
        count > maxInteger ||
        discount >= subtotal ||
        total != subtotal - discount ||
        cash < total ||
        change != cash - total ||
        _integer(data['itemCount'], minimum: 1) != count) {
      throw const FormatException('Nominal atau pembayaran nota tidak valid');
    }
    return TransactionRecord(
      id: id,
      createdAt: documentDate(data['createdAt']),
      totalAmount: total,
      discountAmount: discount,
      paymentMethod: 'cash',
      cashReceived: cash,
      changeAmount: change,
      itemCount: count,
      summaryTitle: _text(data['summaryTitle'] ?? items.first.productName),
      items: List.unmodifiable([
        for (final item in items)
          TransactionItemSnapshot(
            productId: item.productId,
            productName: item.productName,
            quantity: item.quantity,
            unitPrice: item.unitPrice,
            subtotal: item.subtotal,
          ),
      ]),
    );
  }

  /// Membaca baris barang pada dokumen nota.
  static List<SoldItem> soldItemsFromDocument(Map<String, Object?> data) {
    final rawItems = data['items'];
    if (rawItems is! List || rawItems.isEmpty || rawItems.length > 1000) {
      throw const FormatException(
        'Rincian nota wajib diisi dan dibatasi 1000 baris',
      );
    }
    final ids = <String>{};
    return [for (final raw in rawItems) _soldItem(raw, ids)];
  }

  static SoldItem _soldItem(Object? raw, Set<String> ids) {
    if (raw is! Map<String, Object?>) {
      throw const FormatException('Baris nota tidak valid');
    }
    final item = SoldItem.fromJson(raw);
    if (!ids.add(item.productId) ||
        item.productId.contains('/') ||
        item.subtotal != item.quantity * item.unitPrice) {
      throw const FormatException(
        'Baris nota berulang atau subtotal tidak sesuai',
      );
    }
    return item;
  }

  static const maxInteger = 9007199254740991;

  static void validateDocument(String id, Map<String, Object?> data) {
    if (id.trim().isEmpty ||
        id.contains('/') ||
        _integer(data['schemaVersion']) != version) {
      throw const FormatException('Identitas atau versi dokumen tidak valid');
    }
  }

  static String _text(Object? value, {bool allowEmpty = false}) {
    if (value is! String || (!allowEmpty && value.trim().isEmpty)) {
      throw const FormatException('Teks dokumen tidak valid');
    }
    return value;
  }

  static String? _emptyToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  static int _integer(Object? value, {int minimum = 0}) {
    if (value is! num ||
        !value.isFinite ||
        value < minimum ||
        value > maxInteger ||
        value != value.truncateToDouble()) {
      throw const FormatException('Bilangan bulat dokumen tidak valid');
    }
    return value.toInt();
  }

  static DateTime documentDate(Object? value) {
    final date = switch (value) {
      Timestamp() => value.toDate(),
      DateTime() => value,
      int() when value >= 0 && value <= 253402300799999 =>
        DateTime.fromMillisecondsSinceEpoch(value),
      String() => DateTime.tryParse(value),
      _ => null,
    };
    if (date == null || date.year < 1970 || date.year > 9999) {
      throw const FormatException('Waktu dokumen tidak valid');
    }
    return date;
  }

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
