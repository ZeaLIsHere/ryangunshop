import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../features/monitor/model/monitor_layout.dart';
import '../monitor_layout_repository.dart';
import 'firestore_schema.dart';

/// Satu operasi atomik layout dan lokasi; tidak pernah memuat harga atau stok.
class MonitorSyncPayload {
  MonitorSyncPayload(Map<String, Object?> data)
    : layout = MonitorLayout.fromJson(data['layout']),
      token = _token(data['token']),
      baseToken = data['baseToken'] == null ? null : _token(data['baseToken']) {
    final ids = data['productIds'];
    if (ids is! List ||
        ids.length > 450 ||
        ids.any(
          (id) =>
              id is! String ||
              id.isEmpty ||
              id.contains('/') ||
              id.length > 1500,
        ) ||
        ids.toSet().length != ids.length) {
      throw const FormatException('Daftar perubahan lokasi tidak valid');
    }
    productIds = List<String>.from(ids);
    if (!layout.assignments.keys.every(productIds.contains)) {
      throw const FormatException('Penempatan tidak tercakup operasi cloud');
    }
  }
  final MonitorLayout layout;
  final String token;
  final String? baseToken;
  late final List<String> productIds;

  static String _token(Object? value) {
    if (value is! String ||
        !RegExp(r'^[A-Za-z0-9_-]{1,160}$').hasMatch(value)) {
      throw const FormatException('Token revisi cloud tidak valid');
    }
    return value;
  }

  void checkBase(Object? serverToken) {
    if (serverToken == token) {
      return; // Retry setelah commit yang responsnya hilang.
    }
    if (serverToken != baseToken) throw const MonitorLayoutConflict();
  }

  Map<String, Object> location(String productId) {
    final id = layout.assignments[productId] ?? '';
    final fixture = layout.fixtures.where((f) => f.id == id).firstOrNull;
    return {
      'fixtureId': id,
      'locationLabel': fixture?.name ?? 'Belum ditentukan',
    };
  }
}

Future<RemoteMonitorLayout?> fetchMonitorLayout(
  FirebaseFirestore firestore,
  String storeId,
) async {
  // Path toko divalidasi oleh kontrak yang sudah ada.
  FirestoreSchema.productsPath(storeId);
  final doc = await firestore
      .doc('stores/$storeId/layouts/main')
      .get(const GetOptions(source: Source.server));
  if (doc.metadata.isFromCache || doc.metadata.hasPendingWrites) {
    throw StateError('Layout belum dikonfirmasi server');
  }
  if (!doc.exists) return null;
  final data = doc.data()!;
  final token = MonitorSyncPayload._token(data['token']);
  return (layout: MonitorLayout.fromJson(data['layout']), token: token);
}

Future<void> writeMonitorLayout(
  FirebaseFirestore firestore,
  String storeId,
  Map<String, Object?> data,
) async {
  final payload = MonitorSyncPayload(data);
  FirestoreSchema.productsPath(storeId);
  final ref = firestore.doc('stores/$storeId/layouts/main');
  await firestore.runTransaction((tx) async {
    final current = await tx.get(ref);
    final serverToken = current.data()?['token'];
    payload.checkBase(serverToken);
    if (serverToken == payload.token) return;
    // Semua read harus mendahului write; produk yang dihapus tidak dihidupkan lagi.
    final products = await Future.wait(
      payload.productIds.map(
        (id) => tx.get(firestore.doc(FirestoreSchema.productPath(storeId, id))),
      ),
    );
    for (final doc in products) {
      if (!doc.exists || doc.data()?['deletedAt'] != null) {
        if (payload.layout.assignments.containsKey(doc.id)) {
          throw StateError('Produk cloud berubah; periksa penempatan');
        }
        continue;
      }
      tx.update(doc.reference, {
        ...payload.location(doc.id),
        'monitorLocationToken': payload.token,
      });
    }
    tx.set(ref, {'layout': payload.layout.toJson(), 'token': payload.token});
  });
}
