import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';

import '../../features/auth/model/cashier_invitation.dart';
import '../../features/auth/model/store_info.dart';
import '../../features/auth/model/store_member.dart';
import '../../features/auth/model/user_account.dart';
import '../../core/session/user_role.dart';
import 'app_database.dart';
import 'auth_repository.dart';

/// Implementasi AuthRepository berbasis SQLite/Drift.
class DriftAuthRepository implements AuthRepository {
  DriftAuthRepository(this.database);

  final AppDatabase database;

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
    final existing = await database.customSelect(
      'SELECT id FROM app_users WHERE LOWER(email) = ?',
      variables: [Variable.withString(cleanEmail)],
    ).getSingleOrNull();

    if (existing != null) {
      throw const AuthException('Email sudah terdaftar.');
    }

    final userId = 'usr-${DateTime.now().millisecondsSinceEpoch}';
    final storeId = 'str-${DateTime.now().millisecondsSinceEpoch}';
    final salt = 'salt-${DateTime.now().microsecondsSinceEpoch}';
    final now = DateTime.now().toIso8601String();
    final hash = _hashPassword(password, salt);

    await database.transaction(() async {
      // 1. Simpan toko
      await database.customInsert(
        'INSERT INTO app_stores (id, name, owner_id, address, created_at) VALUES (?, ?, ?, ?, ?)',
        variables: [
          Variable.withString(storeId),
          Variable.withString(storeName.trim()),
          Variable.withString(userId),
          Variable.withString(storeAddress?.trim() ?? ''),
          Variable.withString(now),
        ],
      );

      // 2. Simpan user
      await database.customInsert(
        'INSERT INTO app_users (id, email, name, password_hash, salt, role, active_store_id, created_at) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        variables: [
          Variable.withString(userId),
          Variable.withString(cleanEmail),
          Variable.withString(name.trim()),
          Variable.withString(hash),
          Variable.withString(salt),
          Variable.withString('owner'),
          Variable.withString(storeId),
          Variable.withString(now),
        ],
      );

      // 3. Simpan sesi aktif
      await database.customStatement(
        'INSERT OR REPLACE INTO app_active_sessions (id, user_id, logged_in_at) VALUES (1, ?, ?)',
        [userId, now],
      );
    });

    return UserAccount(
      id: userId,
      name: name.trim(),
      email: cleanEmail,
      role: UserRole.owner,
      activeStoreId: storeId,
      createdAt: DateTime.parse(now),
    );
  }

  @override
  Future<UserAccount> registerCashier({
    required String name,
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final existing = await database.customSelect(
      'SELECT id FROM app_users WHERE LOWER(email) = ?',
      variables: [Variable.withString(cleanEmail)],
    ).getSingleOrNull();

    if (existing != null) {
      throw const AuthException('Email sudah terdaftar.');
    }

    final userId = 'usr-${DateTime.now().millisecondsSinceEpoch}';
    final salt = 'salt-${DateTime.now().microsecondsSinceEpoch}';
    final now = DateTime.now().toIso8601String();
    final hash = _hashPassword(password, salt);

    await database.transaction(() async {
      await database.customInsert(
        'INSERT INTO app_users (id, email, name, password_hash, salt, role, active_store_id, created_at) '
        'VALUES (?, ?, ?, ?, ?, ?, NULL, ?)',
        variables: [
          Variable.withString(userId),
          Variable.withString(cleanEmail),
          Variable.withString(name.trim()),
          Variable.withString(hash),
          Variable.withString(salt),
          Variable.withString('cashier'),
          Variable.withString(now),
        ],
      );

      // Simpan sesi aktif
      await database.customStatement(
        'INSERT OR REPLACE INTO app_active_sessions (id, user_id, logged_in_at) VALUES (1, ?, ?)',
        [userId, now],
      );
    });

    return UserAccount(
      id: userId,
      name: name.trim(),
      email: cleanEmail,
      role: UserRole.cashier,
      activeStoreId: null,
      createdAt: DateTime.parse(now),
    );
  }

  @override
  Future<UserAccount> login({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final row = await database.customSelect(
      'SELECT * FROM app_users WHERE LOWER(email) = ?',
      variables: [Variable.withString(cleanEmail)],
    ).getSingleOrNull();

    if (row == null) {
      throw const AuthException('Email atau password salah.');
    }

    final salt = row.read<String>('salt');
    final storedHash = row.read<String>('password_hash');
    final computedHash = _hashPassword(password, salt);

    if (storedHash != computedHash) {
      throw const AuthException('Email atau password salah.');
    }

    final userId = row.read<String>('id');
    final now = DateTime.now().toIso8601String();

    await database.customStatement(
      'INSERT OR REPLACE INTO app_active_sessions (id, user_id, logged_in_at) VALUES (1, ?, ?)',
      [userId, now],
    );

    return UserAccount(
      id: userId,
      name: row.read<String>('name'),
      email: row.read<String>('email'),
      role: row.read<String>('role') == 'cashier' ? UserRole.cashier : UserRole.owner,
      activeStoreId: row.readNullable<String>('active_store_id'),
      createdAt: DateTime.parse(row.read<String>('created_at')),
    );
  }

  @override
  Future<void> logout() async {
    await database.customStatement('DELETE FROM app_active_sessions WHERE id = 1');
  }

  @override
  Future<UserAccount?> getCurrentUser() async {
    final sessionRow = await database.customSelect(
      'SELECT user_id FROM app_active_sessions WHERE id = 1',
    ).getSingleOrNull();

    if (sessionRow == null) return null;
    final userId = sessionRow.read<String>('user_id');

    final userRow = await database.customSelect(
      'SELECT * FROM app_users WHERE id = ?',
      variables: [Variable.withString(userId)],
    ).getSingleOrNull();

    if (userRow == null) return null;

    return UserAccount(
      id: userRow.read<String>('id'),
      name: userRow.read<String>('name'),
      email: userRow.read<String>('email'),
      role: userRow.read<String>('role') == 'cashier' ? UserRole.cashier : UserRole.owner,
      activeStoreId: userRow.readNullable<String>('active_store_id'),
      createdAt: DateTime.parse(userRow.read<String>('created_at')),
    );
  }

  @override
  Future<StoreInfo?> getStore(String storeId) async {
    final row = await database.customSelect(
      'SELECT * FROM app_stores WHERE id = ?',
      variables: [Variable.withString(storeId)],
    ).getSingleOrNull();

    if (row == null) return null;

    return StoreInfo(
      id: row.read<String>('id'),
      name: row.read<String>('name'),
      ownerId: row.read<String>('owner_id'),
      address: row.readNullable<String>('address'),
      createdAt: DateTime.parse(row.read<String>('created_at')),
    );
  }

  @override
  Future<CashierInvitation> createInvitation({
    required String storeId,
    required String cashierEmail,
  }) async {
    final cleanEmail = cashierEmail.trim().toLowerCase();

    final store = await getStore(storeId);
    if (store == null) {
      throw const AuthException('Toko tidak ditemukan.');
    }

    final targetUserRow = await database.customSelect(
      'SELECT * FROM app_users WHERE LOWER(email) = ?',
      variables: [Variable.withString(cleanEmail)],
    ).getSingleOrNull();

    if (targetUserRow != null && targetUserRow.read<String>('role') == 'owner') {
      throw const AuthException('Tidak dapat mengundang akun Pemilik sebagai kasir.');
    }

    final activeMember = await database.customSelect(
      'SELECT m.id FROM app_store_memberships m '
      'JOIN app_users u ON m.user_id = u.id '
      'WHERE m.store_id = ? AND LOWER(u.email) = ? AND m.is_active = 1',
      variables: [Variable.withString(storeId), Variable.withString(cleanEmail)],
    ).getSingleOrNull();

    if (activeMember != null) {
      throw const AuthException('Kasir sudah menjadi anggota aktif di toko ini.');
    }

    final pendingInv = await database.customSelect(
      'SELECT id FROM app_cashier_invitations WHERE store_id = ? AND LOWER(cashier_email) = ? AND status = ?',
      variables: [
        Variable.withString(storeId),
        Variable.withString(cleanEmail),
        Variable.withString('pending'),
      ],
    ).getSingleOrNull();

    if (pendingInv != null) {
      throw const AuthException('Undangan aktif untuk kasir ini sudah dikirimkan.');
    }

    final ownerRow = await database.customSelect(
      'SELECT email FROM app_users WHERE id = ?',
      variables: [Variable.withString(store.ownerId)],
    ).getSingleOrNull();

    final invId = 'inv-${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now().toIso8601String();
    final ownerEmail = ownerRow?.read<String>('email') ?? '';

    await database.customInsert(
      'INSERT INTO app_cashier_invitations (id, store_id, store_name, owner_id, owner_email, cashier_email, status, created_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      variables: [
        Variable.withString(invId),
        Variable.withString(storeId),
        Variable.withString(store.name),
        Variable.withString(store.ownerId),
        Variable.withString(ownerEmail),
        Variable.withString(cleanEmail),
        Variable.withString('pending'),
        Variable.withString(now),
      ],
    );

    return CashierInvitation(
      id: invId,
      storeId: storeId,
      storeName: store.name,
      ownerId: store.ownerId,
      ownerEmail: ownerEmail,
      cashierEmail: cleanEmail,
      status: InvitationStatus.pending,
      createdAt: DateTime.parse(now),
    );
  }

  @override
  Future<List<CashierInvitation>> listStoreInvitations(String storeId) async {
    final rows = await database.customSelect(
      'SELECT * FROM app_cashier_invitations WHERE store_id = ? ORDER BY created_at DESC',
      variables: [Variable.withString(storeId)],
    ).get();

    return rows.map((r) => CashierInvitation(
      id: r.read<String>('id'),
      storeId: r.read<String>('store_id'),
      storeName: r.read<String>('store_name'),
      ownerId: r.read<String>('owner_id'),
      ownerEmail: r.read<String>('owner_email'),
      cashierEmail: r.read<String>('cashier_email'),
      status: InvitationStatus.fromString(r.read<String>('status')),
      createdAt: DateTime.parse(r.read<String>('created_at')),
      respondedAt: r.readNullable<String>('responded_at') != null
          ? DateTime.parse(r.read<String>('responded_at'))
          : null,
    )).toList();
  }

  @override
  Future<List<CashierInvitation>> listCashierInvitations(String cashierEmail) async {
    final rows = await database.customSelect(
      'SELECT * FROM app_cashier_invitations WHERE LOWER(cashier_email) = ? ORDER BY created_at DESC',
      variables: [Variable.withString(cashierEmail.trim().toLowerCase())],
    ).get();

    return rows.map((r) => CashierInvitation(
      id: r.read<String>('id'),
      storeId: r.read<String>('store_id'),
      storeName: r.read<String>('store_name'),
      ownerId: r.read<String>('owner_id'),
      ownerEmail: r.read<String>('owner_email'),
      cashierEmail: r.read<String>('cashier_email'),
      status: InvitationStatus.fromString(r.read<String>('status')),
      createdAt: DateTime.parse(r.read<String>('created_at')),
      respondedAt: r.readNullable<String>('responded_at') != null
          ? DateTime.parse(r.read<String>('responded_at'))
          : null,
    )).toList();
  }

  @override
  Future<void> acceptInvitation({
    required String invitationId,
    required String cashierId,
  }) async {
    final invRow = await database.customSelect(
      'SELECT * FROM app_cashier_invitations WHERE id = ?',
      variables: [Variable.withString(invitationId)],
    ).getSingleOrNull();

    if (invRow == null) {
      throw const AuthException('Undangan tidak ditemukan.');
    }

    final status = invRow.read<String>('status');
    if (status != 'pending') {
      throw const AuthException('Undangan sudah tidak berlaku.');
    }

    final storeId = invRow.read<String>('store_id');
    final now = DateTime.now().toIso8601String();

    await database.transaction(() async {
      // 1. Update status undangan
      await database.customStatement(
        'UPDATE app_cashier_invitations SET status = ?, responded_at = ? WHERE id = ?',
        ['accepted', now, invitationId],
      );

      // 2. Hubungkan kasir ke toko
      await database.customStatement(
        'UPDATE app_users SET active_store_id = ? WHERE id = ?',
        [storeId, cashierId],
      );

      // 3. Tambah atau aktifkan keanggotaan
      final existingMember = await database.customSelect(
        'SELECT id FROM app_store_memberships WHERE store_id = ? AND user_id = ?',
        variables: [Variable.withString(storeId), Variable.withString(cashierId)],
      ).getSingleOrNull();

      if (existingMember != null) {
        await database.customStatement(
          'UPDATE app_store_memberships SET is_active = 1, joined_at = ? WHERE store_id = ? AND user_id = ?',
          [now, storeId, cashierId],
        );
      } else {
        final memberId = 'mem-${DateTime.now().millisecondsSinceEpoch}';
        await database.customInsert(
          'INSERT INTO app_store_memberships (id, store_id, user_id, role, joined_at, is_active) '
          'VALUES (?, ?, ?, ?, ?, 1)',
          variables: [
            Variable.withString(memberId),
            Variable.withString(storeId),
            Variable.withString(cashierId),
            Variable.withString('cashier'),
            Variable.withString(now),
          ],
        );
      }
    });
  }

  @override
  Future<void> rejectInvitation(String invitationId) async {
    final now = DateTime.now().toIso8601String();
    await database.customStatement(
      'UPDATE app_cashier_invitations SET status = ?, responded_at = ? WHERE id = ?',
      ['rejected', now, invitationId],
    );
  }

  @override
  Future<void> cancelInvitation(String invitationId) async {
    final now = DateTime.now().toIso8601String();
    await database.customStatement(
      'UPDATE app_cashier_invitations SET status = ?, responded_at = ? WHERE id = ?',
      ['cancelled', now, invitationId],
    );
  }

  @override
  Future<List<StoreMember>> listStoreMembers(String storeId) async {
    final rows = await database.customSelect(
      'SELECT m.*, u.name as user_name, u.email as user_email '
      'FROM app_store_memberships m '
      'JOIN app_users u ON m.user_id = u.id '
      'WHERE m.store_id = ? AND m.is_active = 1 '
      'ORDER BY m.joined_at DESC',
      variables: [Variable.withString(storeId)],
    ).get();

    return rows.map((r) => StoreMember(
      id: r.read<String>('id'),
      storeId: r.read<String>('store_id'),
      userId: r.read<String>('user_id'),
      userName: r.read<String>('user_name'),
      userEmail: r.read<String>('user_email'),
      role: r.read<String>('role'),
      joinedAt: DateTime.parse(r.read<String>('joined_at')),
      isActive: r.read<int>('is_active') == 1,
    )).toList();
  }

  @override
  Future<void> removeStoreMember({
    required String storeId,
    required String memberUserId,
  }) async {
    await database.transaction(() async {
      await database.customStatement(
        'UPDATE app_store_memberships SET is_active = 0 WHERE store_id = ? AND user_id = ?',
        [storeId, memberUserId],
      );

      // Cabut toko aktif bila kasir tersebut sedang terhubung ke toko ini
      await database.customStatement(
        'UPDATE app_users SET active_store_id = NULL WHERE id = ? AND active_store_id = ?',
        [memberUserId, storeId],
      );
    });
  }
}
