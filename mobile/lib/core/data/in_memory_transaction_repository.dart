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
    bool clearCartDraft = true,
  }) async {
    final products = productRepository?.snapshot ?? const [];
    if (_transactions.any((row) => row.id == transactionId)) return;
    final subtotal = lines.fold<int>(0, (sum, line) => sum + line.subtotal);
    if (transactionId.trim().isEmpty ||
        lines.isEmpty ||
        paymentMethod != 'cash' ||
        totalAmount <= 0 ||
        discountAmount < 0 ||
        totalAmount != subtotal - discountAmount ||
        (!clearCartDraft && cashReceived == null) ||
        (cashReceived != null &&
            (cashReceived < totalAmount ||
                changeAmount != cashReceived - totalAmount)) ||
        lines.map((line) => line.productId).toSet().length != lines.length) {
      throw ArgumentError('Rincian transaksi tunai tidak valid');
    }
    for (final line in lines) {
      final product = products.where((p) => p.id == line.productId).firstOrNull;
      // ponytail: simulasi Kasir lama boleh tanpa katalog; pencatatan chat wajib katalog.
      if (product == null && clearCartDraft) continue;
      if (product == null ||
          line.quantity <= 0 ||
          line.unitPrice <= 0 ||
          line.subtotal != line.quantity * line.unitPrice ||
          product.salePrice != line.unitPrice ||
          product.stock < line.quantity) {
        throw StateError('Harga atau stok produk berubah');
      }
    }
    productRepository?.deductStock({
      for (final line in lines)
        if (products.any((product) => product.id == line.productId))
          line.productId: line.quantity,
    });

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
        items: List.unmodifiable([
          for (final line in lines)
            TransactionItemSnapshot(
              productId: line.productId,
              productName:
                  products
                      .where((p) => p.id == line.productId)
                      .firstOrNull
                      ?.name ??
                  'Barang',
              quantity: line.quantity,
              unitPrice: line.unitPrice,
              subtotal: line.subtotal,
            ),
        ]),
      ),
    );
  }

  @override
  Future<TransactionRecord?> findById(String id) async =>
      _transactions.where((row) => row.id == id).firstOrNull;

  @override
  Future<List<TransactionRecord>> listRecent({int limit = 20}) async {
    return _transactions.take(limit).toList();
  }

  @override
  Future<List<TransactionRecord>> listForDay(DateTime day) async {
    final local = day.toLocal();
    final start = DateTime(local.year, local.month, local.day);
    final end = DateTime(local.year, local.month, local.day + 1);
    return _transactions
        .where(
          (tx) => !tx.createdAt.isBefore(start) && tx.createdAt.isBefore(end),
        )
        .toList();
  }

  @override
  Future<DailySalesSummary> summaryForDay(DateTime day) async {
    final matching = await listForDay(day);
    final total = matching.fold<int>(0, (sum, tx) => sum + tx.totalAmount);
    return DailySalesSummary(total: total, count: matching.length);
  }
}
