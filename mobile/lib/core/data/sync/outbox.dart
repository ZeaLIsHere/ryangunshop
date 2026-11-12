/// Model antrean tulis (*outbox*) untuk sinkronisasi ke Firestore.
///
/// Berkas ini tidak mengimpor paket Firebase sama sekali. Payload disimpan
/// sebagai peta JSON sederhana supaya dapat dititipkan ke SQLite, diuji tanpa
/// emulator, dan baru diubah menjadi dokumen Firestore oleh adapter.
library;

/// Jenis data yang disinkronkan. Draft keranjang sengaja tidak termasuk karena
/// hanya berlaku untuk perangkat yang sedang dipakai.
enum SyncEntityType { product, transaction }

/// Operasi yang harus dijalankan pada dokumen tujuan.
enum SyncOperation { upsert, delete }

/// Status ringkas yang dipakai penanda seperti `SyncPill`.
enum SyncStatus {
  offline,
  pending,
  synced;

  /// Label bahasa Indonesia yang dipakai antarmuka.
  String get label => switch (this) {
    SyncStatus.offline => 'Offline',
    SyncStatus.pending => 'Menunggu sinkron',
    SyncStatus.synced => 'Tersinkron',
  };

  bool get hasPendingWrites => this != SyncStatus.synced;
}

/// Satu perintah tulis yang menunggu dikirim ke Firestore.
///
/// [id] adalah nomor baris pada antrean lokal dan bernilai `null` selama entri
/// belum disimpan.
class OutboxEntry {
  const OutboxEntry({
    required this.entity,
    required this.entityId,
    required this.operation,
    required this.payload,
    required this.createdAt,
    this.id,
    this.attempts = 0,
    this.lastError,
  });

  final int? id;
  final SyncEntityType entity;
  final String entityId;
  final SyncOperation operation;

  /// Isi dokumen tujuan. Nilai harus dapat diubah menjadi JSON: `String`,
  /// `num`, `bool`, `List`, `Map`, atau `null`.
  final Map<String, Object?> payload;
  final DateTime createdAt;
  final int attempts;
  final String? lastError;

  String get entityName => entity.name;

  OutboxEntry copyWith({int? id, int? attempts, String? lastError}) =>
      OutboxEntry(
        id: id ?? this.id,
        entity: entity,
        entityId: entityId,
        operation: operation,
        payload: payload,
        createdAt: createdAt,
        attempts: attempts ?? this.attempts,
        lastError: lastError ?? this.lastError,
      );

  Map<String, Object?> toJson() => {
    'id': id,
    'entity': entity.name,
    'entityId': entityId,
    'operation': operation.name,
    'payload': payload,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'attempts': attempts,
    'lastError': lastError,
  };

  factory OutboxEntry.fromJson(Map<String, Object?> json) {
    final rawPayload = json['payload'];
    return OutboxEntry(
      id: _asInt(json['id']),
      entity: _parseEntity(json['entity']),
      entityId: json['entityId'] as String,
      operation: _parseOperation(json['operation']),
      payload: rawPayload is Map
          ? rawPayload.map((key, value) => MapEntry(key.toString(), value))
          : const {},
      createdAt: DateTime.fromMillisecondsSinceEpoch(_asInt(json['createdAt'])!),
      attempts: _asInt(json['attempts']) ?? 0,
      lastError: json['lastError'] as String?,
    );
  }

  static int? _asInt(Object? value) => switch (value) {
    int() => value,
    num() => value.toInt(),
    String() => int.tryParse(value),
    _ => null,
  };

  static SyncEntityType _parseEntity(Object? value) =>
      SyncEntityType.values.firstWhere(
        (entity) => entity.name == value,
        orElse: () => throw FormatException('Jenis sinkronisasi tidak dikenal: $value'),
      );

  static SyncOperation _parseOperation(Object? value) =>
      SyncOperation.values.firstWhere(
        (operation) => operation.name == value,
        orElse: () => throw FormatException('Operasi sinkronisasi tidak dikenal: $value'),
      );
}
