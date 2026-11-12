import 'package:drift/drift.dart';

import 'app_database.dart';

class TransactionRecord {
  const TransactionRecord({
    required this.id,
    required this.createdAt,
    required this.totalAmount,
    required this.discountAmount,
    required this.paymentMethod,
    this.cashReceived,
    this.changeAmount,
    this.itemCount = 0,
    this.summaryTitle = 'Nota tunai',
  });

  final String id;
  final DateTime createdAt;
  final int totalAmount;
  final int discountAmount;
  final String paymentMethod;
  final int? cashReceived;
  final int? changeAmount;
  final int itemCount;
  final String summaryTitle;
}

class DailySalesSummary {
  const DailySalesSummary({required this.total, required this.count});

  final int total;
  final int count;
}

abstract interface class TransactionRepository {
  factory TransactionRepository(AppDatabase database) =
      DriftTransactionRepository;

  Future<void> checkout({
    required String transactionId,
    required String paymentMethod,
    required int totalAmount,
    required List<CheckoutLine> lines,
    int discountAmount = 0,
    int? cashReceived,
    int? changeAmount,
  });

  Future<List<TransactionRecord>> listRecent({int limit = 20});

  Future<DailySalesSummary> summaryForDay(DateTime day);
}

class DriftTransactionRepository implements TransactionRepository {
  const DriftTransactionRepository(this.database);

  final AppDatabase database;

  @override
  Future<void> checkout({
    required String transactionId,
    required String paymentMethod,
    required int totalAmount,
    required List<CheckoutLine> lines,
    int discountAmount = 0,
    int? cashReceived,
    int? changeAmount,
  }) {
    return database.completeCheckout(
      transactionId: transactionId,
      paymentMethod: paymentMethod,
      totalAmount: totalAmount,
      discountAmount: discountAmount,
      lines: lines,
      cashReceived: cashReceived,
      changeAmount: changeAmount,
    );
  }

  @override
  Future<List<TransactionRecord>> listRecent({int limit = 20}) async {
    final query = database.select(database.transactions)
      ..orderBy([(row) => OrderingTerm.desc(row.createdAt)])
      ..limit(limit);
    final rows = await query.get();
    if (rows.isEmpty) return const [];

    final transactionIds = rows.map((r) => r.id).toList();
    final itemsQuery = database.select(database.transactionItems)
      ..where((row) => row.transactionId.isIn(transactionIds));
    final allItems = await itemsQuery.get();

    final itemsByTrx = <String, List<TransactionItem>>{};
    for (final item in allItems) {
      itemsByTrx.putIfAbsent(item.transactionId, () => []).add(item);
    }

    return rows.map((row) {
      final items = itemsByTrx[row.id] ?? const [];
      final totalQty = items.fold<int>(0, (sum, it) => sum + it.quantity);
      final title = items.isEmpty
          ? 'Nota tunai'
          : (items.length == 1
                ? items.first.productName
                : '${items.first.productName} (+${items.length - 1} item)');

      return TransactionRecord(
        id: row.id,
        createdAt: row.createdAt,
        totalAmount: row.totalAmount,
        discountAmount: row.discountAmount,
        paymentMethod: row.paymentMethod,
        cashReceived: row.cashReceived,
        changeAmount: row.changeAmount,
        itemCount: totalQty,
        summaryTitle: title,
      );
    }).toList();
  }

  @override
  Future<DailySalesSummary> summaryForDay(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final row = await database
        .customSelect(
          'SELECT COUNT(*) AS note_count, COALESCE(SUM(total_amount), 0) AS total '
          'FROM transactions WHERE created_at >= ? AND created_at < ?',
          variables: [
            Variable.withInt(start.millisecondsSinceEpoch ~/ 1000),
            Variable.withInt(end.millisecondsSinceEpoch ~/ 1000),
          ],
        )
        .getSingle();
    return DailySalesSummary(
      total: row.read<int>('total'),
      count: row.read<int>('note_count'),
    );
  }
}
