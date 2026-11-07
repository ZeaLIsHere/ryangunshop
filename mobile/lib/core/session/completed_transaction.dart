/// Model untuk satu transaksi yang telah diselesaikan pada sesi kasir.
class CompletedTransaction {
  const CompletedTransaction({
    required this.id,
    required this.timeLabel,
    required this.title,
    required this.amount,
    required this.itemCount,
    required this.paymentMethod,
    this.imageUrl,
  });

  final String id;
  final String timeLabel;
  final String title;
  final int amount;
  final int itemCount;
  final String paymentMethod;
  final String? imageUrl;
}
