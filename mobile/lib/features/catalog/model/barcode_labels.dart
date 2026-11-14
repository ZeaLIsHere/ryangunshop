import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../../core/data/product_record.dart';
import '../../../core/data/product_repository.dart';
import '../../../core/format/rupiah.dart';

const barcodeLabelsFilename = 'ryangunshop-label-barcode-a4.pdf';
typedef BarcodeLabelShare = Future<ShareResult> Function(Uint8List bytes);

Future<ShareResult> shareBarcodeLabels(Uint8List bytes) =>
    SharePlus.instance.share(
      ShareParams(
        title: 'Bagikan label barcode A4',
        files: [XFile.fromData(bytes, mimeType: 'application/pdf')],
        fileNameOverrides: [barcodeLabelsFilename],
      ),
    );

/// Batas panjang menjaga modul Code128 cukup lebar pada label cetak 91 mm.
String? barcodeLabelError(String? code) {
  if (code == null || code.isEmpty) {
    return 'Belum ada barcode. Buat kode internal dahulu.';
  }
  if (code.length > 24) {
    return 'Barcode lebih dari 24 karakter; tidak muat aman pada label ini.';
  }
  if (!RegExp(r'^[\x20-\x7E]+$').hasMatch(code) || code.trim() != code) {
    return 'Barcode harus memakai karakter ASCII cetak tanpa spasi di awal/akhir.';
  }
  try {
    pw.Barcode.code128().verify(code);
  } catch (_) {
    return 'Barcode tidak dapat dicetak sebagai Code128.';
  }
  return null;
}

/// Quiet zone minimal sepuluh modul, termasuk untuk kode sangat pendek.
({double quiet, double bars}) barcodeLabelGeometry(String code, double width) {
  final elements = pw.Barcode.code128()
      .make(code, width: 1, height: 1, drawText: false)
      .whereType<pw.BarcodeBar>();
  final module = elements
      .map((bar) => bar.width)
      .reduce((a, b) => a < b ? a : b);
  final proportional = width * 10 / (1 / module + 20);
  final minimum =
      width *
      BarcodeLabelsDocument.quietZone /
      BarcodeLabelsDocument.labelWidth;
  final quiet = proportional > minimum ? proportional : minimum;
  return (quiet: quiet, bars: width - 2 * quiet);
}

bool isInternalBarcode(String? code) =>
    code != null && RegExp(r'^RG[0-9A-F]{12}(?:-[0-9]+)?$').hasMatch(code);

String internalBarcode(String id, Iterable<String> used) {
  // Hash stabil, bukan String.hashCode yang tidak dijamin lintas proses.
  var hash = 0x811c9dc5;
  for (final unit in id.codeUnits) {
    hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
  }
  var second = 0;
  for (final unit in id.codeUnits.reversed) {
    second = (second * 31 + unit) & 0xffff;
  }
  final base =
      'RG${hash.toRadixString(16).padLeft(8, '0')}${second.toRadixString(16).padLeft(4, '0')}'
          .toUpperCase();
  final taken = used.toSet();
  var code = base;
  for (var suffix = 1; taken.contains(code); suffix++) {
    code = '$base-$suffix';
  }
  if (barcodeLabelError(code) != null) {
    throw StateError('Ruang kode internal habis.');
  }
  return code;
}

void requireBarcodeOwner(bool Function() canManage) {
  if (!canManage()) {
    throw StateError('Akses berubah. Hanya pemilik boleh mengelola label.');
  }
}

/// Dipanggil hanya sesudah konfirmasi. Baca ulang agar seluruh kolom lain tetap utuh.
Future<ProductRecord> persistInternalBarcode(
  ProductRepository repository,
  String productId, {
  required bool Function() canManage,
}) async {
  requireBarcodeOwner(canManage);
  final records = await repository.listProducts();
  requireBarcodeOwner(canManage);
  final matches = records.where((p) => p.id == productId);
  if (matches.isEmpty) {
    throw StateError('Produk sudah dihapus. Muat ulang katalog.');
  }
  final product = matches.single;
  if (product.barcode != null && product.barcode!.isNotEmpty) return product;
  final code = internalBarcode(
    product.id,
    records.map((p) => p.barcode).whereType<String>(),
  );
  final collision = await repository.findByBarcode(code);
  requireBarcodeOwner(canManage);
  if (collision != null) throw StateError('Kode sudah digunakan. Coba lagi.');
  final updated = ProductRecord(
    id: product.id,
    barcode: code,
    name: product.name,
    salePrice: product.salePrice,
    stock: product.stock,
    costPrice: product.costPrice,
    category: product.category,
    unit: product.unit,
    fixtureId: product.fixtureId,
    locationLabel: product.locationLabel,
    lowStockThreshold: product.lowStockThreshold,
  );
  await repository.save(updated);
  requireBarcodeOwner(canManage);
  final saved = await repository.findByBarcode(code);
  requireBarcodeOwner(canManage);
  if (saved == null || saved.id != product.id) {
    throw StateError(
      'Kode belum terverifikasi tersimpan. Muat ulang sebelum mencetak.',
    );
  }
  return saved;
}

class BarcodeLabelLine {
  BarcodeLabelLine(this.product, this.quantity) {
    if (quantity < 1 || quantity > 100) {
      throw ArgumentError('Jumlah label harus 1–100 per produk.');
    }
    final error = barcodeLabelError(product.barcode);
    if (error != null) throw ArgumentError('${product.name}: $error');
  }
  final ProductRecord product;
  final int quantity;
}

class BarcodeLabelsDocument {
  BarcodeLabelsDocument(
    Iterable<BarcodeLabelLine> lines, {
    this.showPrice = true,
  }) : lines = List.unmodifiable(lines) {
    if (this.lines.isEmpty || labelCount > 500) {
      throw ArgumentError('Pilih 1–500 label per ekspor.');
    }
  }
  final List<BarcodeLabelLine> lines;
  final bool showPrice;
  int get labelCount => lines.fold(0, (sum, line) => sum + line.quantity);
  int get pageCount => (labelCount + labelsPerPage - 1) ~/ labelsPerPage;
  static const labelsPerPage = 16;
  static const margin = 12 * PdfPageFormat.mm;
  static const gap = 4 * PdfPageFormat.mm;
  static const labelHeight = 30 * PdfPageFormat.mm;
  static const quietZone = 5 * PdfPageFormat.mm;
  static final labelWidth = (PdfPageFormat.a4.width - 2 * margin - gap) / 2;

  Future<Uint8List> pdf() async {
    final font = pw.Font.ttf(
      await rootBundle.load('assets/fonts/PlusJakartaSans-Regular.ttf'),
    );
    final document = pw.Document();
    final labels = [
      for (final line in lines)
        for (var i = 0; i < line.quantity; i++) line.product,
    ];
    for (var offset = 0; offset < labels.length; offset += labelsPerPage) {
      final page = labels.skip(offset).take(labelsPerPage).toList();
      document.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(margin),
          theme: pw.ThemeData.withFont(base: font),
          build: (_) => pw.Column(
            children: [
              for (var row = 0; row < (page.length + 1) ~/ 2; row++)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: gap),
                  child: pw.Row(
                    children: [
                      _label(page[row * 2]),
                      pw.SizedBox(width: gap),
                      if (row * 2 + 1 < page.length) _label(page[row * 2 + 1]),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    }
    return document.save();
  }

  pw.Widget _label(ProductRecord product) => pw.Container(
    width: labelWidth,
    height: labelHeight,
    color: PdfColors.white,
    padding: const pw.EdgeInsets.symmetric(
      horizontal: quietZone,
      vertical: 2 * PdfPageFormat.mm,
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.SizedBox(
          height: 20,
          child: pw.Text(
            product.name,
            maxLines: 2,
            overflow: pw.TextOverflow.clip,
            style: const pw.TextStyle(fontSize: 8),
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Padding(
          padding: pw.EdgeInsets.symmetric(
            horizontal:
                barcodeLabelGeometry(product.barcode!, labelWidth).quiet -
                quietZone,
          ),
          child: pw.BarcodeWidget(
            barcode: pw.Barcode.code128(),
            data: product.barcode!,
            drawText: false,
            height: 28,
            color: PdfColors.black,
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          product.barcode!,
          textAlign: pw.TextAlign.center,
          style: const pw.TextStyle(fontSize: 7),
        ),
        pw.Text(
          '${isInternalBarcode(product.barcode) ? 'Internal RG' : 'Kode produk'}${showPrice ? ' | ${formatRupiah(product.salePrice)}' : ''}',
          maxLines: 1,
          style: const pw.TextStyle(fontSize: 7),
        ),
      ],
    ),
  );
}

/// Snapshot repository baru, tidak pernah mengekspor draft kode yang belum disimpan.
Future<ShareResult> exportBarcodeLabels({
  required ProductRepository repository,
  required Map<String, int> quantities,
  required bool showPrice,
  required bool Function() canManage,
  required BarcodeLabelShare share,
}) async {
  requireBarcodeOwner(canManage);
  final selection = Map<String, int>.of(quantities);
  final products = await repository.listProducts();
  requireBarcodeOwner(canManage);
  final byId = {for (final product in products) product.id: product};
  final lines = <BarcodeLabelLine>[];
  for (final entry in selection.entries) {
    final product = byId[entry.key];
    if (product == null) {
      throw StateError('Produk sudah dihapus. Muat ulang katalog.');
    }
    lines.add(BarcodeLabelLine(product, entry.value));
  }
  final bytes = await BarcodeLabelsDocument(lines, showPrice: showPrice).pdf();
  requireBarcodeOwner(canManage);
  return share(bytes);
}
