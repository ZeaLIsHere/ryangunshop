import '../model/report_payment_method.dart';
import '../model/transaction_record.dart';

/// Riwayat transaksi contoh beserta teks layarnya.
abstract final class ReportsSample {
  static const String summaryTitle = 'Total transaksi contoh';
  static const String scenarioTitle = 'Skenario contoh';
  static const String scenarioNote =
      'Pilih skenario untuk mencoba state kosong dan gagal.';

  static const String loadingLabel = 'Memuat riwayat contoh';
  static const String emptyTitle = 'Belum ada transaksi';
  static const String emptyDescription =
      'Transaksi yang selesai akan muncul di sini.';
  static const String errorTitle = 'Riwayat contoh gagal dimuat';
  static const String errorDescription =
      'Ini skenario contoh, bukan kegagalan layanan nyata.';

  static const List<TransactionRecord> records = <TransactionRecord>[
    TransactionRecord(
      id: 'TRX-0001',
      timeLabel: '09.14',
      itemCount: 3,
      total: 27500,
      paymentMethod: ReportPaymentMethod.cash,
    ),
    TransactionRecord(
      id: 'TRX-0002',
      timeLabel: '10.02',
      itemCount: 1,
      total: 6000,
      paymentMethod: ReportPaymentMethod.qris,
    ),
    TransactionRecord(
      id: 'TRX-0003',
      timeLabel: '11.48',
      itemCount: 5,
      total: 123000,
      paymentMethod: ReportPaymentMethod.qris,
    ),
    TransactionRecord(
      id: 'TRX-0004',
      timeLabel: '13.20',
      itemCount: 2,
      total: 18500,
      paymentMethod: ReportPaymentMethod.cash,
    ),
  ];
}
