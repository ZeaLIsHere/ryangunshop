import 'report_payment_method.dart';

/// Satu transaksi pada riwayat dan laporan.
class TransactionRecord {
  const TransactionRecord({
    required this.id,
    required this.timeLabel,
    required this.itemCount,
    required this.total,
    required this.paymentMethod,
  });

  final String id;

  /// Label waktu untuk ditampilkan; diganti waktu transaksi sebenarnya saat
  /// lapisan data tersedia.
  final String timeLabel;

  final int itemCount;

  /// Total dalam rupiah bulat.
  final int total;

  final ReportPaymentMethod paymentMethod;
}
