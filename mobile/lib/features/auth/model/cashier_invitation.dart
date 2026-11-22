enum InvitationStatus {
  pending('Menunggu'),
  accepted('Diterima'),
  rejected('Ditolak'),
  cancelled('Dibatalkan');

  const InvitationStatus(this.label);
  final String label;

  static InvitationStatus fromString(String value) {
    for (final s in InvitationStatus.values) {
      if (s.name == value) return s;
    }
    return InvitationStatus.pending;
  }
}

/// Model data undangan kasir yang dikirimkan oleh Pemilik.
class CashierInvitation {
  const CashierInvitation({
    required this.id,
    required this.storeId,
    required this.storeName,
    required this.ownerId,
    required this.ownerEmail,
    required this.cashierEmail,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  final String id;
  final String storeId;
  final String storeName;
  final String ownerId;
  final String ownerEmail;
  final String cashierEmail;
  final InvitationStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  bool get isPending => status == InvitationStatus.pending;

  CashierInvitation copyWith({
    InvitationStatus? status,
    DateTime? respondedAt,
  }) {
    return CashierInvitation(
      id: id,
      storeId: storeId,
      storeName: storeName,
      ownerId: ownerId,
      ownerEmail: ownerEmail,
      cashierEmail: cashierEmail,
      status: status ?? this.status,
      createdAt: createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'store_id': storeId,
    'store_name': storeName,
    'owner_id': ownerId,
    'owner_email': ownerEmail,
    'cashier_email': cashierEmail,
    'status': status.name,
    'created_at': createdAt.toIso8601String(),
    'responded_at': respondedAt?.toIso8601String(),
  };

  factory CashierInvitation.fromMap(Map<String, dynamic> map) {
    return CashierInvitation(
      id: map['id'] as String,
      storeId: map['store_id'] as String,
      storeName: map['store_name'] as String,
      ownerId: map['owner_id'] as String,
      ownerEmail: map['owner_email'] as String,
      cashierEmail: map['cashier_email'] as String,
      status: InvitationStatus.fromString(map['status'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      respondedAt: map['responded_at'] != null
          ? DateTime.parse(map['responded_at'] as String)
          : null,
    );
  }
}
