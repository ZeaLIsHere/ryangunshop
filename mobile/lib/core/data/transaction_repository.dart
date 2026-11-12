import 'package:drift/drift.dart';

import 'app_database.dart';
import 'sync/firestore_schema.dart';
import 'sync/outbox.dart';
import 'sync/sync_queue.dart';

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
  factory TransactionRepository(
    AppDatabase database, {
    SyncQueue? queue,
  }) = DriftTransactionRepository;

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
  const DriftTransactionRepository(this.database, {this.queue});

  final AppDatabase database;
  final SyncQueue? queue;

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
    final syncQueue = queue;
    return database.completeCheckout(
      transactionId: transactionId,
      paymentMethod: paymentMethod,
      totalAmount: totalAmount,
      discountAmount: discountAmount,
      lines: lines,
      cashReceived: cashReceived,
      changeAmount: changeAmount,
      afterWrite: syncQueue == null
          ? null
          : () => _enqueueTransaction(syncQueue, transactionId),
    );
  }

  /// Menitipkan nota ke antrean Firestore di dalam transaksi SQLite yang sama.
  Future<void> _enqueueTransaction(
    SyncQueue syncQueue,
    String transactionId,
  ) async {
    final row =
        await (database.select(database.transactions)
              ..where((item) => item.id.equals(transactionId)))
            .getSingle();
    final itemRows =
        await (database.select(database.transactionItems)
              ..where((item) => item.transactionId.equals(transactionId)))
            .get();
    final items = [
      for (final item in itemRows)
        SoldItem(
          productId: item.productId,
          productName: item.productName,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
          subtotal: item.subtotal,
        ),
    ];
    final record = TransactionRecord(
      id: row.id,
      createdAt: row.createdAt,
      totalAmount: row.totalAmount,
      discountAmount: row.discountAmount,
      paymentMethod: row.paymentMethod,
      cashReceived: row.cashReceived,
      changeAmount: row.changeAmount,
      itemCount: items.fold<int>(0, (sum, item) => sum + item.quantity),
      summaryTitle: _summaryTitle(items),
    );
    await syncQueue.enqueue(
      OutboxEntry(
        entity: SyncEntityType.transaction,
        entityId: row.id,
        operation: SyncOperation.upsert,
        payload: FirestoreSchema.transactionDocument(record, items),
        createdAt: row.createdAt,
      ),
    );
  }

  String _summaryTitle(List<SoldItem> items) {
    if (items.isEmpty) return 'Nota tunai';
    return items.length == 1
        ? items.first.productName
        : '${items.first.productName} (+${items.length - 1} item)';
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
