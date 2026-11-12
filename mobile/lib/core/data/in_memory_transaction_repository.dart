import 'app_database.dart' show CheckoutLine;
import 'in_memory_product_repository.dart';
import 'transaction_repository.dart';

class InMemoryTransactionRepository implements TransactionRepository {
  InMemoryTransactionRepository({this.productRepository});

  final InMemoryProductRepository? productRepository;
  final List<TransactionRecord> _transactions = [];

  @override
  Future<void> checkout({
    required String transactionId,
    required String paymentMethod,
    required int totalAmount,
    required List<CheckoutLine> lines,
    int discountAmount = 0,
    int? cashReceived,
    int? changeAmount,
  }) async {
    final products = await productRepository?.listProducts() ?? const [];
    for (final line in lines) {
      final matches = products.where((p) => p.id == line.productId);
      if (matches.isNotEmpty) {
        final current = matches.first;
        final newStock = (current.stock - line.quantity).clamp(0, 999999);
        await productRepository?.save(current.copyWith(stock: newStock));
      }
    }

    final totalQty = lines.fold<int>(0, (sum, it) => sum + it.quantity);
    final title = lines.isEmpty
        ? 'Nota tunai'
        : (lines.length == 1
              ? (products
                        .where((p) => p.id == lines.first.productId)
                        .firstOrNull
                        ?.name ??
                    'Barang')
              : '${lines.length} barang');

    _transactions.insert(
      0,
      TransactionRecord(
        id: transactionId,
        createdAt: DateTime.now(),
        totalAmount: totalAmount,
        discountAmount: discountAmount,
        paymentMethod: paymentMethod,
        cashReceived: cashReceived,
        changeAmount: changeAmount,
        itemCount: totalQty,
        summaryTitle: title,
      ),
    );
  }

  @override
  Future<List<TransactionRecord>> listRecent({int limit = 20}) async {
    return _transactions.take(limit).toList();
  }

  @override
  Future<DailySalesSummary> summaryForDay(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final matching = _transactions.where(
      (tx) => tx.createdAt.isAfter(start) && tx.createdAt.isBefore(end),
    );
    final total = matching.fold<int>(0, (sum, tx) => sum + tx.totalAmount);
    return DailySalesSummary(total: total, count: matching.length);
  }
}
