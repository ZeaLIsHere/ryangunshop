import '../model/payment_preview.dart';

abstract final class PaymentSample {
  static const cash = PaymentPreview(
    total: 23000,
    method: PaymentMethod.cash,
    cashReceived: 25000,
  );

  /// Termasuk status paid untuk pratinjau, tanpa menyelesaikan transaksi.
  static final qrisScenarios = List<PaymentPreview>.unmodifiable([
    for (final status in QrisStatus.values)
      PaymentPreview(
        total: 23000,
        method: PaymentMethod.qris,
        qrisStatus: status,
      ),
  ]);
}
