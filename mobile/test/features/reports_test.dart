import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ryangunshop/core/data/app_database.dart';
import 'package:ryangunshop/core/data/in_memory_transaction_repository.dart';
import 'package:ryangunshop/core/data/transaction_repository.dart';
import 'package:ryangunshop/core/theme/app_theme.dart';
import 'package:ryangunshop/core/widgets/brand_spinner.dart';
import 'package:ryangunshop/features/reports/view/reports_screen.dart';
import 'package:ryangunshop/features/reports/view_model/reports_view_model.dart';

void main() {
  late AppDatabase database;
  late TransactionRepository repository;
  final day = DateTime(2026, 11, 14);

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = TransactionRepository(database);
  });
  tearDown(() => database.close());

  Future<void> insert(
    String id,
    DateTime time, {
    String method = 'cash',
    int net = 9000,
    int discount = 1000,
    String productId = 'p',
    String name = 'Nama saat dijual',
    int quantity = 2,
    int gross = 10000,
  }) async {
    await database
        .into(database.transactions)
        .insert(
          TransactionsCompanion.insert(
            id: id,
            createdAt: time,
            totalAmount: net,
            discountAmount: Value(discount),
            paymentMethod: method,
            cashReceived: const Value(20000),
            changeAmount: Value(20000 - net),
          ),
        );
    await database
        .into(database.transactionItems)
        .insert(
          TransactionItemsCompanion.insert(
            transactionId: id,
            productId: productId,
            productName: name,
            quantity: quantity,
            unitPrice: gross ~/ quantity,
            subtotal: gross,
          ),
        );
  }

  test(
    'hari lokal inklusif tengah malam, eksklusif hari berikut; lebih dari 50',
    () async {
      await insert('before', day.subtract(const Duration(seconds: 1)));
      await insert('start', day);
      for (var i = 0; i < 60; i++) {
        await insert('t$i', day.add(Duration(minutes: i + 1)));
      }
      await insert('last', DateTime(2026, 11, 14, 23, 59, 59));
      await insert('next', DateTime(2026, 11, 15));
      final records = await repository.listForDay(day);
      expect(records, hasLength(62));
      expect(records.last.id, 'start');
      expect(records.first.id, 'last');
      expect(records.any((r) => r.id == 'before' || r.id == 'next'), isFalse);
      final summary = await repository.summaryForDay(day);
      expect(summary.count, 62);
      expect(summary.total, 62 * 9000);
      expect(await repository.listForDay(DateTime(2026, 11, 12)), isEmpty);
    },
  );

  test(
    'aritmetika, metode asli, agregasi produk dan snapshot tidak ikut katalog',
    () async {
      await insert('a', day, method: 'cash');
      await insert(
        'b',
        day.add(const Duration(hours: 1)),
        method: 'bank_transfer',
        net: 15000,
        discount: 0,
        quantity: 3,
        gross: 15000,
      );
      await insert(
        'c',
        day.add(const Duration(hours: 2)),
        method: 'qris',
        productId: 'other',
        name: 'Barang lain',
        net: 1000,
        discount: 0,
        quantity: 1,
        gross: 1000,
      );
      await database.saveProduct(
        ProductsCompanion.insert(
          id: 'p',
          name: 'Nama katalog berubah',
          salePrice: 999999,
          stock: 1,
          updatedAt: DateTime.now(),
        ),
      );
      final model = ReportsViewModel(repository: repository, day: day);
      addTearDown(model.dispose);
      await model.load();
      expect(model.totalAmount, 25000);
      expect(model.discountAmount, 1000);
      expect(model.grossAmount, 26000);
      expect(model.averageAmount, closeTo(25000 / 3, 0.001));
      expect(model.paymentBreakdown['bank_transfer'], (count: 1, total: 15000));
      expect(model.paymentBreakdown['cash'], (count: 1, total: 9000));
      expect(model.paymentBreakdown['qris'], (count: 1, total: 1000));
      expect(reportPaymentLabel('bank_transfer'), 'bank_transfer');
      expect(model.soldProducts.first.quantity, 5);
      expect(model.soldProducts.first.gross, 25000);
      final snapshot = model.dailyRecords.last.items.single;
      expect(snapshot.productName, 'Nama saat dijual');
      expect(snapshot.unitPrice, 5000);
      expect(snapshot.quantity, 2);
      expect(snapshot.subtotal, 10000);
      expect(model.dailyRecords.last.cashReceived, 20000);
      expect(model.dailyRecords.last.changeAmount, 11000);
      await model.selectDay(DateTime(2026, 11, 10));
      expect(model.totalAmount, 0);
      expect(model.averageAmount, 0);
      expect(model.paymentBreakdown, isEmpty);
    },
  );

  test(
    'repository memori menyimpan snapshot dan mendukung laporan harian',
    () async {
      final memory = InMemoryTransactionRepository();
      await memory.checkout(
        transactionId: 'memory',
        paymentMethod: 'cash',
        totalAmount: 100,
        lines: const [
          CheckoutLine(
            productId: 'p',
            quantity: 1,
            unitPrice: 100,
            subtotal: 100,
          ),
        ],
      );
      final record = (await memory.listRecent()).single;
      expect(
        (await memory.listForDay(record.createdAt))
            .single
            .items
            .single
            .subtotal,
        100,
      );
      expect((await memory.summaryForDay(record.createdAt)).count, 1);
      expect(await memory.listForDay(DateTime(1970)), isEmpty);
    },
  );

  test('hasil permintaan lama tidak menimpa tanggal baru', () async {
    final fake = _ControlledRepository();
    final model = ReportsViewModel(repository: fake, day: day);
    addTearDown(model.dispose);
    final first = model.load();
    final second = model.selectDay(DateTime(2026, 11, 15));
    fake.requests[1].complete([]);
    await second;
    fake.requests[0].completeError(StateError('lama'));
    await first;
    expect(model.status, ReportsStatus.ready);
    expect(model.selectedDay, DateTime(2026, 11, 15));
  });

  testWidgets('memuat, gagal, coba lagi, kosong dan pemilih tanggal', (
    tester,
  ) async {
    _phone(tester);
    final fake = _ControlledRepository();
    await tester.pumpWidget(_host(fake));
    expect(find.byType(BrandSpinner), findsOneWidget);
    fake.requests.single.completeError(StateError('database gagal'));
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.text('Coba lagi').hitTestable(),
      find.byType(ListView),
      const Offset(0, -150),
    );
    expect(find.text('Coba lagi'), findsOneWidget);
    expect(find.text('Penjualan bersih'), findsNothing);
    await tester.tap(find.text('Coba lagi'));
    await tester.pump();
    fake.requests.last.complete([]);
    await tester.pumpAndSettle();
    expect(find.text('Pilih tanggal lain'), findsOneWidget);
    final today = DateTime.now();
    expect(fake.days.first, DateTime(today.year, today.month, today.day));
    await tester.dragUntilVisible(
      find.text('Pilih tanggal lain').hitTestable(),
      find.byType(ListView),
      const Offset(0, -150),
    );
    await tester.tap(find.text('Pilih tanggal lain'));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    '360 dp skala 1.3: ringkasan, semua produk, detail snapshot dan target 48',
    (tester) async {
      _phone(tester);
      final now = DateTime.now();
      for (var i = 0; i < 6; i++) {
        await insert(
          'nota-$i',
          now,
          productId: 'p$i',
          name: 'Produk $i nama panjang saat transaksi',
          method: i == 0 ? 'bank_transfer' : 'cash',
        );
      }
      await tester.pumpWidget(_host(repository));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 150));
      });
      await tester.pumpAndSettle();
      expect(find.text('6 transaksi'), findsOneWidget);
      expect(find.textContaining('waktu lokal perangkat'), findsOneWidget);
      expect(find.textContaining('WIB'), findsNothing);
      await tester.dragUntilVisible(
        find.text('Lihat semua produk').hitTestable(),
        find.byType(ListView),
        const Offset(0, -200),
      );
      for (final element in find.byType(TextButton).evaluate()) {
        final size = tester.getSize(find.byWidget(element.widget));
        expect(size.height, greaterThanOrEqualTo(48));
        expect(size.width, greaterThanOrEqualTo(48));
      }
      await tester.tap(find.text('Lihat semua produk'));
      await tester.pumpAndSettle();
      expect(find.text('Tampilkan 5 teratas'), findsOneWidget);
      await tester.dragUntilVisible(
        find.text('Lihat nota').first.hitTestable(),
        find.byType(ListView),
        const Offset(0, -150),
      );
      await tester.tap(find.text('Lihat nota').first);
      await tester.pumpAndSettle();
      expect(find.text('Detail nota'), findsOneWidget);
      expect(find.text('Produk 0 nama panjang saat transaksi'), findsOneWidget);
      expect(find.text('bank_transfer'), findsOneWidget);
      expect(find.text('2 × Rp 5.000'), findsOneWidget);
      await tester.dragUntilVisible(
        find.text('Kembalian').hitTestable(),
        find.byType(ListView),
        const Offset(0, -150),
      );
      expect(find.text('Rp 11.000'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

Widget _host(TransactionRepository repository) => MaterialApp(
  theme: AppTheme.light(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context)
        .copyWith(textScaler: const TextScaler.linear(1.3)),
    child: child!,
  ),
  home: ReportsScreen(repository: repository),
);

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

class _ControlledRepository extends InMemoryTransactionRepository {
  final requests = <Completer<List<TransactionRecord>>>[];
  final days = <DateTime>[];

  @override
  Future<List<TransactionRecord>> listForDay(DateTime day) {
    days.add(day);
    final request = Completer<List<TransactionRecord>>();
    requests.add(request);
    return request.future;
  }
}
