import 'package:flutter/foundation.dart';

import '../model/payment_preview.dart';

/// State UI pembayaran contoh; tidak membuat atau memverifikasi transaksi.
class PaymentViewModel extends ChangeNotifier {
  PaymentViewModel({required this.totalAmount}) : assert(totalAmount >= 0);

  final int totalAmount;
  PaymentMethod _method = PaymentMethod.cash;
  int? _cashReceived;
  QrisStatus _qrisStatus = QrisStatus.creating;

  PaymentMethod get method => _method;
  int? get cashReceived => _cashReceived;
  QrisStatus get qrisStatus => _qrisStatus;
  bool get canCompleteCash =>
      totalAmount > 0 && _cashReceived != null && _cashReceived! >= totalAmount;
  int? get change => canCompleteCash ? _cashReceived! - totalAmount : null;

  void selectMethod(PaymentMethod method) {
    if (_method == method) return;
    _method = method;
    notifyListeners();
  }

  void setCashInput(String input) {
    _cashReceived = int.tryParse(input.trim());
    notifyListeners();
  }

  void chooseCashAmount(int amount) {
    _cashReceived = amount;
    notifyListeners();
  }

  void selectQrisStatus(QrisStatus status) {
    _qrisStatus = status;
    notifyListeners();
  }
}
