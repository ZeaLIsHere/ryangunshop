enum PaymentMethod { cash, qris }

/// Status ini hanya untuk simulasi tampilan, bukan konfirmasi pembayaran.
enum QrisStatus { creating, awaitingPayment, paid, expired, failed }

class PaymentPreview {
  const PaymentPreview({
    required this.total,
    required this.method,
    this.cashReceived,
    this.qrisStatus,
  }) : assert(total >= 0),
       assert(cashReceived == null || cashReceived >= 0),
       assert(method != PaymentMethod.qris || qrisStatus != null),
       assert(method != PaymentMethod.cash || qrisStatus == null),
       assert(method != PaymentMethod.qris || cashReceived == null);

  final int total;
  final PaymentMethod method;
  final int? cashReceived;
  final QrisStatus? qrisStatus;

  /// Null berarti uang belum diisi atau belum mencukupi, bukan kembalian nol.
  int? get change {
    final received = cashReceived;
    if (method != PaymentMethod.cash || received == null || received < total) {
      return null;
    }
    return received - total;
  }
}
