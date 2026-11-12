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
  });

  final String id;
  final DateTime createdAt;
  final int totalAmount;
  final int discountAmount;
  final String paymentMethod;
  final int? cashReceived;
  final int? changeAmount;
}

class DailySalesSummary {
  const DailySalesSummary({required this.total, required this.count});

  final int total;
  final int count;
}

class TransactionRepository {
  const TransactionRepository(this.database);

  final AppDatabase database;

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

  Future<List<TransactionRecord>> listRecent({int limit = 20}) async {
    final query = database.select(database.transactions)
      ..orderBy([(row) => OrderingTerm.desc(row.createdAt)])
      ..limit(limit);
    final rows = await query.get();
    return rows
        .map(
          (row) => TransactionRecord(
            id: row.id,
            createdAt: row.createdAt,
            totalAmount: row.totalAmount,
            discountAmount: row.discountAmount,
            paymentMethod: row.paymentMethod,
            cashReceived: row.cashReceived,
            changeAmount: row.changeAmount,
          ),
        )
        .toList();
  }

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
