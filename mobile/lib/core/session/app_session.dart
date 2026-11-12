import 'package:flutter/widgets.dart';

import '../data/app_database.dart';
import '../data/drift_product_repository.dart';
import '../data/transaction_repository.dart';
import '../../features/checkout/model/cart_item.dart';
import '../../features/checkout/view_model/cart_view_model.dart';
import 'completed_transaction.dart';
import 'user_role.dart';

/// Keadaan sesi yang dipakai lintas fitur, misalnya peran pengguna.
///
/// Dipisahkan dari fitur agar denah, pengaturan, dan kasir membaca peran dari satu
/// sumber yang sama.
class AppSession extends ChangeNotifier {
  AppSession({this.database})
    : cart = CartViewModel(withSampleItems: database == null),
      _todayRevenue = database == null ? 1450000 : 0,
      _todayTransactionCount = database == null ? 42 : 0,
      _recentTransactions = database == null
          ? List.of(_sampleTransactions)
          : [];

  final AppDatabase? database;
  final CartViewModel cart;
  DriftProductRepository? get productRepository =>
      database == null ? null : DriftProductRepository(database!);
  TransactionRepository? get transactionRepository =>
      database == null ? null : TransactionRepository(database!);

  UserRole _role = UserRole.owner;

  int _todayRevenue;
  int _todayTransactionCount;

  static const _sampleTransactions = <CompletedTransaction>[
    CompletedTransaction(
      id: 'TRX-9481',
      timeLabel: '13:42 WIB',
      title: 'Minyak Goreng Bimoli 2L',
      amount: 36500,
      itemCount: 1,
      paymentMethod: 'Tunai',
    ),
    CompletedTransaction(
      id: 'TRX-9480',
      timeLabel: '13:30 WIB',
      title: 'Indomie Goreng Spesial (5 Pcs)',
      amount: 15500,
      itemCount: 5,
      paymentMethod: 'QRIS',
    ),
    CompletedTransaction(
      id: 'TRX-9479',
      timeLabel: '13:18 WIB',
      title: 'Teh Pucuk Harum Dingin 350ml (2)',
      amount: 8000,
      itemCount: 2,
      paymentMethod: 'Tunai',
    ),
  ];
  final List<CompletedTransaction> _recentTransactions;
  bool _disposed = false;
  int _localLoadVersion = 0;

  Future<void> loadLocalSummary() async {
    if (_disposed) return;
    final source = transactionRepository;
    if (source == null) return;
    final version = ++_localLoadVersion;
    try {
      final today = await source.summaryForDay(DateTime.now());
      final recent = await source.listRecent(limit: 20);
      if (_disposed || version != _localLoadVersion) return;
      _todayRevenue = today.total;
      _todayTransactionCount = today.count;
      _recentTransactions
        ..clear()
        ..addAll(
          recent.map(
            (row) => CompletedTransaction(
              id: row.id,
              timeLabel:
                  '${row.createdAt.hour.toString().padLeft(2, '0')}:${row.createdAt.minute.toString().padLeft(2, '0')} WIB',
              title: 'Nota tunai',
              amount: row.totalAmount,
              itemCount: 0,
              paymentMethod: 'Tunai',
            ),
          ),
        );
      notifyListeners();
    } catch (_) {
      // Data contoh tidak boleh ditampilkan sebagai pengganti data lokal.
    }
  }

  UserRole get role => _role;
  int get todayRevenue => _todayRevenue;
  int get todayTransactionCount => _todayTransactionCount;
  int get todayAverageRevenue => _todayTransactionCount > 0
      ? (_todayRevenue / _todayTransactionCount).round()
      : 0;
  List<CompletedTransaction> get recentTransactions =>
      List.unmodifiable(_recentTransactions);

  void recordTransaction({
    required int totalAmount,
    required List<CartItem> items,
    required String paymentMethod,
    int? cashReceived,
    int? changeAmount,
  }) {
    _todayRevenue += totalAmount;
    _todayTransactionCount += 1;
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} WIB';
    final trxId = 'TRX-${9482 + _recentTransactions.length - 3}';
    final title = items.isNotEmpty
        ? (items.length == 1
              ? items.first.productName
              : '${items.first.productName} (+${items.length - 1} item)')
        : 'Pesanan Kasir';

    _recentTransactions.insert(
      0,
      CompletedTransaction(
        id: trxId,
        timeLabel: timeStr,
        title: title,
        amount: totalAmount,
        itemCount: items.fold(0, (sum, it) => sum + it.quantity),
        paymentMethod: paymentMethod,
      ),
    );
    notifyListeners();
  }

  /// Pintasan bagi fitur yang perlu tahu apakah mode edit denah boleh dibuka.
  bool get canEditFloorPlan => _role.canEditFloorPlan;

  void selectRole(UserRole role) {
    if (role == _role) {
      return;
    }
    _role = role;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    cart.dispose();
    super.dispose();
  }
}

/// Menyediakan [AppSession] untuk seluruh pohon widget.
///
/// Dipasang sekali di akar aplikasi, lalu dibaca dengan
/// `AppSessionScope.of(context)`.
class AppSessionScope extends InheritedNotifier<AppSession> {
  const AppSessionScope({
    required AppSession session,
    required super.child,
    super.key,
  }) : super(notifier: session);

  static AppSession? maybeOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppSessionScope>();
    return scope?.notifier;
  }

  static AppSession of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppSessionScope>();
    assert(scope != null, 'AppSessionScope belum dipasang di atas widget ini.');
    return scope!.notifier!;
  }
}
