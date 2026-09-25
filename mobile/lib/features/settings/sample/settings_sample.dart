import '../model/store_profile.dart';

/// Data contoh dan teks untuk halaman pengaturan.
///
/// Semua nilai di sini adalah contoh dan diberi penanda "Data contoh" pada layar.
abstract final class SettingsSample {
  static const StoreProfile storeProfile = StoreProfile(
    name: 'Warung Ryan',
    address: 'Jl. Melati No. 12',
    cashierCount: 2,
  );

  static const String rolesSectionTitle = 'Peran pengguna';
  static const String rolesSectionNote =
      'Pemilihan peran masih contoh. Setelah autentikasi tersedia, peran ditentukan '
      'dari akun yang masuk.';

  static const String floorPlanAccessTitle = 'Mode edit denah';
  static const String floorPlanAccessAllowed = 'Tersedia untuk peran Pemilik.';
  static const String floorPlanAccessLocked = 'Terkunci untuk peran Kasir.';

  static const String storeSectionTitle = 'Info warung';
  static const String sampleBadge = 'Data contoh';

  static const String aboutSectionTitle = 'Tentang aplikasi';
  static const String aboutDescription =
      'Versi pratinjau UI. Seluruh data pada versi ini adalah contoh dan belum '
      'terhubung layanan nyata.';
}
