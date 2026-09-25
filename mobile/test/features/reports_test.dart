import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
    expect(find.text('Kembali ke denah'), findsOneWidget);
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
}

Widget _host() {
  return MaterialApp(theme: AppTheme.light(), home: const ReportsScreen());
}

void _usePhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}
