import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../../core/data/product_record.dart';
import '../../../core/data/product_repository.dart';
import '../../../core/format/rupiah.dart';
import '../../../core/session/app_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../model/barcode_labels.dart';
import 'product_catalog.dart';

class BarcodeLabelsScreen extends StatefulWidget {
  const BarcodeLabelsScreen({
    this.repository,
    this.share = shareBarcodeLabels,
    super.key,
  });
  final ProductRepository? repository;
  final BarcodeLabelShare share;

  @override
  State<BarcodeLabelsScreen> createState() => _BarcodeLabelsScreenState();
}

class _BarcodeLabelsScreenState extends State<BarcodeLabelsScreen> {
  ProductRepository? _repository;
  List<ProductRecord> _products = [];
  final _quantities = <String, int>{};
  final _search = TextEditingController();
  bool _loading = true;
  bool _busy = false;
  bool _showPrice = true;
  bool _cancelled = false;
  String? _error;
  String? _message;
  int _loadVersion = 0;

  bool get _owner =>
      mounted && AppSessionScope.of(context).role.canManageProducts;
  bool get _active => _owner && !_cancelled;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_repository == null) {
      _repository =
          widget.repository ?? AppSessionScope.of(context).productRepository;
      _load();
    }
  }

  Future<void> _load({bool preserveError = false}) async {
    final version = ++_loadVersion;
    setState(() {
      _loading = true;
      if (!preserveError) _error = null;
    });
    try {
      final products = await _repository!.listProducts();
      if (!mounted || version != _loadVersion) return;
      products.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      setState(() {
        _products = products;
        _quantities.removeWhere((id, _) => !products.any((p) => p.id == id));
      });
    } catch (_) {
      if (mounted && version == _loadVersion) {
        setState(() => _error = 'Katalog lokal gagal dimuat. Coba muat ulang.');
      }
    } finally {
      if (mounted && version == _loadVersion) setState(() => _loading = false);
    }
  }

  Future<void> _generate() async {
    if (!_owner || _busy) return;
    final missing = _products
        .where(
          (p) =>
              _quantities.containsKey(p.id) &&
              (p.barcode == null || p.barcode!.isEmpty),
        )
        .toList();
    if (missing.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Simpan kode internal?'),
        content: Text(
          '${missing.length} produk tanpa barcode akan diberi kode internal RG (Code128), bukan EAN/GS1. Barcode kemasan yang sudah ada tidak diubah. Kode tersimpan tetap ada bila proses dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Simpan kode'),
          ),
        ],
      ),
    );
    if (confirmed != true || !_owner || _busy) return;
    setState(() {
      _busy = true;
      _cancelled = false;
      _error = null;
      _message = null;
    });
    var saved = 0;
    final failed = <String>[];
    for (final product in missing) {
      if (!_active) break;
      try {
        final updated = await persistInternalBarcode(
          _repository!,
          product.id,
          canManage: () => _active,
        );
        saved++;
        if (mounted) {
          setState(() {
            final index = _products.indexWhere((p) => p.id == updated.id);
            if (index >= 0) _products[index] = updated;
          });
        }
      } catch (_) {
        failed.add(product.name);
      }
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message =
          '$saved dari ${missing.length} kode terverifikasi tersimpan.${_cancelled ? ' Proses dibatalkan.' : ''}';
      if (failed.isNotEmpty) {
        _error =
            'Belum terverifikasi: ${failed.join(', ')}. Muat ulang lalu coba lagi; kode yang sudah tersimpan tidak diganti.';
      }
    });
    await _load(preserveError: true);
  }

  Future<void> _export() async {
    if (!_owner || _busy) return;
    setState(() {
      _busy = true;
      _cancelled = false;
      _error = null;
      _message = null;
    });
    try {
      final result = await exportBarcodeLabels(
        repository: _repository!,
        quantities: _quantities,
        showPrice: _showPrice,
        canManage: () => _active,
        share: widget.share,
      );
      if (!_active) return;
      setState(
        () => _message = switch (result.status) {
          ShareResultStatus.success => 'PDF diserahkan ke aplikasi tujuan. Penyimpanan atau pencetakan ditangani aplikasi tersebut.',
          ShareResultStatus.dismissed =>
            'Berbagi dibatalkan. PDF tidak diklaim tersimpan.',
          ShareResultStatus.unavailable =>
            'Menu berbagi dibuka; hasil penyimpanan tidak tersedia.',
        },
      );
    } catch (error) {
      if (mounted && !_cancelled) {
        setState(
          () => _error =
              'PDF belum dibagikan. ${error is ArgumentError
                  ? error.message
                  : error is StateError
                  ? error.message
                  : 'Gagal membuat atau membagikan PDF. Coba lagi.'}',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openCatalog() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ProductCatalog(repository: _repository),
      ),
    );
    if (mounted && _owner) await _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_owner) {
      return Scaffold(
        appBar: AppBar(title: const Text('Akses terbatas')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.screen),
            child: Text(
              'Hanya pemilik boleh mengelola dan membagikan label barcode. Ubah peran melalui Pengaturan.',
            ),
          ),
        ),
      );
    }
    final query = _search.text.trim().toLowerCase();
    final visible = _products.where(
      (p) =>
          p.name.toLowerCase().contains(query) ||
          (p.barcode?.toLowerCase().contains(query) ?? false),
    );
    final selected = _products
        .where((p) => _quantities.containsKey(p.id))
        .toList();
    final missing = selected
        .where((p) => p.barcode == null || p.barcode!.isEmpty)
        .length;
    final total = _quantities.values.fold(0, (sum, value) => sum + value);
    final valid =
        selected.isNotEmpty &&
        selected.every((p) => barcodeLabelError(p.barcode) == null) &&
        total <= 500;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Label Barcode'),
        actions: [
          IconButton(
            tooltip: 'Muat ulang katalog',
            onPressed: _busy ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.screen),
                children: [
                  const Row(
                    children: [
                      Icon(Icons.offline_bolt_outlined),
                      SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text('Data lokal • bisa dibuat tanpa internet'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'A4 • 16 label per halaman • Code128. Cetak ukuran aktual 100%, tanpa penyesuaian halaman. Uji pindai sebelum digunakan.',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _search,
                    enabled: !_busy,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Cari nama atau barcode',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Tampilkan harga'),
                    value: _showPrice,
                    onChanged: _busy
                        ? null
                        : (value) => setState(() => _showPrice = value),
                  ),
                  if (_error != null) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(child: Text(_error!)),
                      ],
                    ),
                    TextButton(
                      onPressed: _busy ? null : _load,
                      child: const Text('Muat ulang katalog'),
                    ),
                  ],
                  if (_message != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(_message!),
                      ),
                    ),
                  if (_loading)
                    const Center(child: CircularProgressIndicator())
                  else if (_products.isEmpty) ...[
                    const Text(
                      'Belum ada produk. Tambahkan produk melalui katalog, lalu pilih untuk mencetak label.',
                    ),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _openCatalog,
                      icon: const Icon(Icons.inventory_2_outlined),
                      label: const Text('Buka katalog / tambah produk'),
                    ),
                  ] else if (visible.isEmpty)
                    const Text(
                      'Produk tidak ditemukan. Coba nama atau barcode lain.',
                    )
                  else
                    for (final product in visible) ...[
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(product.name),
                        subtitle: Text(
                          product.barcode == null || product.barcode!.isEmpty
                              ? 'Belum ada barcode • perlu kode internal'
                              : '${isInternalBarcode(product.barcode) ? 'Kode internal RG' : 'Barcode produk (dipertahankan)'}\n${product.barcode}',
                        ),
                        value: _quantities.containsKey(product.id),
                        onChanged: _busy
                            ? null
                            : (value) => setState(() {
                                if (value == true) {
                                  _quantities[product.id] = 1;
                                } else {
                                  _quantities.remove(product.id);
                                }
                              }),
                      ),
                      if (_quantities.containsKey(product.id)) ...[
                        Row(
                          children: [
                            const Expanded(child: Text('Jumlah label (1–100)')),
                            IconButton(
                              tooltip: 'Kurangi label ${product.name}',
                              onPressed: _busy || _quantities[product.id]! <= 1
                                  ? null
                                  : () => setState(
                                      () => _quantities[product.id] =
                                          _quantities[product.id]! - 1,
                                    ),
                              icon: const Icon(Icons.remove),
                            ),
                            Text('${_quantities[product.id]}'),
                            IconButton(
                              tooltip: 'Tambah label ${product.name}',
                              onPressed:
                                  _busy || _quantities[product.id]! >= 100
                                  ? null
                                  : () => setState(
                                      () => _quantities[product.id] =
                                          _quantities[product.id]! + 1,
                                    ),
                              icon: const Icon(Icons.add),
                            ),
                          ],
                        ),
                        if (barcodeLabelError(product.barcode)
                            case final String error)
                          Text(error)
                        else
                          BarcodeLabelPreview(
                            product: product,
                            showPrice: _showPrice,
                          ),
                      ],
                      const Divider(),
                    ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.screen),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '$total label • ${(total + 15) ~/ 16} halaman A4 • maks. 500 label',
                  ),
                  if (_busy) ...[
                    const LinearProgressIndicator(),
                    TextButton(
                      onPressed: () => setState(() {
                        _cancelled = true;
                        _message = 'Pembatalan diminta. Penulisan yang sedang berjalan dapat selesai; kode tersimpan tidak dihapus.';
                      }),
                      child: const Text('Batalkan langkah berikutnya'),
                    ),
                  ] else ...[
                    if (missing > 0)
                      OutlinedButton(
                        onPressed: _generate,
                        child: Text('Buat kode internal ($missing produk)'),
                      ),
                    FilledButton.icon(
                      onPressed: !_loading && valid ? _export : null,
                      icon: const Icon(Icons.share_outlined),
                      label: const Text('Bagikan PDF A4'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BarcodeLabelPreview extends StatelessWidget {
  const BarcodeLabelPreview({
    required this.product,
    required this.showPrice,
    super.key,
  });
  final ProductRecord product;
  final bool showPrice;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Pratinjau label ${product.name}, barcode ${product.barcode}',
    child: Container(
      color: Colors.white,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: Colors.black),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: AppSpacing.xs),
            SizedBox(
              height: AppSpacing.minTouchTarget,
              child: CustomPaint(painter: _BarcodePainter(product.barcode!)),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(product.barcode!, textAlign: TextAlign.center),
            Text(
              '${isInternalBarcode(product.barcode) ? 'Kode internal RG' : 'Kode produk'}${showPrice ? ' • ${formatRupiah(product.salePrice)}' : ''}',
            ),
          ],
        ),
      ),
    ),
  );
}

class _BarcodePainter extends CustomPainter {
  _BarcodePainter(this.code);
  final String code;
  @override
  void paint(Canvas canvas, Size size) {
    // Ruang putih minimum 5 mm/label di PDF; preview memakai proporsi sama.
    final geometry = barcodeLabelGeometry(code, size.width);
    final quiet = geometry.quiet;
    final bars = pw.Barcode.code128().make(
      code,
      width: geometry.bars,
      height: size.height,
      drawText: false,
    );
    final paint = Paint()
      ..color = Colors.black
      ..isAntiAlias = false;
    for (final bar in bars) {
      if (bar is pw.BarcodeBar && bar.black) {
        canvas.drawRect(
          Rect.fromLTWH(quiet + bar.left, bar.top, bar.width, bar.height),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_BarcodePainter oldDelegate) => oldDelegate.code != code;
}
