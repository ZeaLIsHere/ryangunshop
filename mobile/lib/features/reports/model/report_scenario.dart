/// Skenario contoh pada layar riwayat.
///
/// Dipakai agar state kosong dan state gagal dapat dicoba tanpa layanan nyata.
enum ReportScenario {
  withData(label: 'Ada data'),
  empty(label: 'Kosong'),
  failure(label: 'Gagal');

  const ReportScenario({required this.label});

  final String label;
}
