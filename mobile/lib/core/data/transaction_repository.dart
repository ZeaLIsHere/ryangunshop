import 'package:drift/drift.dart';

import 'app_database.dart';

class TransactionRecord {
  const TransactionRecord({
    required this.id,
    required this.createdAt,
    required this.totalAmount,
    required this.paymentMethod,
    this.cashReceived,
    this.changeAmount,
  });

  final String id;
  final DateTime createdAt;
  final int totalAmount;
  final String paymentMethod;
  final int? cashReceived;
  final int? changeAmount;
}

class TransactionRepository {
  const TransactionRepository(this.database);

  final AppDatabase database;

  Future<void> checkout({
    required String transactionId,
    required String paymentMethod,
    required int totalAmount,
    required List<CheckoutLine> lines,
    int? cashReceived,
    int? changeAmount,
  }) {
    return database.completeCheckout(
      transactionId: transactionId,
      paymentMethod: paymentMethod,
      totalAmount: totalAmount,
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
            paymentMethod: row.paymentMethod,
            cashReceived: row.cashReceived,
            changeAmount: row.changeAmount,
          ),
        )
        .toList();
  }
}
