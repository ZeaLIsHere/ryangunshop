/// Keanggotaan kasir pada suatu toko.
class StoreMember {
  const StoreMember({
    required this.id,
    required this.storeId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.role,
    required this.joinedAt,
    required this.isActive,
  });

  final String id;
  final String storeId;
  final String userId;
  final String userName;
  final String userEmail;
  final String role;
  final DateTime joinedAt;
  final bool isActive;

  Map<String, dynamic> toMap() => {
    'id': id,
    'store_id': storeId,
    'user_id': userId,
    'user_name': userName,
    'user_email': userEmail,
    'role': role,
    'joined_at': joinedAt.toIso8601String(),
    'is_active': isActive ? 1 : 0,
  };

  factory StoreMember.fromMap(Map<String, dynamic> map) {
    return StoreMember(
      id: map['id'] as String,
      storeId: map['store_id'] as String,
      userId: map['user_id'] as String,
      userName: map['user_name'] as String,
      userEmail: map['user_email'] as String,
      role: map['role'] as String,
      joinedAt: DateTime.parse(map['joined_at'] as String),
      isActive: (map['is_active'] as int? ?? 1) == 1,
    );
  }
}
