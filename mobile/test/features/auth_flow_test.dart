import 'package:flutter_test/flutter_test.dart';
import 'package:ryangunshop/core/data/auth_repository.dart';
import 'package:ryangunshop/core/data/in_memory_auth_repository.dart';
import 'package:ryangunshop/core/session/app_session.dart';
import 'package:ryangunshop/core/session/user_role.dart';

void main() {
  group('Sistem Autentikasi dan Sesi (Auth Flow Test)', () {
    late InMemoryAuthRepository authRepo;
    late AppSession session;

    setUp(() {
      authRepo = InMemoryAuthRepository();
      session = AppSession(authRepository: authRepo);
    });

    tearDown(() {
      session.dispose();
    });

    test('Register Owner berhasil dan otomatis membuat toko', () async {
      final user = await session.registerOwner(
        name: 'Pak Ryan Owner',
        email: 'owner@warung.com',
        password: 'password123',
        storeName: 'Warung Berkah Ryan',
        storeAddress: 'Jl. Utama No. 1',
      );

      expect(user.id, isNotEmpty);
      expect(user.name, 'Pak Ryan Owner');
      expect(user.email, 'owner@warung.com');
      expect(user.role, UserRole.owner);
      expect(user.isOwner, isTrue);
      expect(user.activeStoreId, isNotNull);
      expect(session.isAuthenticated, isTrue);
      expect(session.isOwner, isTrue);

      final store = await authRepo.getStore(user.activeStoreId!);
      expect(store, isNotNull);
      expect(store!.name, 'Warung Berkah Ryan');
      expect(store.ownerId, user.id);
    });

    test('Register Kasir berhasil tanpa toko otomatis (belum terhubung toko)', () async {
      final user = await session.registerCashier(
        name: 'Andi Kasir',
        email: 'andi@kasir.com',
        password: 'password123',
      );

      expect(user.id, isNotEmpty);
      expect(user.name, 'Andi Kasir');
      expect(user.email, 'andi@kasir.com');
      expect(user.role, UserRole.cashier);
      expect(user.isCashier, isTrue);
      expect(user.activeStoreId, isNull);
      expect(user.hasActiveStore, isFalse);

      expect(session.isAuthenticated, isTrue);
      expect(session.isCashier, isTrue);
      expect(session.isCashierLinkedToStore, isFalse);
    });

    test('Pendaftaran dengan email yang sama ditolak', () async {
      await session.registerCashier(
        name: 'User Satu',
        email: 'duplikat@test.com',
        password: 'password123',
      );

      expect(
        () => session.registerCashier(
          name: 'User Dua',
          email: 'duplikat@test.com',
          password: 'password456',
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('Login dengan kredensial yang valid berhasil', () async {
      await authRepo.registerOwner(
        name: 'Pemilik Toko',
        email: 'pemilik@toko.com',
        password: 'securePassword123',
        storeName: 'Toko Maju',
      );
      await session.logout();

      expect(session.isAuthenticated, isFalse);

      final loggedIn = await session.login('pemilik@toko.com', 'securePassword123');
      expect(loggedIn.email, 'pemilik@toko.com');
      expect(loggedIn.role, UserRole.owner);
      expect(session.isAuthenticated, isTrue);
      expect(session.currentUser?.id, loggedIn.id);
    });

    test('Login dengan password salah ditolak', () async {
      await authRepo.registerCashier(
        name: 'Budi Kasir',
        email: 'budi@kasir.com',
        password: 'correctPassword',
      );
      await session.logout();

      expect(
        () => session.login('budi@kasir.com', 'wrongPassword'),
        throwsA(isA<AuthException>()),
      );
      expect(session.isAuthenticated, isFalse);
    });

    test('Logout menghapus sesi aktif pengguna', () async {
      await session.registerOwner(
        name: 'Pemilik',
        email: 'pemilik@test.com',
        password: 'password123',
        storeName: 'Toko Test',
      );
      expect(session.isAuthenticated, isTrue);

      await session.logout();
      expect(session.isAuthenticated, isFalse);
      expect(session.currentUser, isNull);
      expect(session.currentStore, isNull);
    });

    test('Otorisasi peran: Kasir tidak memiliki hak kelola produk dan denah', () async {
      final cashier = await session.registerCashier(
        name: 'Siti Kasir',
        email: 'siti@kasir.com',
        password: 'password123',
      );

      expect(cashier.role.canManageProducts, isFalse);
      expect(cashier.role.canEditFloorPlan, isFalse);
    });

    test('Otorisasi peran: Pemilik memiliki hak penuh atas produk dan denah', () async {
      final owner = await session.registerOwner(
        name: 'Doni Pemilik',
        email: 'doni@owner.com',
        password: 'password123',
        storeName: 'Warung Doni',
      );

      expect(owner.role.canManageProducts, isTrue);
      expect(owner.role.canEditFloorPlan, isTrue);
    });
  });
}
