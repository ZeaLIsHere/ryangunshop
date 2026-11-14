import 'package:flutter/material.dart';

import '../../../core/data/product_record.dart';
import '../../../core/data/transaction_repository.dart' as db;
import '../../../core/format/rupiah.dart';
import '../../../core/session/app_session.dart';
import '../../../core/session/user_role.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../catalog/model/catalog_product.dart';
import '../../catalog/view/barcode_labels_screen.dart';
import '../../catalog/view/product_catalog.dart';
import '../../catalog/view/product_form_screen.dart';
import '../model/dashboard_shortcut.dart';

typedef _DashboardData = ({
  List<ProductRecord> products,
  List<db.TransactionRecord> daily,
  List<db.TransactionRecord> recent,
});

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    required this.onShortcutSelected,
    this.onStartScan,
    super.key,
  });

  final ValueChanged<DashboardShortcut> onShortcutSelected;
  final VoidCallback? onStartScan;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Future<_DashboardData>? _data;
  int? _transactionCount;
  bool _adding = false;

  bool get _owner =>
      mounted && AppSessionScope.maybeOf(context)?.role == UserRole.owner;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final count = AppSessionScope.maybeOf(context)?.todayTransactionCount;
    if (_data == null || count != _transactionCount) {
      _transactionCount = count;
      _data = _load();
    }
  }

  Future<_DashboardData> _load() async {
    final session = AppSessionScope.maybeOf(context);
    if (session == null) throw StateError('Sesi belum tersedia');
    final products = await session.productRepository.listProducts();
    final daily = await session.transactionRepository.listForDay(
      DateTime.now(),
    );
    final recent = await session.transactionRepository.listRecent(limit: 5);
    return (products: products, daily: daily, recent: recent);
  }

  void _reload() => setState(() {
    _data = _load();
  });

  Future<void> _addProduct() async {
    if (!_owner || _adding) return;
    setState(() => _adding = true);
    CatalogProduct? pending;
    try {
      final session = AppSessionScope.of(context);
      final products = await session.productRepository.listProducts();
      if (!mounted || !_owner) return;
      pending = await Navigator.of(context).push<CatalogProduct>(
        MaterialPageRoute(
          builder: (_) => ProductFormScreen(
            isLocal: true,
            existingProducts: products.map(CatalogProduct.fromRecord).toList(),
          ),
        ),
      );
      if (!mounted || !_owner || pending == null) return;
      await session.productRepository.save(pending.toRecord());
      if (!mounted) return;
      _reload();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            pending == null
                ? 'Produk gagal dimuat. Coba lagi.'
                : 'Produk belum tersimpan. Coba simpan lagi.',
          ),
          action: pending == null
              ? null
              : SnackBarAction(
                  label: 'Coba lagi',
                  onPressed: () => _retrySave(pending!),
                ),
        ),
      );
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  Future<void> _retrySave(CatalogProduct product) async {
    if (!_owner) return;
    try {
      await AppSessionScope.of(context).productRepository
          .save(product.toRecord());
      if (mounted) _reload();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Produk belum tersimpan. Coba lagi.'),
          action: SnackBarAction(
            label: 'Coba lagi',
            onPressed: () => _retrySave(product),
          ),
        ),
      );
    }
  }

  Future<void> _openManagement(Widget page) async {
    if (!_owner) return;
    await Navigator.of(context)
        .push<void>(MaterialPageRoute(builder: (_) => page));
    if (mounted) _reload();
  }

  Widget _action(String label, IconData icon, VoidCallback? action) =>
      OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(
            AppSpacing.minTouchTarget,
            AppSpacing.minTouchTarget,
          ),
          padding: const EdgeInsets.all(AppSpacing.sm),
        ),
        onPressed: action,
        icon: Icon(icon),
        label: Text(label),
      );

  Widget _heading(String title) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
    child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
  );

  void _shortcut(DashboardShortcut shortcut) =>
      widget.onShortcutSelected(shortcut);

  @override
  Widget build(BuildContext context) {
    final owner = _owner;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screen),
      children: [
        Text(
          owner ? 'Kelola warung' : 'Siap melayani',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        const Row(
          children: [
            Icon(Icons.phone_android_outlined),
            SizedBox(width: AppSpacing.xs),
            Expanded(child: Text('Data perangkat ini · dapat dibuka offline')),
          ],
        ),
        const Text('Peran dari Pengaturan adalah mode UI, bukan autentikasi.'),
        _heading('Aksi Cepat'),
        if (owner) ...[
          _action('Tambah Produk', Icons.add, _adding ? null : _addProduct),
          _action(
            'Kelola Stok',
            Icons.inventory_2_outlined,
            () => _openManagement(
              Scaffold(
                appBar: AppBar(title: const Text('Kelola Stok')),
                body: SafeArea(
                  child: ProductCatalog(
                    repository: AppSessionScope.of(context).productRepository,
                  ),
                ),
              ),
            ),
          ),
          _action(
            'Label Barcode',
            Icons.barcode_reader,
            () => _openManagement(const BarcodeLabelsScreen()),
          ),
          _action('Laporan', Icons.assessment_outlined, () {
            if (_owner) _shortcut(DashboardShortcut.reports);
          }),
        ] else ...[
          _action(
            'Pindai Barcode',
            Icons.qr_code_scanner,
            widget.onStartScan ?? () => _shortcut(DashboardShortcut.cashier),
          ),
          _action(
            'Buka Kasir',
            Icons.point_of_sale,
            () => _shortcut(DashboardShortcut.cashier),
          ),
          _action(
            'Stok',
            Icons.inventory_2_outlined,
            () => _shortcut(DashboardShortcut.catalog),
          ),
          _action(
            'Riwayat Nota',
            Icons.receipt_long_outlined,
            () => _shortcut(DashboardShortcut.reports),
          ),
        ],
        _action('Muat ulang', Icons.refresh, _reload),
        FutureBuilder<_DashboardData>(
          future: _data,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(
                  semanticsLabel: 'Memuat beranda',
                ),
              );
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.error_outline),
                  const Text(
                    'Data beranda gagal dimuat. Angka belum tersedia.',
                  ),
                  _action('Coba lagi', Icons.refresh, _reload),
                ],
              );
            }
            final data = snapshot.data!;
            final total = data.daily.fold(
              0,
              (sum, record) => sum + record.totalAmount,
            );
            final sold = <String, ({String name, int quantity, DateTime at})>{};
            for (final record in data.daily) {
              for (final item in record.items) {
                final old = sold[item.productId];
                sold[item.productId] = (
                  name: old == null || record.createdAt.isAfter(old.at)
                      ? item.productName
                      : old.name,
                  quantity: (old?.quantity ?? 0) + item.quantity,
                  at: old == null || record.createdAt.isAfter(old.at)
                      ? record.createdAt
                      : old.at,
                );
              }
            }
            final top = sold.entries.toList()
              ..sort((a, b) {
                final quantity = b.value.quantity.compareTo(a.value.quantity);
                return quantity != 0 ? quantity : a.key.compareTo(b.key);
              });
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (owner) ...[
                  _heading('Hari ini'),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Penjualan bersih: ${formatRupiah(total)}'),
                        Text('${data.daily.length} nota'),
                        Text(
                          'Rata-rata per nota: ${formatRupiah(data.daily.isEmpty ? 0 : (total / data.daily.length).round())}',
                        ),
                      ],
                    ),
                  ),
                  if (data.daily.isEmpty)
                    const Text(
                      'Belum ada penjualan hari ini. Nota tersimpan akan muncul di sini.',
                    ),
                  _heading('Perlu perhatian'),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Stok kosong: ${data.products.where((p) => p.stock == 0).length} produk',
                        ),
                        Text(
                          'Stok menipis: ${data.products.where((p) => p.stock > 0 && p.stock <= p.lowStockThreshold).length} produk',
                        ),
                        Text(
                          'Tanpa barcode: ${data.products.where((p) => p.barcode == null || p.barcode!.trim().isEmpty).length} produk',
                        ),
                      ],
                    ),
                  ),
                  if (data.products.isEmpty) ...[
                    const Text('Katalog kosong. Tambahkan produk pertama.'),
                    _action(
                      'Tambah Produk pertama',
                      Icons.add,
                      _adding ? null : _addProduct,
                    ),
                  ],
                  _heading('Produk terlaris hari ini'),
                  const Text(
                    'Jumlah dari snapshot barang pada nota, bukan stok saat ini.',
                  ),
                  if (top.isEmpty)
                    const Text('Belum ada rincian barang terjual.'),
                  for (final item in top.take(5))
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xs,
                      ),
                      child: Text(
                        '${item.value.name} · ${item.value.quantity} barang',
                      ),
                    ),
                ],
                _heading('Nota terbaru'),
                if (data.recent.isEmpty)
                  const Text(
                    'Belum ada nota. Buka Kasir untuk mencatat penjualan.',
                  ),
                for (final record in data.recent)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(record.summaryTitle),
                          Text(record.id),
                          Text(
                            '${TimeOfDay.fromDateTime(record.createdAt.toLocal()).format(context)} · ${formatRupiah(record.totalAmount)}',
                          ),
                        ],
                      ),
                    ),
                  ),
                _action(
                  'Lihat semua nota',
                  Icons.receipt_long_outlined,
                  () => _shortcut(DashboardShortcut.reports),
                ),
                if (data.recent.isEmpty)
                  _action(
                    'Buka Kasir',
                    Icons.point_of_sale,
                    () => _shortcut(DashboardShortcut.cashier),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
