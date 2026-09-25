import 'package:flutter/foundation.dart';

import '../model/report_scenario.dart';
import '../model/transaction_record.dart';
import '../sample/reports_sample.dart';

/// Status pemuatan riwayat.
enum ReportsStatus { loading, ready, failure }

/// Keadaan layar riwayat dan laporan transaksi.
class ReportsViewModel extends ChangeNotifier {
  ReportsViewModel({this.loadDelay = const Duration(milliseconds: 350)});

  /// Jeda tiruan agar state memuat terlihat dan dapat dicoba. Saat lapisan data
  /// tersedia, jeda ini diganti pemanggilan sumber data.
  final Duration loadDelay;

  ReportScenario _scenario = ReportScenario.withData;
  ReportsStatus _status = ReportsStatus.loading;
  List<TransactionRecord> _records = const <TransactionRecord>[];
  bool _disposed = false;

  ReportScenario get scenario => _scenario;

  ReportsStatus get status => _status;

  List<TransactionRecord> get records => _records;

  bool get hasRecords => _records.isNotEmpty;

  int get totalAmount =>
      _records.fold(0, (total, record) => total + record.total);

  /// Memuat ulang riwayat, atau mengganti skenario contoh bila dioper.
  Future<void> load({ReportScenario? scenario}) async {
    _scenario = scenario ?? _scenario;
    _status = ReportsStatus.loading;
    _records = const <TransactionRecord>[];
    notifyListeners();

    await Future<void>.delayed(loadDelay);
    if (_disposed) {
      return;
    }

    switch (_scenario) {
      case ReportScenario.withData:
        _records = ReportsSample.records;
        _status = ReportsStatus.ready;
      case ReportScenario.empty:
        _records = const <TransactionRecord>[];
        _status = ReportsStatus.ready;
      case ReportScenario.failure:
        _records = const <TransactionRecord>[];
        _status = ReportsStatus.failure;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
