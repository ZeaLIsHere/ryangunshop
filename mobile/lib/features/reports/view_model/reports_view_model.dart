import 'package:flutter/foundation.dart';

import '../../../core/data/transaction_repository.dart' as db;
import '../model/report_payment_method.dart';
import '../model/report_scenario.dart';
import '../model/transaction_record.dart';
import '../sample/reports_sample.dart';

/// Status pemuatan riwayat.
enum ReportsStatus { loading, ready, failure }

DateTime _localDay(DateTime day) {
  final local = day.toLocal();
  return DateTime(local.year, local.month, local.day);
}

String reportPaymentLabel(String method) => switch (method) {
  'cash' => 'Tunai',
  'qris' => 'QRIS',
  '' => 'Tidak tercatat',
  _ => method,
};

/// Keadaan layar riwayat dan laporan transaksi.
class ReportsViewModel extends ChangeNotifier {
  ReportsViewModel({
    this.repository,
    this.initialRecords,
    this.loadDelay = const Duration(milliseconds: 350),
    DateTime? day,
  }) : selectedDay = _localDay(day ?? DateTime.now()),
       _scenario = initialRecords != null
           ? ReportScenario.withData
           : ReportScenario.empty;

  db.TransactionRepository? repository;
  final List<TransactionRecord>? initialRecords;

  /// Jeda tiruan agar state memuat terlihat dan dapat dicoba saat data contoh.
  final Duration loadDelay;

  bool get isLocal => repository != null;

  DateTime selectedDay;
  List<db.TransactionRecord> dailyRecords = const [];

  int get discountAmount =>
      dailyRecords.fold(0, (sum, r) => sum + r.discountAmount);
  int get grossAmount => totalAmount + discountAmount;
  double get averageAmount =>
      records.isEmpty ? 0 : totalAmount / records.length;

  Map<String, ({int count, int total})> get paymentBreakdown {
    final result = <String, ({int count, int total})>{};
    for (final record in dailyRecords) {
      final old = result[record.paymentMethod] ?? (count: 0, total: 0);
      result[record.paymentMethod] = (
        count: old.count + 1,
        total: old.total + record.totalAmount,
      );
    }
    return result;
  }

  List<({String id, String name, int quantity, int gross})> get soldProducts {
    final grouped =
        <String, ({String id, String name, int quantity, int gross})>{};
    for (final record in dailyRecords) {
      for (final item in record.items) {
        final old = grouped[item.productId];
        grouped[item.productId] = (
          id: item.productId,
          name: old?.name ?? item.productName,
          quantity: (old?.quantity ?? 0) + item.quantity,
          gross: (old?.gross ?? 0) + item.subtotal,
        );
      }
    }
    return grouped.values.toList()..sort((a, b) {
      final quantity = b.quantity.compareTo(a.quantity);
      return quantity != 0 ? quantity : a.id.compareTo(b.id);
    });
  }

  Future<void> selectDay(DateTime day) {
    selectedDay = _localDay(day);
    return load();
  }

  ReportScenario _scenario;
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
    if (_disposed) return;
    final version = ++_loadVersion;
    dailyRecords = const [];
    final explicitScenario = scenario;
    _scenario = scenario ?? _scenario;
    _status = ReportsStatus.loading;
    _records = const <TransactionRecord>[];
    notifyListeners();

    final source = repository;
    if (source != null && explicitScenario == null) {
      try {
        final localRecords = await source.listForDay(selectedDay);
        if (_disposed || version != _loadVersion) return;
        dailyRecords = List.unmodifiable(localRecords);
        _records = localRecords.map((r) {
          final timeStr =
              '${r.createdAt.toLocal().hour.toString().padLeft(2, '0')}:${r.createdAt.toLocal().minute.toString().padLeft(2, '0')}';
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
    if (_disposed || version != _loadVersion) {
      return;
    }

    if (explicitScenario != null) {
      switch (explicitScenario) {
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
    } else if (initialRecords != null) {
      _scenario = ReportScenario.withData;
      _records = initialRecords!;
      _status = ReportsStatus.ready;
    } else {
      _scenario = ReportScenario.empty;
      _records = const <TransactionRecord>[];
      _status = ReportsStatus.ready;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
