import '../../features/auth/model/cashier_invitation.dart';
import '../../features/auth/model/store_info.dart';
import '../../features/auth/model/store_member.dart';
import '../../features/auth/model/user_account.dart';

/// Pengecualian pada proses autentikasi dan otorisasi.
class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Kontrak abstraksi penyimpanan dan layanan autentikasi.
abstract class AuthRepository {
  /// Mendaftarkan pengguna baru sebagai Pemilik toko.
  Future<UserAccount> registerOwner({
    required String name,
    required String email,
    required String password,
    required String storeName,
    String? storeAddress,
  });

  /// Mendaftarkan pengguna baru sebagai Kasir (tanpa toko otomatis).
  Future<UserAccount> registerCashier({
    required String name,
    required String email,
    required String password,
  });

  /// Masuk dengan email dan password.
  Future<UserAccount> login({
    required String email,
    required String password,
  });

  /// Keluar dari sesi aplikasi.
  Future<void> logout();

  /// Mengambil data pengguna aktif saat ini.
  Future<UserAccount?> getCurrentUser();

  /// Mengambil informasi toko berdasarkan ID.
  Future<StoreInfo?> getStore(String storeId);

  /// Membuat dan mengirimkan undangan kasir ke email tujuan.
  Future<CashierInvitation> createInvitation({
    required String storeId,
    required String cashierEmail,
  });

  /// Mengambil daftar undangan yang diterbitkan oleh toko tertentu.
  Future<List<CashierInvitation>> listStoreInvitations(String storeId);

  /// Mengambil daftar undangan masuk untuk email kasir tertentu.
  Future<List<CashierInvitation>> listCashierInvitations(String cashierEmail);

  /// Menerima undangan kasir.
  Future<void> acceptInvitation({
    required String invitationId,
    required String cashierId,
  });

  /// Menolak undangan kasir.
  Future<void> rejectInvitation(String invitationId);

  /// Membatalkan undangan kasir oleh Pemilik.
  Future<void> cancelInvitation(String invitationId);

  /// Mengambil daftar kasir aktif yang tergabung dalam toko.
  Future<List<StoreMember>> listStoreMembers(String storeId);

  /// Melepas kasir dari toko (menonaktifkan keanggotaan).
  Future<void> removeStoreMember({
    required String storeId,
    required String memberUserId,
  });
}
