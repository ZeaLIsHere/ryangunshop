/// Metode pembayaran pada riwayat contoh.
///
/// Digantikan model bersama milik fitur pembayaran setelah fitur itu tersedia.
enum ReportPaymentMethod {
  cash(label: 'Tunai'),
  qris(label: 'QRIS');

  const ReportPaymentMethod({required this.label});

  final String label;
}
