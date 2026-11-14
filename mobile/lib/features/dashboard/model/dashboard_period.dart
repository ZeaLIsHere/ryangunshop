import '../../../core/data/transaction_repository.dart';

/// Hari kalender lokal; akhir eksklusif menghindari asumsi hari selalu 24 jam.
class DashboardPeriod {
  DashboardPeriod(DateTime now, this.days) {
    final local = now.toLocal();
    end = DateTime(local.year, local.month, local.day + 1);
    start = DateTime(local.year, local.month, local.day - days + 1);
  }

  final int days;
  late final DateTime start;
  late final DateTime end;

  List<({DateTime date, int total})> dailyTotals(
    List<TransactionRecord> records,
  ) {
    final totals = <DateTime, int>{};
    for (final record in records) {
      final local = record.createdAt.toLocal();
      final date = DateTime(local.year, local.month, local.day);
      totals.update(
        date,
        (value) => value + record.totalAmount,
        ifAbsent: () => record.totalAmount,
      );
    }
    return [
      for (var i = 0; i < days; i++)
        (
          date: DateTime(start.year, start.month, start.day + i),
          total: totals[DateTime(start.year, start.month, start.day + i)] ?? 0,
        ),
    ];
  }
}
