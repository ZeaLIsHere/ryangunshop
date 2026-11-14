import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ryangunshop/core/data/app_database.dart';
import 'package:ryangunshop/core/data/in_memory_transaction_repository.dart';
import 'package:ryangunshop/core/data/transaction_repository.dart';
import 'package:ryangunshop/features/dashboard/model/dashboard_period.dart';

void main() {
  test(
    '1/7/30 hari kalender, seluruh nota, batas lokal dan jumlah grafik',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = DriftTransactionRepository(database);
      final today = DateTime(2026, 11, 14);
      Future<void> insert(String id, DateTime at, {int amount = 90}) async {
        await database
            .into(database.transactions)
            .insert(
              TransactionsCompanion.insert(
                id: id,
                createdAt: at.toUtc(),
                totalAmount: amount,
                discountAmount: const Value(10),
                paymentMethod: 'cash',
              ),
            );
        await database
            .into(database.transactionItems)
            .insert(
              TransactionItemsCompanion.insert(
                transactionId: id,
                productId: 'p',
                productName: 'Snapshot',
                quantity: 2,
                unitPrice: 50,
                subtotal: 100,
              ),
            );
      }

      for (var i = 0; i < 60; i++) {
        await insert('today-$i', DateTime(2026, 11, 14, 12));
      }
      await insert('7-start', DateTime(2026, 11, 8));
      await insert('7-before', DateTime(2026, 11, 7, 23, 59, 59));
      await insert('30-start', DateTime(2026, 10, 16));
      await insert('30-before', DateTime(2026, 10, 15, 23, 59, 59));
      await insert('tomorrow', DateTime(2026, 11, 15));
      await insert('future', DateTime(2026, 12, 1));
      for (final entry in {1: 60, 7: 61, 30: 63}.entries) {
        final period = DashboardPeriod(today, entry.key);
        final records = await repository.listForPeriod(
          period.start,
          period.end,
        );
        expect(records, hasLength(entry.value));
        expect(
          records.any((row) => row.id == 'tomorrow' || row.id == 'future'),
          false,
        );
        final points = period.dailyTotals(records);
        expect(points, hasLength(entry.key));
        expect(
          points.fold(0, (sum, point) => sum + point.total),
          entry.value * 90,
        );
        expect(
          records
              .expand((row) => row.items)
              .fold(0, (sum, item) => sum + item.quantity),
          entry.value * 2,
        );
        expect(
          records
              .expand((row) => row.items)
              .fold(0, (sum, item) => sum + item.subtotal),
          entry.value * 100,
        );
        expect(points.last.total, 5400);
        expect(points.first.date, period.start);
      }
      expect((await repository.listForDay(today)), hasLength(60));
      final empty = DashboardPeriod(DateTime(2025), 7).dailyTotals([]);
      expect(empty.every((point) => point.total == 0), true);
    },
  );

  test('repository memori menghormati batas akhir eksklusif', () async {
    final repository = InMemoryTransactionRepository();
    final before = DateTime.now();
    await repository.checkout(
      transactionId: 'n',
      paymentMethod: 'cash',
      totalAmount: 100,
      lines: [
        const CheckoutLine(
          productId: 'p',
          quantity: 1,
          unitPrice: 100,
          subtotal: 100,
        ),
      ],
    );
    final row = (await repository.listRecent()).single;
    expect(await repository.listForPeriod(before, row.createdAt), isEmpty);
    expect(
      await repository.listForPeriod(
        row.createdAt,
        row.createdAt.add(const Duration(seconds: 1)),
      ),
      hasLength(1),
    );
    expect(
      repository.listForPeriod(row.createdAt, row.createdAt),
      throwsArgumentError,
    );
  });
}
