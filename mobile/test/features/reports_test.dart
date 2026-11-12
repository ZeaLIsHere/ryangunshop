import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ryangunshop/core/data/app_database.dart';
import 'package:ryangunshop/core/data/transaction_repository.dart';
import 'package:ryangunshop/core/theme/app_theme.dart';
import 'package:ryangunshop/core/widgets/brand_spinner.dart';
import 'package:ryangunshop/features/reports/model/report_scenario.dart';
import 'package:ryangunshop/features/reports/sample/reports_sample.dart';
import 'package:ryangunshop/features/reports/view/reports_screen.dart';

/// Lebih lama dari jeda muat pada [ReportsViewModel] agar state akhir tercapai.
const Duration _pastLoadDelay = Duration(milliseconds: 500);

void main() {
  testWidgets('menampilkan state memuat lalu ringkasan data contoh', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(_host());

    expect(find.byType(BrandSpinner), findsOneWidget);

    await tester.pump(_pastLoadDelay);
    await tester.pump();

    expect(find.byType(BrandSpinner), findsNothing);

    await tester.tap(find.text(ReportScenario.withData.label));
    await tester.pump(_pastLoadDelay);
    await tester.pump();

    expect(find.text('Rp 175.000'), findsOneWidget);
    expect(
      find.text('${ReportsSample.records.length} transaksi'),
      findsOneWidget,
    );

    final firstRecord = ReportsSample.records.first;
    expect(
      find.text('${firstRecord.timeLabel} · ${firstRecord.itemCount} barang'),
      findsOneWidget,
    );
  });

  testWidgets('skenario kosong menampilkan keadaan kosong dengan tindakan', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(_host());
    await tester.pump(_pastLoadDelay);
    await tester.pump();

    await tester.tap(find.text(ReportScenario.empty.label));
    await tester.pump();
    expect(find.byType(BrandSpinner), findsOneWidget);

    await tester.pump(_pastLoadDelay);
    await tester.pump();

    expect(find.text(ReportsSample.emptyTitle), findsOneWidget);
    expect(find.text('Kembali ke beranda'), findsOneWidget);
  });

  testWidgets('skenario gagal menampilkan keadaan gagal dengan coba lagi', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(_host());
    await tester.pump(_pastLoadDelay);
    await tester.pump();

    await tester.tap(find.text(ReportScenario.failure.label));
    await tester.pump(_pastLoadDelay);
    await tester.pump();

    expect(find.text(ReportsSample.errorTitle), findsOneWidget);
    expect(find.text(ReportsSample.errorDescription), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
  });

  testWidgets('menampilkan riwayat transaksi nyata dari repository lokal', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = TransactionRepository(database);

    await database.saveProduct(
      ProductsCompanion.insert(
        id: 'p-1',
        name: 'Minyak Goreng 2L',
        salePrice: 35000,
        stock: 5,
        updatedAt: DateTime.now(),
      ),
    );

    await repository.checkout(
      transactionId: 'TRX-LOKAL-01',
      paymentMethod: 'cash',
      totalAmount: 35000,
      cashReceived: 50000,
      changeAmount: 15000,
      lines: const [
        CheckoutLine(
          productId: 'p-1',
          quantity: 1,
          unitPrice: 35000,
          subtotal: 35000,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: ReportsScreen(repository: repository),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tersimpan di perangkat'), findsOneWidget);
    expect(find.text('Rp 35.000'), findsNWidgets(2));
    expect(find.text('1 transaksi'), findsOneWidget);
    expect(find.textContaining('Minyak Goreng 2L'), findsOneWidget);
    expect(find.textContaining('TRX-LOKAL-01'), findsOneWidget);
  });
}

Widget _host() {
  return MaterialApp(theme: AppTheme.light(), home: const ReportsScreen());
}

void _usePhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}
