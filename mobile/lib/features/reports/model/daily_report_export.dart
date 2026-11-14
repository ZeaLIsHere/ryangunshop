import 'package:excel_plus/excel_plus.dart' as xl;

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../../core/data/transaction_repository.dart' as db;
import '../../../core/format/rupiah.dart';
import '../view_model/reports_view_model.dart';

/// Snapshot satu hari: tidak berubah bila layar memuat tanggal lain saat ekspor.
class DailyReportExport {
  DailyReportExport(ReportsViewModel model, {DateTime? generatedAt})
    : day = model.selectedDay,
      generatedAt = (generatedAt ?? DateTime.now()).toLocal(),
      records = List<db.TransactionRecord>.unmodifiable(model.dailyRecords),
      gross = model.grossAmount,
      discount = model.discountAmount,
      net = model.totalAmount,
      average = model.averageAmount,
      payments = Map.unmodifiable(model.paymentBreakdown),
      products = List.unmodifiable(model.soldProducts) {
    if (!model.isLocal || model.status != ReportsStatus.ready) {
      throw StateError('Laporan lokal belum siap. Muat ulang laporan.');
    }
  }

  final DateTime day;
  final DateTime generatedAt;
  final List<db.TransactionRecord> records;
  final int gross;
  final int discount;
  final int net;
  final double average;
  final Map<String, ({int count, int total})> payments;
  final List<({String id, String name, int quantity, int gross})> products;

  String get date =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';
  String filename(String extension) => 'laporan-harian-$date.$extension';

  static const xlsxMimeType =
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

  Uint8List xlsx() {
    final workbook = xl.Excel.createExcel();
    workbook.rename('Sheet1', 'Ringkasan');
    final rupiah = xl.CellStyle(
      numberFormat: xl.NumFormat.custom(formatCode: '"Rp" #,##0.00'),
    );
    final header = xl.CellStyle(
      bold: true,
      textWrapping: xl.TextWrapping.WrapText,
    );

    void row(xl.Sheet sheet, List<Object> values, {bool heading = false}) {
      final index = sheet.maxRows;
      for (var column = 0; column < values.length; column++) {
        final value = values[column];
        // Teks tidak dipercaya selalu bertipe teks, termasuk awalan =, +, -, @.
        sheet.updateCell(
          xl.CellIndex.indexByColumnRow(columnIndex: column, rowIndex: index),
          switch (value) {
            int n => xl.IntCellValue(n),
            double n => xl.DoubleCellValue(n),
            _ => xl.TextCellValue(value.toString()),
          },
          cellStyle: heading
              ? header
              : value is num
              ? rupiah
              : null,
        );
      }
    }

    void widths(xl.Sheet sheet, List<double> values) {
      for (var i = 0; i < values.length; i++) {
        sheet.setColumnWidth(i, values[i]);
      }
    }

    void count(xl.Sheet sheet, int column, int rowIndex) {
      sheet
          .cell(
            xl.CellIndex.indexByColumnRow(
              columnIndex: column,
              rowIndex: rowIndex,
            ),
          )
          .cellStyle = xl.CellStyle(
        numberFormat: xl.NumFormat.standard_0,
      );
    }

    final summary = workbook['Ringkasan'];
    widths(summary, [44, 90, 24]);
    row(summary, ['RyanGunshop - Laporan harian', 'Nilai'], heading: true);
    row(summary, ['Tanggal laporan (lokal perangkat)', date]);
    row(summary, ['Dibuat (lokal perangkat)', generatedAt.toIso8601String()]);
    row(summary, [
      'Cakupan',
      'Transaksi pada perangkat ini saja; bukan gabungan semua perangkat. Ekspor dibuat lokal tanpa layanan jaringan.',
    ]);
    row(summary, ['Penjualan kotor sebelum diskon nota', gross]);
    row(summary, ['Diskon nota', discount]);
    row(summary, ['Penjualan bersih', net]);
    row(summary, ['Jumlah nota', records.length]);
    count(summary, 1, 7);
    row(summary, ['Rata-rata bersih per nota', average]);
    row(summary, [
      'Nilai barang',
      'Kotor sebelum diskon nota; diskon nota tidak dialokasikan ke produk. Nama memakai snapshot penjualan.',
    ]);
    row(summary, [
      'Metode pembayaran tercatat',
      'Jumlah nota',
      'Penjualan bersih',
    ], heading: true);
    for (final entry in payments.entries) {
      row(summary, [
        reportPaymentLabel(entry.key),
        entry.value.count,
        entry.value.total,
      ]);
      count(summary, 1, summary.maxRows - 1);
    }
    if (records.isEmpty) {
      row(summary, ['Tidak ada transaksi pada tanggal ini.']);
    }

    final transactions = workbook['Transaksi'];
    widths(transactions, [30, 32, 26, 18, 30, 24, 24]);
    row(transactions, [
      'Tanggal/jam nota (lokal perangkat)',
      'ID nota',
      'Metode pembayaran',
      'Jumlah barang',
      'Kotor sebelum diskon nota',
      'Diskon nota',
      'Penjualan bersih',
    ], heading: true);
    for (final record in records) {
      row(transactions, [
        record.createdAt.toLocal().toIso8601String(),
        record.id,
        reportPaymentLabel(record.paymentMethod),
        record.itemCount,
        record.totalAmount + record.discountAmount,
        record.discountAmount,
        record.totalAmount,
      ]);
      count(transactions, 3, transactions.maxRows - 1);
    }

    final sold = workbook['Barang Terjual'];
    widths(sold, [32, 48, 18, 32]);
    row(sold, [
      'ID produk',
      'Nama produk (snapshot)',
      'Jumlah barang',
      'Kotor sebelum diskon nota',
    ], heading: true);
    for (final product in products) {
      row(sold, [product.id, product.name, product.quantity, product.gross]);
      count(sold, 2, sold.maxRows - 1);
    }
    return Uint8List.fromList(workbook.encode()!);
  }

  Future<Uint8List> pdf() async {
    // Font dibundel aplikasi; tidak memakai Google Fonts atau unduhan jaringan.
    final regular = pw.Font.ttf(
      await rootBundle.load('assets/fonts/PlusJakartaSans-Regular.ttf'),
    );
    final bold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/PlusJakartaSans-Bold.ttf'),
    );
    final document = pw.Document(compress: false);
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        // Batas mengikuti isi, bukan batas bawaan 20 halaman.
        maxPages: products.length + payments.length + 10,
        theme: pw.ThemeData.withFont(base: regular, bold: bold),
        footer: (context) => pw.Text(
          'RyanGunshop | Halaman ${context.pageNumber}/${context.pagesCount}',
        ),
        build: (_) => [
          pw.Header(level: 0, text: 'RyanGunshop - Laporan harian'),
          pw.Text('Tanggal laporan: $date (waktu lokal perangkat)'),
          pw.Text(
            'Dibuat: ${generatedAt.toIso8601String()} (waktu lokal perangkat)',
          ),
          pw.Paragraph(
            text:
                'Cakupan: transaksi pada perangkat ini saja. '
                'Bukan gabungan semua perangkat. Ekspor dibuat lokal tanpa layanan jaringan.',
          ),
          pw.Text(
            'Penjualan kotor sebelum diskon nota: ${formatRupiah(gross)}',
          ),
          pw.Text('Diskon nota: ${formatRupiah(discount)}'),
          pw.Text('Penjualan bersih: ${formatRupiah(net)}'),
          pw.Text('Jumlah nota: ${records.length}'),
          pw.Text(
            'Rata-rata bersih per nota: ${formatRupiah(average.round())} '
            '(dibulatkan ke rupiah terdekat)',
          ),
          if (records.isEmpty)
            pw.Paragraph(text: 'Tidak ada transaksi pada tanggal ini.'),
          pw.Header(level: 1, text: 'Metode pembayaran tercatat'),
          for (final entry in payments.entries)
            pw.Text(
              '${reportPaymentLabel(entry.key)}: ${entry.value.count} nota; '
              'bersih ${formatRupiah(entry.value.total)}',
            ),
          pw.Header(level: 1, text: 'Semua produk terjual'),
          pw.Paragraph(
            text:
                'Nilai produk adalah kotor sebelum diskon nota. '
                'Diskon nota tidak dialokasikan ke produk. Nama memakai snapshot penjualan.',
          ),
          if (products.isEmpty) pw.Text('Rincian barang tidak tersimpan.'),
          // Widget per produk memungkinkan MultiPage memisahkan daftar tanpa dipotong.
          for (final product in products)
            pw.Paragraph(
              text:
                  '${product.name} [${product.id}]\n'
                  '${product.quantity} barang | Kotor sebelum diskon nota: '
                  '${formatRupiah(product.gross)}',
            ),
        ],
      ),
    );
    return document.save();
  }
}

/// Membuka tujuan berbagi native; hasil bukan bukti berkas tersimpan permanen.
Future<void> shareDailyReport(
  Uint8List bytes,
  String filename,
  String mimeType,
) async {
  await SharePlus.instance.share(
    ShareParams(
      title: 'Bagikan laporan harian',
      files: [XFile.fromData(bytes, mimeType: mimeType)],
      fileNameOverrides: [filename],
    ),
  );
}

typedef ReportShare = Future<void> Function(
  Uint8List bytes,
  String filename,
  String mimeType,
);
