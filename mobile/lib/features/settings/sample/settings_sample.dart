import '../model/store_profile.dart';

/// Data profil dan teks untuk halaman pengaturan warung.
abstract final class SettingsSample {
  static const StoreProfile storeProfile = StoreProfile(
    name: 'RyanGunshop - Warung Modern',
    address: 'Jl. Sisingamangaraja No. 45, Medan',
    cashierCount: 2,
  );

  static const String rolesSectionTitle = 'Peran Pengguna';
  static const String rolesSectionNote =
      'Mode demo: peran dapat dipilih bebas, bukan autentikasi. Hanya pemilik dapat mengelola produk.';

  static const String floorPlanAccessTitle = 'Mode Edit Denah';
  static const String floorPlanAccessAllowed = 'Tersedia untuk peran Pemilik.';
  static const String floorPlanAccessLocked = 'Terkunci untuk peran Kasir.';

  static const String storeSectionTitle = 'Profil Warung';
  static const String sampleBadge = 'Data contoh';

  static const String hardwareSectionTitle = 'Perangkat Kasir';
  static const String printerStatus =
      'Printer Thermal 58mm (Bluetooth) • Terhubung';

  static const String syncSectionTitle = 'Sinkronisasi & Penyimpanan';
  static const String syncStatus = 'Penyimpanan Lokal Aktif • Sinkron Otomatis';

  static const String aboutSectionTitle = 'Tentang Aplikasi';
  static const String aboutDescription =
      'RyanGunshop POS v1.0.0 — Aplikasi kasir dan pengelolaan warung berbasis denah spasial.';
}
