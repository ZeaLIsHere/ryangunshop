/// Profil warung yang ditampilkan pada halaman pengaturan.
class StoreProfile {
  const StoreProfile({
    required this.name,
    required this.address,
    required this.cashierCount,
  });

  final String name;
  final String address;
  final int cashierCount;
}
