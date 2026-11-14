import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ryangunshop/core/data/transaction_repository.dart';
import 'package:ryangunshop/core/session/app_session.dart';
import 'package:ryangunshop/core/session/user_role.dart';
import 'package:ryangunshop/core/theme/app_theme.dart';
import 'package:ryangunshop/features/reports/view/reports_screen.dart';

class _Repository implements TransactionRepository {
  @override
  Future<List<TransactionRecord>> listForDay(DateTime day) async => [
    TransactionRecord(
      id: 'nota-izin',
      createdAt: day,
      totalAmount: 9000,
      discountAmount: 1000,
      paymentMethod: 'cash',
      itemCount: 2,
      items: const [
        TransactionItemSnapshot(
          productId: 'p',
          productName: 'Kopi snapshot',
          quantity: 2,
          unitPrice: 5000,
          subtotal: 10000,
        ),
      ],
    ),
  ];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late AppSession session;
  setUp(() => session = AppSession());
  tearDown(() => session.dispose());

  Future<void> host(WidgetTester tester, {Widget? screen}) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      AppSessionScope(
        session: session,
        child: MaterialApp(
          theme: AppTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          ),
          home: screen ?? ReportsScreen(repository: _Repository()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'kasir hanya riwayat dan detail nota, tanpa agregat maupun ekspor',
    (tester) async {
      session.selectRole(UserRole.cashier);
      await host(tester);
      for (final text in ['Riwayat Nota', 'Daftar nota', 'nota-izin']) {
        await tester.scrollUntilVisible(
          find.text(text),
          160,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text(text), findsOneWidget);
      }
      for (final text in [
        'Bagikan PDF',
        'Bagikan Excel',
        'Ringkasan harian',
        'Metode pembayaran tercatat',
        'Produk terlaris',
      ]) {
        expect(find.text(text), findsNothing);
      }
      await tester.scrollUntilVisible(
        find.text('Lihat nota'),
        160,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Lihat nota'));
      await tester.pumpAndSettle();
      expect(find.text('Detail nota'), findsOneWidget);
      expect(find.text('Kopi snapshot'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'handler lama ditolak setelah role kasir; role pemilik dapat pulih',
    (tester) async {
      var shares = 0;
      await host(
        tester,
        screen: ReportsScreen(
          repository: _Repository(),
          shareReport: (Uint8List bytes, String name, String mime) async {
            shares++;
          },
        ),
      );
      await tester.scrollUntilVisible(
        find.text('Bagikan Excel'),
        140,
        scrollable: find.byType(Scrollable).first,
      );
      final button = tester.widget<TextButton>(
        find.ancestor(
          of: find.text('Bagikan Excel'),
          matching: find.byType(TextButton),
        ),
      );
      session.selectRole(UserRole.cashier);
      button.onPressed!();
      await tester.pumpAndSettle();
      expect(shares, 0);
      expect(find.text('Bagikan Excel'), findsNothing);
      expect(find.text('Ringkasan harian'), findsNothing);
      session.selectRole(UserRole.owner);
      await tester.pumpAndSettle();
      expect(find.text('Bagikan Excel'), findsOneWidget);
    },
  );

  testWidgets('role berubah selama PDF async tidak membagikan laporan', (
    tester,
  ) async {
    var shares = 0;
    await host(
      tester,
      screen: ReportsScreen(
        repository: _Repository(),
        shareReport: (Uint8List bytes, String name, String mime) async {
          shares++;
        },
      ),
    );
    await tester.scrollUntilVisible(
      find.text('Bagikan PDF'),
      140,
      scrollable: find.byType(Scrollable).first,
    );
    final button = tester.widget<TextButton>(
      find.ancestor(
        of: find.text('Bagikan PDF'),
        matching: find.byType(TextButton),
      ),
    );
    button.onPressed!();
    session.selectRole(UserRole.cashier);
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(shares, 0);
    expect(find.text('Bagikan PDF'), findsNothing);
  });
}
