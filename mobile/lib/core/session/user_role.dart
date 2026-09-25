/// Peran pengguna aplikasi.
///
/// Tahap ini belum memakai autentikasi, jadi peran dipilih dari halaman pengaturan.
/// Setelah autentikasi tersedia, peran diambil dari klaim dan tidak lagi dapat dipilih
/// bebas oleh pengguna.
enum UserRole {
  owner(
    label: 'Pemilik',
    description: 'Dapat mengubah tata letak warung dan pengaturan.',
  ),
  cashier(
    label: 'Kasir',
    description: 'Dapat menjual barang tanpa akses mode edit denah.',
  );

  const UserRole({required this.label, required this.description});

  final String label;
  final String description;

  /// Hanya pemilik yang boleh membuka mode edit denah.
  bool get canEditFloorPlan => this == UserRole.owner;
}
