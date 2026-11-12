import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ryangunshop/core/data/app_database.dart';
import 'package:ryangunshop/core/session/app_session.dart';
import 'package:ryangunshop/core/theme/app_theme.dart';
import 'package:ryangunshop/features/statistics/view/statistics_screen.dart';

void main() {
  testWidgets('statistik tanpa sesi menampilkan state kosong pada 360 dp', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!,
        ),
        home: const StatisticsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Statistik'), findsOneWidget);
    expect(find.text('Belum ada data'), findsOneWidget);
    expect(find.text('Tren penjualan'), findsOneWidget);
    expect(find.text('Belum ada data transaksi produk'), findsOneWidget);
    expect(find.text('Belum ada data metode pembayaran'), findsOneWidget);
    expect(find.textContaining('Deterjen'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('statistik menampilkan data lokal bila tersedia di sesi', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    await database.saveProduct(
      ProductsCompanion.insert(
        id: 'stat-p1',
        name: 'Gula Pasir 1kg',
        salePrice: 15000,
        costPrice: const Value(12000),
        stock: 10,
        updatedAt: DateTime.now(),
      ),
    );
    final session = AppSession(database: database);
    addTearDown(session.dispose);

    await tester.pumpWidget(
      AppSessionScope(
        session: session,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const StatisticsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tersimpan di perangkat'), findsOneWidget);
    // Nilai inventaris: 15000 * 10 = Rp 150.000
    expect(find.text('Rp 150.000'), findsOneWidget);
    expect(find.text('10'), findsWidgets);
  });
}
