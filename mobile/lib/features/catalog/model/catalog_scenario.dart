/// Skenario lokal yang dapat dicoba tanpa koneksi atau layanan eksternal.
enum CatalogScenario {
  withData('Daftar contoh'),
  loading('Memuat'),
  empty('Kosong'),
  failure('Gagal'),
  offline('Offline');

  const CatalogScenario(this.label);

  final String label;
}
