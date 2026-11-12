import 'package:flutter/foundation.dart';

import '../../../core/data/transaction_repository.dart' as db;
import '../model/report_payment_method.dart';
import '../model/report_scenario.dart';
import '../model/transaction_record.dart';
import '../sample/reports_sample.dart';

/// Status pemuatan riwayat.
enum ReportsStatus { loading, ready, failure }

/// Keadaan layar riwayat dan laporan transaksi.
class ReportsViewModel extends ChangeNotifier {
  ReportsViewModel({
    this.repository,
    this.initialRecords,
    this.loadDelay = const Duration(milliseconds: 350),
  });

  db.TransactionRepository? repository;
  final List<TransactionRecord>? initialRecords;

  /// Jeda tiruan agar state memuat terlihat dan dapat dicoba saat data contoh.
  final Duration loadDelay;

  bool get isLocal => repository != null;

  ReportScenario _scenario = ReportScenario.withData;
  ReportsStatus _status = ReportsStatus.loading;
  List<TransactionRecord> _records = const <TransactionRecord>[];
  bool _disposed = false;
  int _loadVersion = 0;

  ReportScenario get scenario => _scenario;

  ReportsStatus get status => _status;

  List<TransactionRecord> get records => _records;

  bool get hasRecords => _records.isNotEmpty;

  int get totalAmount =>
      _records.fold(0, (total, record) => total + record.total);

  void updateRepository(db.TransactionRepository? newRepository) {
    if (repository == newRepository) return;
    repository = newRepository;
    load();
  }

  /// Memuat ulang riwayat, atau mengganti skenario contoh bila dioper.
  Future<void> load({ReportScenario? scenario}) async {
    _scenario = scenario ?? _scenario;
    _status = ReportsStatus.loading;
    _records = const <TransactionRecord>[];
    notifyListeners();

    final source = repository;
    if (source != null && scenario == null) {
      final version = ++_loadVersion;
      try {
        final localRecords = await source.listRecent(limit: 50);
        if (_disposed || version != _loadVersion) return;
        _records = localRecords.map((r) {
          final timeStr =
              '${r.createdAt.hour.toString().padLeft(2, '0')}:${r.createdAt.minute.toString().padLeft(2, '0')} WIB';
          final method = r.paymentMethod == 'cash'
              ? ReportPaymentMethod.cash
              : ReportPaymentMethod.qris;
          return TransactionRecord(
            id: r.id,
            timeLabel: timeStr,
            itemCount: r.itemCount,
            total: r.totalAmount,
            paymentMethod: method,
            title: r.summaryTitle,
          );
        }).toList();
        _status = ReportsStatus.ready;
      } catch (_) {
        if (_disposed || version != _loadVersion) return;
        _status = ReportsStatus.failure;
      }
      notifyListeners();
      return;
    }

    await Future<void>.delayed(loadDelay);
    if (_disposed) {
      return;
    }

    switch (_scenario) {
      case ReportScenario.withData:
        _records = initialRecords ?? ReportsSample.records;
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
