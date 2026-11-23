/// Model data warung/toko milik Owner.
class StoreInfo {
  const StoreInfo({
    required this.id,
    required this.name,
    required this.ownerId,
    this.address,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String ownerId;
  final String? address;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'owner_id': ownerId,
    'address': address,
    'created_at': createdAt.toIso8601String(),
  };

  factory StoreInfo.fromMap(Map<String, dynamic> map) {
    return StoreInfo(
      id: map['id'] as String,
      name: map['name'] as String,
      ownerId: map['owner_id'] as String,
      address: map['address'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
