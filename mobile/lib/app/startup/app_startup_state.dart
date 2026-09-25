/// Keadaan awal aplikasi dalam satu sesi berjalan.
///
/// Tahap ini belum memakai penyimpanan lokal, jadi penanda "sudah melihat
/// perkenalan" hanya bertahan selama proses aplikasi hidup. Setelah lapisan data
/// tersedia, penanda ini diganti penyimpanan tetap tanpa mengubah pemakainya.
abstract final class AppStartupState {
  static bool _hasSeenOnboarding = false;

  /// Apakah perkenalan sudah ditampilkan pada sesi ini.
  static bool get hasSeenOnboarding => _hasSeenOnboarding;

  static void markOnboardingSeen() {
    _hasSeenOnboarding = true;
  }

  /// Mengembalikan penanda ke keadaan awal; dipakai oleh pengujian.
  static void resetForTesting() {
    _hasSeenOnboarding = false;
  }
}
