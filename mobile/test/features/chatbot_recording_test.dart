import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ryangunshop/core/data/app_database.dart';
import 'package:ryangunshop/core/data/product_record.dart';
import 'package:ryangunshop/core/data/transaction_repository.dart';
import 'package:ryangunshop/core/session/app_session.dart';
import 'package:ryangunshop/features/chatbot/model/chat_action.dart';
import 'package:ryangunshop/features/chatbot/view_model/chatbot_view_model.dart';
import 'package:ryangunshop/features/checkout/model/cart_item.dart';

class LostResultRepository extends DriftTransactionRepository {
  LostResultRepository(super.database);
  bool loseResult = true;
  bool failReadback = false;
  @override
  Future<TransactionRecord?> findById(String id) async {
    if (failReadback) {
      failReadback = false;
      throw StateError('Readback unavailable');
    }
    return super.findById(id);
  }

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
    await super.checkout(
      transactionId: transactionId,
      paymentMethod: paymentMethod,
      totalAmount: totalAmount,
      lines: lines,
      discountAmount: discountAmount,
      cashReceived: cashReceived,
      changeAmount: changeAmount,
      clearCartDraft: clearCartDraft,
    );
    if (loseResult) {
      loseResult = false;
      failReadback = true;
      throw StateError('Result lost after commit');
    }
  }
}

class LostResultSession extends AppSession {
  LostResultSession(AppDatabase db) : super(database: db);
  late final repository = LostResultRepository(database!);
  @override
  TransactionRepository get transactionRepository => repository;
}

class FailedSummaryModel extends ChatbotViewModel {
  @override
  Future<Map<String, Object?>> storeSummary() async =>
      throw StateError('Summary unavailable');
}

void main() {
  late AppDatabase db;
  late AppSession session;
  late ChatbotViewModel vm;
  const product = ProductRecord(
    id: 'rice',
    name: 'Beras',
    salePrice: 15000,
    stock: 10,
  );
  Map<String, dynamic> args() => {
    'items': [
      {'product_id': 'rice', 'quantity': 2},
    ],
    'discount': 1000,
  };
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    session = AppSession(database: db);
    vm = ChatbotViewModel()..session = session;
    await session.loadLocalCart();
    await session.productRepository.save(product);
    await vm.handleTool('search_products', {'query': 'Beras'});
  });
  tearDown(() async {
    await session.finishLocalWrites();
    vm.dispose();
    session.dispose();
    await db.close();
  });

  test(
    'konfirmasi tunai uang pas, diskon, stok, laporan dan retry ID sama',
    () async {
      await vm.handleTool('prepare_sale', args());
      final action = vm.actions.single;
      expect(
        await session.transactionRepository.listForDay(DateTime.now()),
        isEmpty,
      );
      expect((await session.productRepository.listProducts()).single.stock, 10);
      final result = await Future.wait([
        vm.confirmAction(action),
        vm.confirmAction(action),
      ]);
      expect(result.where((ok) => ok).length, 1);
      final row = (await session.transactionRepository.listForDay(
        DateTime.now(),
      )).single;
      expect(row.id, action.id);
      expect(row.cashReceived, 29000);
      expect(row.changeAmount, 0);
      expect(row.discountAmount, 1000);
      expect(row.paymentMethod, 'cash');
      expect(row.items.single.quantity, 2);
      expect((await session.productRepository.listProducts()).single.stock, 8);
      expect(session.todayRevenue, 29000);
      expect((await vm.storeSummary())['jumlah_nota'], 1);
      action.state =
          ChatActionState.failure; // Pemulihan hasil panggilan yang hilang.
      expect(await vm.confirmAction(action), true);
      expect((await session.productRepository.listProducts()).single.stock, 8);
      expect(
        (await session.transactionRepository.summaryForDay(DateTime.now()))
            .count,
        1,
      );
    },
  );

  test('harga berubah harus konfirmasi ulang, stok berubah tidak mengurangi sebagian', () async {
    await vm.handleTool('prepare_sale', args());
    await session.productRepository.save(
      const ProductRecord(
        id: 'rice',
        name: 'Beras',
        salePrice: 16000,
        stock: 10,
      ),
    );
    final action = vm.actions.single;
    expect(await vm.confirmAction(action), false);
    expect(action.error, contains('Harga berubah'));
    expect(action.total, 31000);
    expect(await session.transactionRepository.findById(action.id), isNull);
    expect(await vm.confirmAction(action), true);
    expect(
      (await session.transactionRepository.findById(action.id))!.cashReceived,
      31000,
    );
    await vm.handleTool('prepare_sale', args());
    await session.productRepository.save(product.copyWith(stock: 1));
    expect(await vm.confirmAction(vm.actions.last), false);
    expect((await session.productRepository.listProducts()).single.stock, 1);
    expect(
      (await session.transactionRepository.summaryForDay(DateTime.now())).count,
      1,
    );
  });

  test('keranjang aktif, catatan, diskon dan draft disk tetap utuh', () async {
    session.cart.restoreDraft(
      const [
        CartItem(
          productId: 'rice',
          productName: 'Beras',
          unit: 'kg',
          unitPrice: 15000,
          quantity: 1,
        ),
      ],
      discount: 500,
      note: 'Simpan',
    );
    await session.flushCartDraft();
    await vm.handleTool('prepare_sale', args());
    expect(await vm.confirmAction(vm.actions.single), false);
    expect(vm.actions.single.error, contains('Selesaikan atau batalkan'));
    expect(session.cart.total, 14500);
    expect(session.cart.note, 'Simpan');
    expect(
      await session.transactionRepository.listForDay(DateTime.now()),
      isEmpty,
    );
    final restored = AppSession(database: db);
    await restored.loadLocalCart();
    expect(restored.cart.total, 14500);
    expect(restored.cart.note, 'Simpan');
    restored.dispose();
  });

  test('argumen hilang, salah, diskon penuh dan QRIS ditolak', () async {
    for (final item in [
      {'product_id': 'rice'},
      {'product_id': 'rice', 'quantity': 0},
      {'product_id': 'rice', 'quantity': -1},
      {'product_id': 'rice', 'quantity': 1.5},
      {'product_id': 'unknown', 'quantity': 1},
    ]) {
      await expectLater(
        vm.handleTool('prepare_sale', {
          'items': [item],
        }),
        throwsFormatException,
      );
    }
    for (final extra in [
      {'cash_received': 100},
      {'discount': 30000},
      {'payment_method': 'qris'},
      {'paid': true},
    ]) {
      await expectLater(
        vm.handleTool('prepare_sale', {...args(), ...extra}),
        throwsFormatException,
      );
    }
    expect(
      await session.transactionRepository.listForDay(DateTime.now()),
      isEmpty,
    );
  });

  test(
    'commit berhasil, hasil dan readback hilang, retry tidak menggandakan nota',
    () async {
      final lostSession = LostResultSession(db);
      final model = ChatbotViewModel()..session = lostSession;
      await lostSession.loadLocalCart();
      await model.handleTool('search_products', {'query': 'Beras'});
      await model.handleTool('prepare_sale', args());
      final action = model.actions.single;
      expect(await model.confirmAction(action), false);
      expect(await model.confirmAction(action), true);
      expect((await session.productRepository.listProducts()).single.stock, 8);
      expect(
        (await session.transactionRepository.summaryForDay(DateTime.now()))
            .count,
        1,
      );
      model.dispose();
      lostSession.dispose();
    },
  );

  test(
    'ringkasan gagal setelah commit tetap sukses dan tidak dapat retry',
    () async {
      final model = FailedSummaryModel()..session = session;
      await model.handleTool('search_products', {'query': 'Beras'});
      await model.handleTool('prepare_sale', args());
      final action = model.actions.single;
      expect(await model.confirmAction(action), true);
      expect(action.state, ChatActionState.success);
      expect(action.error, contains('Nota sudah tercatat'));
      expect(await model.confirmAction(action), false);
      expect(
        (await session.transactionRepository.summaryForDay(DateTime.now()))
            .count,
        1,
      );
      model.dispose();
    },
  );

  test('repository rollback seluruh stok jika satu barang gagal', () async {
    await expectLater(
      session.transactionRepository.checkout(
        transactionId: 'atomic',
        paymentMethod: 'cash',
        totalAmount: 30001,
        cashReceived: 30001,
        changeAmount: 0,
        clearCartDraft: false,
        lines: const [
          CheckoutLine(
            productId: 'rice',
            quantity: 2,
            unitPrice: 15000,
            subtotal: 30000,
          ),
          CheckoutLine(
            productId: 'missing',
            quantity: 1,
            unitPrice: 1,
            subtotal: 1,
          ),
        ],
      ),
      throwsA(anything),
    );
    expect((await session.productRepository.listProducts()).single.stock, 10);
    expect(await session.transactionRepository.findById('atomic'), isNull);
  });
}
