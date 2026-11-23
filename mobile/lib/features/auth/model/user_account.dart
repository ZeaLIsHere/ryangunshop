import '../../../core/session/user_role.dart';

/// Model akun pengguna terautentikasi dalam aplikasi RyanGunshop.
class UserAccount {
  const UserAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.activeStoreId,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? activeStoreId;
  final DateTime createdAt;

  bool get isOwner => role == UserRole.owner;
  bool get isCashier => role == UserRole.cashier;
  bool get hasActiveStore => activeStoreId != null && activeStoreId!.isNotEmpty;

  UserAccount copyWith({
    String? name,
    String? activeStoreId,
    bool clearStoreId = false,
  }) {
    return UserAccount(
      id: id,
      name: name ?? this.name,
      email: email,
      role: role,
      activeStoreId: clearStoreId ? null : (activeStoreId ?? this.activeStoreId),
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role.name,
    'active_store_id': activeStoreId,
    'created_at': createdAt.toIso8601String(),
  };

  factory UserAccount.fromMap(Map<String, dynamic> map) {
    return UserAccount(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      role: (map['role'] as String) == 'cashier'
          ? UserRole.cashier
          : UserRole.owner,
      activeStoreId: map['active_store_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
