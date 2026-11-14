import 'package:flutter/material.dart';

import '../../../core/data/product_record.dart';
import '../../../core/data/transaction_repository.dart' as db;
import '../../../core/format/rupiah.dart';
import '../../../core/session/app_session.dart';
import '../../../core/session/user_role.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../model/dashboard_period.dart';
import '../../../core/widgets/app_card.dart';
import '../../catalog/model/catalog_product.dart';
import '../../catalog/view/barcode_labels_screen.dart';
import '../../catalog/view/product_catalog.dart';
import '../../catalog/view/product_form_screen.dart';
import '../model/dashboard_shortcut.dart';

typedef _DashboardData = ({
  List<ProductRecord> products,
  List<db.TransactionRecord> daily,
  DashboardPeriod period,
});

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({
    required this.onShortcutSelected,
    this.onStartScan,
    super.key,
  });

  final ValueChanged<DashboardShortcut> onShortcutSelected;
  final VoidCallback? onStartScan;

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  Future<_DashboardData>? _data;
  int? _transactionCount;
  bool _adding = false;
  int _days = 1;

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
    final period = DashboardPeriod(DateTime.now(), _days);
    final daily = await session.transactionRepository.listForPeriod(
      period.start,
      period.end,
    );
    return (products: products, daily: daily, period: period);
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
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screen),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Kelola warung',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          const Row(
            children: [
              Icon(Icons.phone_android_outlined, color: AppColors.primary),
              SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text('Data perangkat ini · dapat dibuka offline'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            children: [
              for (final entry in {
                1: 'Hari ini',
                7: '7 hari',
                30: '30 hari',
              }.entries)
                ChoiceChip(
                  label: Text(entry.value),
                  selected: _days == entry.key,
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  onSelected: (_) => setState(() {
                    _days = entry.key;
                    _data = _load();
                  }),
                ),
            ],
          ),
          FutureBuilder<_DashboardData>(
            future: _data,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Center(
                    child: CircularProgressIndicator(
                      semanticsLabel: 'Memuat beranda',
                    ),
                  ),
                );
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return Column(
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
                (sum, row) => sum + row.totalAmount,
              );
              final sold = <String, ({String name, int quantity, int gross})>{};
              for (final row in data.daily) {
                for (final item in row.items) {
                  final old = sold[item.productId];
                  sold[item.productId] = (
                    name: old?.name ?? item.productName,
                    quantity: (old?.quantity ?? 0) + item.quantity,
                    gross: (old?.gross ?? 0) + item.subtotal,
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
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    '${_date(data.period.start)} – ${_date(DateTime(data.period.end.year, data.period.end.month, data.period.end.day - 1))} · waktu lokal perangkat',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: const BoxDecoration(
                      color: AppColors.primarySubtle,
                      borderRadius: AppRadius.panelBorder,
                      border: Border(
                        left: BorderSide(
                          color: AppColors.primary,
                          width: AppSpacing.xxs,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Penjualan bersih: ${formatRupiah(total)}',
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          '${data.daily.length} nota',
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          'Rata-rata per nota: ${formatRupiah(data.daily.isEmpty ? 0 : (total / data.daily.length).round())}',
                        ),
                      ],
                    ),
                  ),
                  _heading('Penjualan harian'),
                  _SalesChart(points: data.period.dailyTotals(data.daily)),
                  if (data.daily.isEmpty) ...[
                    const Text('Belum ada penjualan pada periode ini.'),
                    _action(
                      'Buka Kasir',
                      Icons.point_of_sale,
                      () => _shortcut(DashboardShortcut.cashier),
                    ),
                  ],
                  _heading('Perlu perhatian'),
                  const Text(
                    'Kondisi stok saat ini · tidak mengikuti periode penjualan',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _stockLine(
                          Icons.remove_shopping_cart_outlined,
                          'Stok kosong: ${data.products.where((p) => p.stock == 0).length} produk',
                        ),
                        _stockLine(
                          Icons.warning_amber_rounded,
                          'Stok menipis: ${data.products.where((p) => p.stock > 0 && p.stock <= p.lowStockThreshold).length} produk',
                        ),
                        _stockLine(
                          Icons.barcode_reader,
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
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      _action(
                        'Tambah Produk',
                        Icons.add,
                        _adding ? null : _addProduct,
                      ),
                      _action(
                        'Kelola Stok',
                        Icons.inventory_2_outlined,
                        () => _openManagement(
                          Scaffold(
                            appBar: AppBar(title: const Text('Kelola Stok')),
                            body: SafeArea(
                              child: ProductCatalog(
                                repository: AppSessionScope.of(context)
                                    .productRepository,
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
                    ],
                  ),
                  _heading('Produk terlaris'),
                  const Text(
                    'Jumlah barang dan penjualan kotor sebelum diskon nota. Snapshot saat transaksi.',
                  ),
                  if (top.isEmpty)
                    const Text('Belum ada rincian barang terjual.'),
                  for (final item in top.take(5))
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '${item.value.name} · ${item.value.quantity} barang',
                            style: theme.textTheme.titleMedium,
                          ),
                          Text('Kotor: ${formatRupiah(item.value.gross)}'),
                        ],
                      ),
                    ),
                  _heading('Nota terbaru'),
                  const Text('Nota dalam periode terpilih'),
                  if (data.daily.isEmpty)
                    const Text('Belum ada nota pada periode ini.'),
                  for (final row in data.daily.take(5))
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xs,
                      ),
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              row.summaryTitle,
                              style: theme.textTheme.titleMedium,
                            ),
                            Text(row.id),
                            Text(
                              '${_date(row.createdAt.toLocal())} · ${TimeOfDay.fromDateTime(row.createdAt.toLocal()).format(context)}',
                            ),
                            Text(formatRupiah(row.totalAmount)),
                          ],
                        ),
                      ),
                    ),
                  _action(
                    'Lihat semua nota',
                    Icons.receipt_long_outlined,
                    () => _shortcut(DashboardShortcut.reports),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          _action('Muat ulang', Icons.refresh, _reload),
        ],
      ),
    );
  }

  Widget _stockLine(IconData icon, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: Row(
      children: [
        Icon(icon, color: AppColors.muted),
        const SizedBox(width: AppSpacing.xs),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

String _date(DateTime date) => '${date.day}/${date.month}/${date.year}';

class _SalesChart extends StatelessWidget {
  const _SalesChart({required this.points});
  final List<({DateTime date, int total})> points;

  @override
  Widget build(BuildContext context) {
    final maximum = points.fold(
      0,
      (value, point) => point.total > value ? point.total : value,
    );
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Penjualan bersih (Rp) · maksimum ${formatRupiah(maximum)}'),
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final point in points)
                  Semantics(
                    label: '${_date(point.date)}: ${formatRupiah(point.total)}',
                    child: ExcludeSemantics(
                      child: SizedBox(
                        width: AppSpacing.minTouchTarget + AppSpacing.xl,
                        child: Column(
                          children: [
                            Text(
                              formatRupiah(point.total),
                              style: Theme.of(context).textTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(
                              height: AppSpacing.minTouchTarget * 2,
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  width: AppSpacing.lg,
                                  height: maximum == 0
                                      ? 0
                                      : AppSpacing.minTouchTarget *
                                            2 *
                                            point.total /
                                            maximum,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius:
                                        AppRadius.controlCompactBorder,
                                  ),
                                ),
                              ),
                            ),
                            const Divider(),
                            Text('${point.date.day}/${point.date.month}'),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            points.length > 1
                ? 'Tanggal · geser untuk melihat semua hari · dasar Rp 0'
                : 'Tanggal · dasar Rp 0',
          ),
        ],
      ),
    );
  }
}
