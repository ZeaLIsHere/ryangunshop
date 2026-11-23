import 'package:flutter_test/flutter_test.dart';
import 'package:ryangunshop/core/data/auth_repository.dart';
import 'package:ryangunshop/core/data/in_memory_auth_repository.dart';
import 'package:ryangunshop/core/session/app_session.dart';
import 'package:ryangunshop/features/auth/model/cashier_invitation.dart';

void main() {
  group('Sistem Undangan dan Pengelolaan Kasir', () {
    late InMemoryAuthRepository authRepo;
    late AppSession session;

    setUp(() {
      authRepo = InMemoryAuthRepository();
      session = AppSession(authRepository: authRepo);
    });

    tearDown(() {
      session.dispose();
    });

    test('Alur lengkap: Owner mengundang kasir, kasir menerima, dan terhubung ke toko', () async {
      // 1. Owner mendaftar toko
      final owner = await session.registerOwner(
        name: 'Pak Bos',
        email: 'bos@toko.com',
        password: 'password123',
        storeName: 'Warung Sentosa',
      );
      final storeId = owner.activeStoreId!;

      // 2. Kasir mendaftar (belum punya toko)
      final cashier = await authRepo.registerCashier(
        name: 'Budi Kasir',
        email: 'budi@kasir.com',
        password: 'password123',
      );
      expect(cashier.hasActiveStore, isFalse);

      // 3. Owner membuat undangan ke email kasir
      final invitation = await authRepo.createInvitation(
        storeId: storeId,
        cashierEmail: 'budi@kasir.com',
      );
      expect(invitation.status, InvitationStatus.pending);
      expect(invitation.storeName, 'Warung Sentosa');
      expect(invitation.cashierEmail, 'budi@kasir.com');

      // 4. Kasir melihat daftar undangan masuk
      final cashierInvs = await authRepo.listCashierInvitations('budi@kasir.com');
      expect(cashierInvs.length, 1);
      expect(cashierInvs.first.id, invitation.id);

      // 5. Kasir menerima undangan
      await authRepo.acceptInvitation(
        invitationId: invitation.id,
        cashierId: cashier.id,
      );

      // 6. Verifikasi kasir sekarang terhubung ke toko
      final updatedCashier = await authRepo.getCurrentUser();
      expect(updatedCashier, isNotNull);
      // Login sebagai kasir untuk cek currentUser
      final loggedInCashier = await authRepo.login(email: 'budi@kasir.com', password: 'password123');
      expect(loggedInCashier.activeStoreId, storeId);
      expect(loggedInCashier.hasActiveStore, isTrue);

      // 7. Owner melihat kasir dalam daftar anggota toko
      final members = await authRepo.listStoreMembers(storeId);
      expect(members.length, 1);
      expect(members.first.userId, cashier.id);
      expect(members.first.userEmail, 'budi@kasir.com');
      expect(members.first.isActive, isTrue);
    });

    test('Kasir dapat menolak undangan', () async {
      final owner = await authRepo.registerOwner(
        name: 'Owner Toko',
        email: 'owner@test.com',
        password: 'password123',
        storeName: 'Toko Keren',
      );

      await authRepo.registerCashier(
        name: 'Kasir Satu',
        email: 'kasir1@test.com',
        password: 'password123',
      );

      final inv = await authRepo.createInvitation(
        storeId: owner.activeStoreId!,
        cashierEmail: 'kasir1@test.com',
      );

      await authRepo.rejectInvitation(inv.id);

      final invitations = await authRepo.listStoreInvitations(owner.activeStoreId!);
      expect(invitations.first.status, InvitationStatus.rejected);

      // Kasir tetap tidak memiliki toko
      final cashier = await authRepo.login(email: 'kasir1@test.com', password: 'password123');
      expect(cashier.hasActiveStore, isFalse);
    });

    test('Owner dapat membatalkan undangan yang masih pending', () async {
      final owner = await authRepo.registerOwner(
        name: 'Owner',
        email: 'owner2@test.com',
        password: 'password123',
        storeName: 'Toko Baru',
      );

      await authRepo.registerCashier(
        name: 'Calon Kasir',
        email: 'calon@kasir.com',
        password: 'password123',
      );

      final inv = await authRepo.createInvitation(
        storeId: owner.activeStoreId!,
        cashierEmail: 'calon@kasir.com',
      );
      expect(inv.status, InvitationStatus.pending);

      await authRepo.cancelInvitation(inv.id);

      final invitations = await authRepo.listStoreInvitations(owner.activeStoreId!);
      expect(invitations.first.status, InvitationStatus.cancelled);
    });

    test('Undangan ganda yang masih aktif dicegah', () async {
      final owner = await authRepo.registerOwner(
        name: 'Owner',
        email: 'owner3@test.com',
        password: 'password123',
        storeName: 'Toko Tiga',
      );

      await authRepo.registerCashier(
        name: 'Kasir',
        email: 'kasir3@test.com',
        password: 'password123',
      );

      await authRepo.createInvitation(
        storeId: owner.activeStoreId!,
        cashierEmail: 'kasir3@test.com',
      );

      // Percobaan kedua mengirim undangan ke email yang sama
      expect(
        () => authRepo.createInvitation(
          storeId: owner.activeStoreId!,
          cashierEmail: 'kasir3@test.com',
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('Owner tidak dapat mengundang akun Owner lain sebagai kasir', () async {
      final owner1 = await authRepo.registerOwner(
        name: 'Owner 1',
        email: 'ownerA@test.com',
        password: 'password123',
        storeName: 'Toko A',
      );

      await authRepo.registerOwner(
        name: 'Owner 2',
        email: 'ownerB@test.com',
        password: 'password123',
        storeName: 'Toko B',
      );

      expect(
        () => authRepo.createInvitation(
          storeId: owner1.activeStoreId!,
          cashierEmail: 'ownerB@test.com',
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('Melepas kasir mencabut akses toko tanpa menghapus akun kasir', () async {
      final owner = await authRepo.registerOwner(
        name: 'Owner',
        email: 'owner_del@test.com',
        password: 'password123',
        storeName: 'Toko Lepas',
      );
      final storeId = owner.activeStoreId!;

      final cashier = await authRepo.registerCashier(
        name: 'Kasir Lepas',
        email: 'kasir_lepas@test.com',
        password: 'password123',
      );

      final inv = await authRepo.createInvitation(
        storeId: storeId,
        cashierEmail: 'kasir_lepas@test.com',
      );

      await authRepo.acceptInvitation(
        invitationId: inv.id,
        cashierId: cashier.id,
      );

      // Verifikasi aktif
      var members = await authRepo.listStoreMembers(storeId);
      expect(members.length, 1);

      // Owner melepas kasir
      await authRepo.removeStoreMember(
        storeId: storeId,
        memberUserId: cashier.id,
      );

      // Kasir aktif di toko menjadi 0
      members = await authRepo.listStoreMembers(storeId);
      expect(members.isEmpty, isTrue);

      // Akun kasir tetap dapat login tetapi activeStoreId sudah hilang
      final reloadedCashier = await authRepo.login(
        email: 'kasir_lepas@test.com',
        password: 'password123',
      );
      expect(reloadedCashier.id, cashier.id);
      expect(reloadedCashier.hasActiveStore, isFalse);

      // Kasir dapat diundang kembali
      final newInv = await authRepo.createInvitation(
        storeId: storeId,
        cashierEmail: 'kasir_lepas@test.com',
      );
      expect(newInv.status, InvitationStatus.pending);
    });
  });
}
