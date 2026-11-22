import 'dart:async';

import 'package:flutter/widgets.dart';

import '../data/app_database.dart';
import '../data/cart_draft_repository.dart';
import '../data/drift_product_repository.dart';
import '../data/in_memory_product_repository.dart';
import '../data/in_memory_transaction_repository.dart';
import '../data/product_repository.dart';
import '../data/product_record.dart';
import '../data/sync/sync_queue.dart';
import '../data/sync/cloud_read_through.dart';
import '../data/transaction_repository.dart';
import '../../features/checkout/model/cart_item.dart';
import '../../features/checkout/view_model/cart_view_model.dart';
import '../../features/auth/model/user_account.dart';
import '../../features/auth/model/store_info.dart';
import '../data/auth_repository.dart';
import '../data/drift_auth_repository.dart';
import '../data/in_memory_auth_repository.dart';
import 'completed_transaction.dart';
import 'user_role.dart';

/// Keadaan sesi yang dipakai lintas fitur, misalnya peran pengguna.
///
/// Dipisahkan dari fitur agar denah, pengaturan, dan kasir membaca peran dari satu
/// sumber yang sama.
class AppSession extends ChangeNotifier {
  AppSession({
    this.database,
    this.syncQueue,
    this.cloudReadThrough,
    AuthRepository? authRepository,
  })  : _inMemoryProducts = InMemoryProductRepository([]),
        cart = CartViewModel(withSampleItems: false),
        _todayRevenue = 0,
        _todayTransactionCount = 0,
        _lowStockCount = 0,
        _recentTransactions = [] {
    _authRepository = authRepository ??
        (database != null
            ? DriftAuthRepository(database!)
            : InMemoryAuthRepository());
    _inMemoryTransactions = InMemoryTransactionRepository(
      productRepository: _inMemoryProducts,
    );
    unawaited(restoreAuthSession());
    if (database != null) {
      cart.addListener(_onCartChanged);
      unawaited(loadLocalCart());
      _dataSubscription = database!
          .customSelect(
            'SELECT 1',
            readsFrom: {
              database!.products,
              database!.transactions,
              database!.transactionItems,
            },
          )
          .watch()
          .listen((_) {
            if (_disposed) return;
            dataRevision++;
            _summaryDirty = true;
            unawaited(loadLocalSummary(refreshCloud: false));
          }, onError: (Object _) {});
    }
  }

  final AppDatabase? database;
  late final AuthRepository _authRepository;

  AuthRepository get authRepository => _authRepository;

  UserAccount? _currentUser;
  StoreInfo? _currentStore;
  bool _authReady = false;

  UserAccount? get currentUser => _currentUser;
  StoreInfo? get currentStore => _currentStore;
  bool get isAuthenticated => _currentUser != null;
  bool get isAuthReady => _authReady;
  bool get isOwner => _currentUser?.isOwner ?? (_role == UserRole.owner);
  bool get isCashier => _currentUser?.isCashier ?? (_role == UserRole.cashier);
  bool get isCashierLinkedToStore =>
      isCashier && (_currentUser?.hasActiveStore ?? false);

  /// Antrean Firestore. Kosong berarti aplikasi berjalan lokal saja.
  final SyncQueue? syncQueue;
  final CloudReadThrough? cloudReadThrough;
  final InMemoryProductRepository _inMemoryProducts;
  late final InMemoryTransactionRepository _inMemoryTransactions;
  final CartViewModel cart;

  ProductRepository get productRepository => database != null
      ? DriftProductRepository(
          database!,
          queue: syncQueue,
          beforeRead: cloudReadThrough?.refresh,
        )
      : _inMemoryProducts;

  TransactionRepository get transactionRepository => database != null
      ? DriftTransactionRepository(
          database!,
          queue: syncQueue,
          beforeRead: cloudReadThrough?.refresh,
        )
      : _inMemoryTransactions;

  UserRole _role = UserRole.owner;

  int _todayRevenue;
  int _todayTransactionCount;
  int _lowStockCount;
  final List<CompletedTransaction> _recentTransactions;
  bool _disposed = false;
  int dataRevision = 0;
  StreamSubscription<Object?>? _dataSubscription;
  int _localLoadVersion = 0;
  bool _cartReady = false;
  bool _cartLoadFailed = false;
  bool _cartSaveFailed = false;
  bool _restoringCart = false;
  int _cartRevision = 0;
  Future<void>? _cartLoadFuture;
  Future<void> _cartWriteQueue = Future<void>.value();
  Future<void>? _summaryFuture;
  bool _summaryDirty = false;

  bool get isLocalCartReady => database == null || _cartReady;
  bool get isLocalCartLoadFailed => _cartLoadFailed;
  bool get isLocalCartSaveFailed => _cartSaveFailed;

  Future<void> loadLocalCart() {
    if (database == null || _disposed || _cartReady) {
      return Future<void>.value();
    }
    return _cartLoadFuture ??= _readLocalCart().whenComplete(() {
      _cartLoadFuture = null;
    });
  }

  Future<void> _readLocalCart() async {
    final revision = _cartRevision;
    try {
      final draft = await CartDraftRepository(database!).load();
      if (_disposed) return;
      if (_cartRevision == revision) {
        _restoringCart = true;
        try {
          cart.restoreDraft(
            [
              for (final item in draft.items)
                CartItem(
                  productId: item.productId,
                  productName: item.productName,
                  unitPrice: item.unitPrice,
                  quantity: item.quantity,
                  unit: item.unit,
                ),
            ],
            discount: draft.discount,
            note: draft.note,
          );
        } finally {
          _restoringCart = false;
        }
      }
      _cartReady = true;
      _cartLoadFailed = false;
      notifyListeners();
      if (_cartRevision != revision) _queueCartSave();
    } catch (_) {
      if (_disposed) return;
      _cartLoadFailed = true;
      notifyListeners();
    }
  }

  void _onCartChanged() {
    if (_restoringCart || _disposed) return;
    _cartRevision++;
    if (_cartReady) _queueCartSave();
  }

  void _queueCartSave() {
    final draft = CartDraftSnapshot(
      items: [
        for (final item in cart.items)
          CartDraftLine(
            productId: item.productId,
            productName: item.productName,
            unitPrice: item.unitPrice,
            quantity: item.quantity,
            unit: item.unit,
          ),
      ],
      discount: cart.discount,
      note: cart.note,
    );
    final source = CartDraftRepository(database!);
    _cartWriteQueue = _cartWriteQueue
        .catchError((Object _) {})
        .then((_) => source.save(draft));
    unawaited(
      _cartWriteQueue.then(
        (_) {
          if (_disposed || !_cartSaveFailed) return;
          _cartSaveFailed = false;
          notifyListeners();
        },
        onError: (Object _, StackTrace _) {
          if (_disposed) return;
          _cartSaveFailed = true;
          notifyListeners();
        },
      ),
    );
  }

  Future<void> flushCartDraft() async {
    await loadLocalCart();
    if (database == null) return;
    if (!_cartReady) throw StateError('Draft keranjang gagal dimuat');
    await _cartWriteQueue;
  }

  Future<void> finishLocalWrites() async {
    final loading = _cartLoadFuture;
    if (loading != null) await loading;
    await _cartWriteQueue;
  }

  Future<void> refreshCloud({bool force = false}) async {
    await cloudReadThrough?.refresh(force: force);
  }

  Future<void> loadLocalSummary({bool refreshCloud = true}) {
    return _summaryFuture ??= _reloadSummary(refreshCloud: refreshCloud)
        .whenComplete(() => _summaryFuture = null);
  }

  Future<void> _reloadSummary({required bool refreshCloud}) async {
    do {
      _summaryDirty = false;
      await _loadSummary(refreshCloud: refreshCloud);
      refreshCloud = false;
    } while (_summaryDirty && !_disposed);
  }

  Future<void> _loadSummary({required bool refreshCloud}) async {
    if (_disposed) return;
    final source = !refreshCloud && database != null
        ? DriftTransactionRepository(database!)
        : transactionRepository;
    final products = !refreshCloud && database != null
        ? DriftProductRepository(database!)
        : productRepository;
    final version = ++_localLoadVersion;
    try {
      final results = await Future.wait<Object>([
        source.summaryForDay(DateTime.now()),
        source.listRecent(limit: 20),
        products.listProducts(),
      ]);
      final today = results[0] as DailySalesSummary;
      final recent = results[1] as List<TransactionRecord>;
      final allProducts = results[2] as List<ProductRecord>;
      if (_disposed || version != _localLoadVersion) return;
      _todayRevenue = today.total;
      _todayTransactionCount = today.count;
      _lowStockCount = allProducts
          .where((p) => p.stock > 0 && p.stock <= p.lowStockThreshold)
          .length;
      _recentTransactions
        ..clear()
        ..addAll(
          recent.map(
            (row) => CompletedTransaction(
              id: row.id,
              timeLabel:
                  '${row.createdAt.hour.toString().padLeft(2, '0')}:${row.createdAt.minute.toString().padLeft(2, '0')} WIB',
              title: row.summaryTitle,
              amount: row.totalAmount,
              itemCount: row.itemCount,
              paymentMethod: row.paymentMethod == 'qris' ? 'QRIS' : 'Tunai',
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
  int get lowStockCount => _lowStockCount;
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

  Future<void> restoreAuthSession() async {
    try {
      final user = await _authRepository.getCurrentUser();
      _currentUser = user;
      if (user != null) {
        _role = user.role;
        if (user.activeStoreId != null) {
          _currentStore = await _authRepository.getStore(user.activeStoreId!);
        } else {
          _currentStore = null;
        }
      } else {
        _currentStore = null;
      }
    } catch (_) {
      _currentUser = null;
      _currentStore = null;
    } finally {
      _authReady = true;
      notifyListeners();
    }
  }

  Future<UserAccount> login(String email, String password) async {
    final user = await _authRepository.login(email: email, password: password);
    _currentUser = user;
    _role = user.role;
    if (user.activeStoreId != null) {
      _currentStore = await _authRepository.getStore(user.activeStoreId!);
    } else {
      _currentStore = null;
    }
    notifyListeners();
    return user;
  }

  Future<UserAccount> registerOwner({
    required String name,
    required String email,
    required String password,
    required String storeName,
    String? storeAddress,
  }) async {
    final user = await _authRepository.registerOwner(
      name: name,
      email: email,
      password: password,
      storeName: storeName,
      storeAddress: storeAddress,
    );
    _currentUser = user;
    _role = user.role;
    if (user.activeStoreId != null) {
      _currentStore = await _authRepository.getStore(user.activeStoreId!);
    }
    notifyListeners();
    return user;
  }

  Future<UserAccount> registerCashier({
    required String name,
    required String email,
    required String password,
  }) async {
    final user = await _authRepository.registerCashier(
      name: name,
      email: email,
      password: password,
    );
    _currentUser = user;
    _role = user.role;
    _currentStore = null;
    notifyListeners();
    return user;
  }

  Future<void> logout() async {
    await _authRepository.logout();
    _currentUser = null;
    _currentStore = null;
    notifyListeners();
  }

  Future<void> refreshCurrentUser() async {
    if (_currentUser == null) return;
    final updated = await _authRepository.getCurrentUser();
    if (updated != null) {
      _currentUser = updated;
      _role = updated.role;
      if (updated.activeStoreId != null) {
        _currentStore = await _authRepository.getStore(updated.activeStoreId!);
      } else {
        _currentStore = null;
      }
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_dataSubscription?.cancel());
    cart.removeListener(_onCartChanged);
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
