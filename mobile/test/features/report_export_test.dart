import 'dart:async';
import 'dart:convert';

import 'package:excel_plus/excel_plus.dart' as xl;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ryangunshop/core/data/transaction_repository.dart';
import 'package:ryangunshop/core/theme/app_theme.dart';
import 'package:ryangunshop/features/reports/model/daily_report_export.dart';
import 'package:ryangunshop/features/reports/view/reports_screen.dart';
import 'package:ryangunshop/features/reports/view_model/reports_view_model.dart';

final day = DateTime(2026, 11, 14);
TransactionRecord receipt(String id, {int items = 1}) => TransactionRecord(
  id: id,
  createdAt: day.add(const Duration(hours: 23, minutes: 59)),
  totalAmount: items * 10001 - 1,
  discountAmount: 1,
  paymentMethod: '@metode',
  itemCount: items,
  items: [
    for (var i = 0; i < items; i++)
      TransactionItemSnapshot(
        productId: 'p$i',
        productName: '=Kopi "é", susu\r\nBaris $i',
        quantity: 1,
        unitPrice: 10001,
        subtotal: 10001,
      ),
  ],
);

class Repository implements TransactionRepository {
  Repository(this.records);
  final List<TransactionRecord> records;
  Completer<List<TransactionRecord>>? pending;
  @override
  Future<List<TransactionRecord>> listForDay(DateTime day) async =>
      pending == null ? records : pending!.future;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

xl.Data cell(xl.Sheet sheet, String address) =>
    sheet.cell(xl.CellIndex.indexByString(address));

num number(xl.Data data) => switch (data.value) {
  xl.IntCellValue value => value.value,
  xl.DoubleCellValue value => value.value,
  _ => throw StateError('Sel bukan angka: ${data.value}'),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ReportsViewModel> model(List<TransactionRecord> records) async {
    final result = ReportsViewModel(repository: Repository(records), day: day);
    addTearDown(result.dispose);
    await result.load();
    return result;
  }

  test(
    'Excel tiga lembar, Unicode, angka, tanggal, format dan teks bukan formula',
    () async {
      final ids = [
        '=SUM(1,2)',
        '+cmd',
        '-cmd',
        '@cmd',
        '\tcmd',
        '\rcmd',
        '  =cmd',
        '\ncmd',
        'Nota "é",\r\nakhir',
      ];
      final source = await model([for (final id in ids) receipt(id, items: 2)]);
      final report = DailyReportExport(source, generatedAt: day);
      final workbook = xl.Excel.decodeBytes(report.xlsx());
      expect(workbook.tables.keys, [
        'Ringkasan',
        'Transaksi',
        'Barang Terjual',
      ]);
      final transactions = workbook['Transaksi'];
      final rows = transactions.rows;
      expect(rows.length, ids.length + 1);
      expect(rows.first[4]!.value.toString(), 'Kotor sebelum diskon nota');
      for (var i = 0; i < ids.length; i++) {
        final row = rows[i + 1];
        expect(row.length, 7);
        expect(row[0]!.value, isA<xl.TextCellValue>());
        expect(
          DateTime.parse(row[0]!.value.toString()),
          day.add(const Duration(hours: 23, minutes: 59)),
        );
        expect(row[1]!.value, isA<xl.TextCellValue>());
        expect(row[1]!.value.toString(), ids[i]);
        expect(row[2]!.value, isA<xl.TextCellValue>());
        expect(row[2]!.value.toString(), '@metode');
        expect(number(row[3]!), 2);
        expect(number(row[4]!), 20002);
        expect(number(row[5]!), 1);
        expect(number(row[6]!), 20001);
        expect(row[4]!.cellStyle!.numberFormat.formatCode, '"Rp" #,##0.00');
      }
      expect(report.net, ids.length * 20001);
      expect(report.gross - report.discount, report.net);
      expect(report.average, 20001);
      expect(report.payments['@metode']!.count, ids.length);
      expect(report.products.length, 2);
      final summary = workbook['Ringkasan'];
      expect(cell(summary, 'B2').value.toString(), '2026-11-14');
      expect(cell(summary, 'B3').value.toString(), day.toIso8601String());
      expect(
        cell(summary, 'B4').value.toString(),
        contains('perangkat ini saja'),
      );
      expect(number(cell(summary, 'B5')), report.gross);
      expect(number(cell(summary, 'B6')), report.discount);
      expect(number(cell(summary, 'B7')), report.net);
      expect(number(cell(summary, 'B8')), ids.length);
      expect(number(cell(summary, 'B9')), report.average);
      expect(cell(summary, 'A12').value, isA<xl.TextCellValue>());
      expect(cell(summary, 'A12').value.toString(), '@metode');
      expect(number(cell(summary, 'B12')), ids.length);
      expect(number(cell(summary, 'C12')), report.net);
      final sold = workbook['Barang Terjual'];
      expect(sold.maxRows, 3);
      for (var i = 1; i < sold.rows.length; i++) {
        expect(sold.rows[i][0]!.value, isA<xl.TextCellValue>());
        expect(sold.rows[i][1]!.value, isA<xl.TextCellValue>());
        expect(
          sold.rows[i][1]!.value.toString(),
          '=Kopi "é", susu\r\nBaris ${i - 1}',
        );
        expect(number(sold.rows[i][2]!), ids.length);
        expect(number(sold.rows[i][3]!), ids.length * 10001);
      }
      for (final sheet in workbook.tables.values) {
        expect(cell(sheet, 'A1').cellStyle!.isBold, isTrue);
        for (final row in sheet.rows) {
          for (final data in row) {
            expect(data?.value, isNot(isA<xl.FormulaCellValue>()));
          }
        }
      }
      expect(report.filename('xlsx'), 'laporan-harian-2026-11-14.xlsx');
      await source.selectDay(DateTime(2026, 11, 15));
      expect(report.date, '2026-11-14');
      expect(report.records.length, ids.length);
    },
  );

  test(
    'Excel semua 250 nota dan 700 produk; kosong tetap workbook valid',
    () async {
      final report = DailyReportExport(
        await model([
          for (var i = 0; i < 250; i++) receipt('n$i', items: i == 0 ? 700 : 1),
        ]),
      );
      final workbook = xl.Excel.decodeBytes(report.xlsx());
      expect(workbook['Transaksi'].maxRows, 251);
      expect(cell(workbook['Transaksi'], 'B251').value.toString(), 'n249');
      expect(workbook['Barang Terjual'].maxRows, 701);
      expect(
        workbook['Barang Terjual'].rows
            .skip(1)
            .fold<num>(0, (sum, row) => sum + number(row[3]!)),
        report.gross,
      );
      final empty = DailyReportExport(await model([]));
      final emptyWorkbook = xl.Excel.decodeBytes(empty.xlsx());
      expect(emptyWorkbook['Transaksi'].maxRows, 1);
      expect(emptyWorkbook['Barang Terjual'].maxRows, 1);
      expect(number(cell(emptyWorkbook['Ringkasan'], 'B7')), 0);
      expect(number(cell(emptyWorkbook['Ringkasan'], 'B9')), 0);
      expect(empty.net, 0);
      expect(empty.average, 0);
    },
  );

  test('Excel rata-rata pecahan dan rincian pembayaran tetap angka', () async {
    final report = DailyReportExport(
      await model([
        receipt('tunai'),
        TransactionRecord(
          id: 'qris',
          createdAt: day,
          totalAmount: 10001,
          discountAmount: 0,
          paymentMethod: 'qris',
          itemCount: 1,
          items: receipt('qris').items,
        ),
      ]),
    );
    final summary = xl.Excel.decodeBytes(report.xlsx())['Ringkasan'];
    expect(number(cell(summary, 'B9')), 10000.5);
    expect(summary.rows.skip(11).map((row) => number(row[1]!)).toList(), [
      1,
      1,
    ]);
    expect(
      summary.rows.skip(11).fold<num>(0, (sum, row) => sum + number(row[2]!)),
      20001,
    );
    expect(
      cell(summary, 'B9').cellStyle!.numberFormat.formatCode,
      '"Rp" #,##0.00',
    );
  });

  test('PDF valid A4 multipage, seluruh produk melampaui 20 halaman', () async {
    final report = DailyReportExport(await model([receipt('all', items: 700)]));
    final bytes = await report.pdf();
    final pdf = latin1.decode(bytes);
    expect(pdf.startsWith('%PDF-'), isTrue);
    expect(pdf.trimRight().endsWith('%%EOF'), isTrue);
    expect(RegExp(r'/Type\s*/Page\b').allMatches(pdf).length, greaterThan(20));
    final box = RegExp(r'/MediaBox\s*\[0 0 ([\d.]+) ([\d.]+)\]')
        .firstMatch(pdf)!;
    expect(double.parse(box[1]!), closeTo(595.276, 0.01));
    expect(double.parse(box[2]!), closeTo(841.89, 0.01));
    expect(report.products.length, 700);
    final emptyPdf = await DailyReportExport(await model([])).pdf();
    expect(latin1.decode(emptyPdf), startsWith('%PDF-'));
  });

  testWidgets('berbagi terinjeksi, terkunci, gagal/retry, 360dp skala 1.3', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = Repository([receipt('nota')])..pending = Completer();
    var shared = <String>[];
    var pending = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!,
        ),
        home: ReportsScreen(
          repository: repository,
          shareReport: (bytes, filename, mime) async {
            shared.add('$filename|$mime');
            expect(bytes, isNotEmpty);
            if (filename.endsWith('.xlsx')) {
              final workbook = xl.Excel.decodeBytes(bytes);
              expect(workbook.tables.keys, [
                'Ringkasan',
                'Transaksi',
                'Barang Terjual',
              ]);
              expect(workbook['Transaksi'].maxRows, 2);
            }
            await pending.future;
          },
        ),
      ),
    );
    TextButton button(String label) =>
        tester.widget<TextButton>(find.widgetWithText(TextButton, label));
    expect(button('Bagikan Excel').onPressed, isNull);
    repository.pending!.complete(repository.records);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bagikan Excel'));
    await tester.pump();
    expect(shared.single, endsWith('.xlsx|${DailyReportExport.xlsxMimeType}'));
    expect(button('Bagikan PDF').onPressed, isNull);
    expect(button('Muat ulang').onPressed, isNull);
    pending.completeError(StateError('share gagal'));
    await tester.pumpAndSettle();
    expect(
      find.text('Ekspor gagal. Coba lagi lewat tombol bagikan.'),
      findsOneWidget,
    );
    pending = Completer<void>()..complete();
    await tester.tap(find.text('Bagikan PDF'));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(seconds: 2));
    });
    await tester.pumpAndSettle();
    expect(shared.last, endsWith('.pdf|application/pdf'));
    expect(button('Bagikan Excel').onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });
}
