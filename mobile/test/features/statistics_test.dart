import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ryangunshop/core/format/rupiah.dart';
import 'package:ryangunshop/core/theme/app_theme.dart';
import 'package:ryangunshop/features/statistics/sample/statistics_sample.dart';
import 'package:ryangunshop/features/statistics/view/statistics_screen.dart';

void main() {
  testWidgets('statistik menampilkan ringkasan contoh pada 360 dp skala 1,3', (
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

    final today = StatisticsSample.forPeriod(StatisticsPeriod.today);

    expect(find.text('Statistik'), findsOneWidget);
    expect(find.text(formatRupiah(today.total)), findsOneWidget);
    expect(find.text('Tren 7 hari terakhir'), findsOneWidget);
    expect(find.text(today.topProducts.first.name), findsOneWidget);
    expect(find.textContaining('Perlu restok'), findsOneWidget);
    expect(find.text('Metode pembayaran'), findsOneWidget);
    expect(find.text('Margin produk'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pemilih periode menukar ringkasan', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const StatisticsScreen()),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        formatRupiah(StatisticsSample.forPeriod(StatisticsPeriod.today).total),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text(StatisticsPeriod.week.label));
    await tester.pumpAndSettle();

    expect(
      find.text(
        formatRupiah(StatisticsSample.forPeriod(StatisticsPeriod.week).total),
      ),
      findsOneWidget,
    );
  });
}
