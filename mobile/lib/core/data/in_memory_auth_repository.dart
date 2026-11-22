import 'dart:convert';
import 'package:crypto/crypto.dart';

import '../../features/auth/model/cashier_invitation.dart';
import '../../features/auth/model/store_info.dart';
import '../../features/auth/model/store_member.dart';
import '../../features/auth/model/user_account.dart';
import '../../core/session/user_role.dart';
import 'auth_repository.dart';

/// Implementasi in-memory AuthRepository untuk pengujian dan state terisolasi.
class InMemoryAuthRepository implements AuthRepository {
  final Map<String, UserAccount> _usersById = {};
  final Map<String, String> _passwordHashes = {};
  final Map<String, String> _salts = {};
  final Map<String, StoreInfo> _stores = {};
  final List<StoreMember> _members = [];
  final List<CashierInvitation> _invitations = [];
  String? _currentUserId;

  static String _hashPassword(String password, String salt) {
    final bytes = utf8.encode('$salt:$password');
    return sha256.convert(bytes).toString();
  }

  @override
  Future<UserAccount> registerOwner({
    required String name,
    required String email,
    required String password,
    required String storeName,
    String? storeAddress,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    if (_usersById.values.any((u) => u.email.toLowerCase() == cleanEmail)) {
      throw const AuthException('Email sudah terdaftar.');
    }

    final userId = 'usr-${DateTime.now().millisecondsSinceEpoch}-${_usersById.length + 1}';
    final storeId = 'str-${DateTime.now().millisecondsSinceEpoch}';
    final salt = 'salt-${DateTime.now().microsecondsSinceEpoch}';

    final store = StoreInfo(
      id: storeId,
      name: storeName.trim(),
      ownerId: userId,
      address: storeAddress?.trim(),
      createdAt: DateTime.now(),
    );
    _stores[storeId] = store;

    final user = UserAccount(
      id: userId,
      name: name.trim(),
      email: cleanEmail,
      role: UserRole.owner,
      activeStoreId: storeId,
      createdAt: DateTime.now(),
    );

    _usersById[userId] = user;
    _passwordHashes[userId] = _hashPassword(password, salt);
    _salts[userId] = salt;
    _currentUserId = userId;

    return user;
  }

  @override
  Future<UserAccount> registerCashier({
    required String name,
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    if (_usersById.values.any((u) => u.email.toLowerCase() == cleanEmail)) {
      throw const AuthException('Email sudah terdaftar.');
    }

    final userId = 'usr-${DateTime.now().millisecondsSinceEpoch}-${_usersById.length + 1}';
    final salt = 'salt-${DateTime.now().microsecondsSinceEpoch}';

    final user = UserAccount(
      id: userId,
      name: name.trim(),
      email: cleanEmail,
      role: UserRole.cashier,
      activeStoreId: null, // Kasir baru belum memiliki toko
      createdAt: DateTime.now(),
    );

    _usersById[userId] = user;
    _passwordHashes[userId] = _hashPassword(password, salt);
    _salts[userId] = salt;
    _currentUserId = userId;

    return user;
  }

  @override
  Future<UserAccount> login({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final user = _usersById.values.cast<UserAccount?>().firstWhere(
      (u) => u?.email.toLowerCase() == cleanEmail,
      orElse: () => null,
    );

    if (user == null) {
      throw const AuthException('Email atau password salah.');
    }

    final salt = _salts[user.id] ?? '';
    final hash = _hashPassword(password, salt);
    if (_passwordHashes[user.id] != hash) {
      throw const AuthException('Email atau password salah.');
    }

    _currentUserId = user.id;
    return user;
  }

  @override
  Future<void> logout() async {
    _currentUserId = null;
  }

  @override
  Future<UserAccount?> getCurrentUser() async {
    final uid = _currentUserId;
    if (uid == null) return null;
    return _usersById[uid];
  }

  @override
  Future<StoreInfo?> getStore(String storeId) async {
    return _stores[storeId];
  }

  @override
  Future<CashierInvitation> createInvitation({
    required String storeId,
    required String cashierEmail,
  }) async {
    final cleanEmail = cashierEmail.trim().toLowerCase();
    final store = _stores[storeId];
    if (store == null) {
      throw const AuthException('Toko tidak ditemukan.');
    }

    final targetUser = _usersById.values.cast<UserAccount?>().firstWhere(
      (u) => u?.email.toLowerCase() == cleanEmail,
      orElse: () => null,
    );

    if (targetUser != null && targetUser.isOwner) {
      throw const AuthException('Tidak dapat mengundang akun Pemilik sebagai kasir.');
    }

    // Periksa apakah sudah menjadi anggota aktif
    final isAlreadyMember = _members.any(
      (m) => m.storeId == storeId && m.userEmail.toLowerCase() == cleanEmail && m.isActive,
    );
    if (isAlreadyMember) {
      throw const AuthException('Kasir sudah menjadi anggota aktif di toko ini.');
    }

    // Periksa apakah ada undangan pending yang aktif
    final hasPending = _invitations.any(
      (i) => i.storeId == storeId && i.cashierEmail.toLowerCase() == cleanEmail && i.isPending,
    );
    if (hasPending) {
      throw const AuthException('Undangan aktif untuk kasir ini sudah dikirimkan.');
    }

    final owner = _usersById[store.ownerId];
    final invitation = CashierInvitation(
      id: 'inv-${DateTime.now().millisecondsSinceEpoch}-${_invitations.length + 1}',
      storeId: storeId,
      storeName: store.name,
      ownerId: store.ownerId,
      ownerEmail: owner?.email ?? '',
      cashierEmail: cleanEmail,
      status: InvitationStatus.pending,
      createdAt: DateTime.now(),
    );

    _invitations.add(invitation);
    return invitation;
  }

  @override
  Future<List<CashierInvitation>> listStoreInvitations(String storeId) async {
    return _invitations.where((i) => i.storeId == storeId).toList();
  }

  @override
  Future<List<CashierInvitation>> listCashierInvitations(String cashierEmail) async {
    final cleanEmail = cashierEmail.trim().toLowerCase();
    return _invitations.where((i) => i.cashierEmail.toLowerCase() == cleanEmail).toList();
  }

  @override
  Future<void> acceptInvitation({
    required String invitationId,
    required String cashierId,
  }) async {
    final idx = _invitations.indexWhere((i) => i.id == invitationId);
    if (idx < 0) {
      throw const AuthException('Undangan tidak ditemukan.');
    }
    final inv = _invitations[idx];
    if (!inv.isPending) {
      throw const AuthException('Undangan sudah tidak berlaku.');
    }

    final cashier = _usersById[cashierId];
    if (cashier == null) {
      throw const AuthException('Akun kasir tidak ditemukan.');
    }

    // Update status undangan
    _invitations[idx] = inv.copyWith(
      status: InvitationStatus.accepted,
      respondedAt: DateTime.now(),
    );

    // Update / tambahkan keanggotaan toko
    final memberIdx = _members.indexWhere(
      (m) => m.storeId == inv.storeId && m.userId == cashierId,
    );
    if (memberIdx >= 0) {
      final old = _members[memberIdx];
      _members[memberIdx] = StoreMember(
        id: old.id,
        storeId: old.storeId,
        userId: old.userId,
        userName: cashier.name,
        userEmail: cashier.email,
        role: 'cashier',
        joinedAt: DateTime.now(),
        isActive: true,
      );
    } else {
      _members.add(
        StoreMember(
          id: 'mem-${DateTime.now().millisecondsSinceEpoch}-${_members.length + 1}',
          storeId: inv.storeId,
          userId: cashierId,
          userName: cashier.name,
          userEmail: cashier.email,
          role: 'cashier',
          joinedAt: DateTime.now(),
          isActive: true,
        ),
      );
    }

    // Hubungkan kasir ke toko
    _usersById[cashierId] = cashier.copyWith(activeStoreId: inv.storeId);
  }

  @override
  Future<void> rejectInvitation(String invitationId) async {
    final idx = _invitations.indexWhere((i) => i.id == invitationId);
    if (idx >= 0) {
      _invitations[idx] = _invitations[idx].copyWith(
        status: InvitationStatus.rejected,
        respondedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> cancelInvitation(String invitationId) async {
    final idx = _invitations.indexWhere((i) => i.id == invitationId);
    if (idx >= 0) {
      _invitations[idx] = _invitations[idx].copyWith(
        status: InvitationStatus.cancelled,
        respondedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<List<StoreMember>> listStoreMembers(String storeId) async {
    return _members.where((m) => m.storeId == storeId && m.isActive).toList();
  }

  @override
  Future<void> removeStoreMember({
    required String storeId,
    required String memberUserId,
  }) async {
    final idx = _members.indexWhere(
      (m) => m.storeId == storeId && m.userId == memberUserId,
    );
    if (idx >= 0) {
      final m = _members[idx];
      _members[idx] = StoreMember(
        id: m.id,
        storeId: m.storeId,
        userId: m.userId,
        userName: m.userName,
        userEmail: m.userEmail,
        role: m.role,
        joinedAt: m.joinedAt,
        isActive: false, // Dinonaktifkan, akun kasir tetap utuh
      );
    }

    // Cabut toko aktif dari kasir
    final cashier = _usersById[memberUserId];
    if (cashier != null && cashier.activeStoreId == storeId) {
      _usersById[memberUserId] = cashier.copyWith(clearStoreId: true);
    }
  }
}
