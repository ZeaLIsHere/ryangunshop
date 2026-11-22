import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ryangunshop/app/routing/app_router.dart';
import 'package:ryangunshop/core/data/in_memory_auth_repository.dart';
import 'package:ryangunshop/core/session/app_session.dart';
import 'package:ryangunshop/core/theme/app_theme.dart';
import 'package:ryangunshop/features/auth/view/login_screen.dart';
import 'package:ryangunshop/features/auth/view/register_screen.dart';
import 'package:ryangunshop/features/cashier_management/view/cashier_management_screen.dart';

void main() {
  group('Pengujian Widget UI Autentikasi dan Kelola Kasir', () {
    late InMemoryAuthRepository authRepo;
    late AppSession session;

    setUp(() {
      authRepo = InMemoryAuthRepository();
      session = AppSession(authRepository: authRepo);
    });

    tearDown(() {
      session.dispose();
    });

    Widget createTestApp(Widget child) {
      return AppSessionScope(
        session: session,
        child: MaterialApp(
          theme: AppTheme.light(),
          onGenerateRoute: AppRouter.onGenerateRoute,
          home: child,
        ),
      );
    }

    testWidgets('LoginScreen menampilkan form email, password, dan tombol masuk', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp(const LoginScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Masuk ke Akun Anda'), findsOneWidget);
      expect(find.text('Email Pengguna'), findsOneWidget);
      expect(find.text('Kata Sandi'), findsOneWidget);
      expect(find.text('Masuk Sekarang'), findsOneWidget);
      expect(find.text('Daftar Baru'), findsOneWidget);

      // Coba submit tanpa input -> pesan error muncul
      await tester.tap(find.text('Masuk Sekarang'));
      await tester.pumpAndSettle();

      expect(find.text('Email dan password tidak boleh kosong.'), findsOneWidget);
    });

    testWidgets('RegisterScreen beralih form antara Pemilik Toko dan Kasir', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp(const RegisterScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Daftar Akun Baru'), findsOneWidget);
      expect(find.text('Pemilik Toko'), findsOneWidget);
      expect(find.text('Kasir'), findsOneWidget);

      // Awalnya peran Pemilik Toko aktif -> ada field Nama Toko
      expect(find.text('Informasi Toko / Warung'), findsOneWidget);
      expect(find.text('Nama Toko'), findsOneWidget);

      // Klik peran Kasir
      await tester.tap(find.text('Kasir'));
      await tester.pumpAndSettle();

      // Field Nama Toko hilang, digantikan catatan khusus kasir
      expect(find.text('Informasi Toko / Warung'), findsNothing);
      expect(
        find.textContaining('Akun Kasir tidak memiliki toko otomatis'),
        findsOneWidget,
      );
      expect(find.text('Daftar sebagai Kasir'), findsOneWidget);
    });

    testWidgets('CashierManagementScreen membatasi akses bila bukan Pemilik', (
      tester,
    ) async {
      // Daftarkan sebagai kasir
      await session.registerCashier(
        name: 'Kasir Saja',
        email: 'kasir_only@test.com',
        password: 'password123',
      );

      await tester.pumpWidget(createTestApp(const CashierManagementScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Akses Terbatas'), findsOneWidget);
      expect(
        find.text('Halaman ini hanya dapat diakses oleh Pemilik toko.'),
        findsOneWidget,
      );
    });

    testWidgets('CashierManagementScreen menampilkan daftar kasir dan tombol undang untuk Pemilik', (
      tester,
    ) async {
      // Daftarkan sebagai pemilik
      await session.registerOwner(
        name: 'Pak Bos',
        email: 'bos_ui@test.com',
        password: 'password123',
        storeName: 'Toko Berkah UI',
      );

      await tester.pumpWidget(createTestApp(const CashierManagementScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Kelola Kasir Toko'), findsOneWidget);
      expect(find.text('Kasir Aktif'), findsOneWidget);
      expect(find.text('Undangan'), findsOneWidget);
      expect(find.text('Undang Kasir'), findsOneWidget);
    });
  });
}
