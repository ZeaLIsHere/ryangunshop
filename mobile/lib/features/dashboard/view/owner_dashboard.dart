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
import '../../../core/widgets/sales_line_chart.dart';
import '../../catalog/model/catalog_product.dart';
import '../../catalog/view/barcode_labels_screen.dart';
import '../../catalog/view/product_catalog.dart';
import '../../catalog/view/product_form_screen.dart';
import '../model/dashboard_shortcut.dart';
import '../../../core/session/completed_transaction.dart';
import 'dashboard_components.dart';
import '../../monitor/view/monitor_screen.dart';

typedef _DashboardData = ({
  List<ProductRecord> products,
  List<db.TransactionRecord> daily,
  DashboardPeriod period,
  List<db.TransactionRecord> recent,
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
  int? _dataRevision;
  bool _adding = false;
  int _days = 7;

  bool get _owner =>
      mounted && AppSessionScope.maybeOf(context)?.role == UserRole.owner;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = AppSessionScope.maybeOf(context);
    final count = session?.todayTransactionCount;
    final revision = session?.dataRevision;
    if (_data == null ||
        count != _transactionCount ||
        revision != _dataRevision) {
      _dataRevision = revision;
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
    final recent = await session.transactionRepository.listRecent(limit: 20);
    return (products: products, daily: daily, period: period, recent: recent);
  }

  Future<void> _reload() async {
    await AppSessionScope.maybeOf(context)?.refreshCloud(force: true);
    if (mounted) {
      setState(() {
        _data = _load();
      });
    }
  }

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
    child: Text(
      title,
      style: Theme.of(context).textTheme.titleMedium
          ?.copyWith(fontWeight: FontWeight.bold),
    ),
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

                  DashboardHeroCard(
                    daily: data.daily,
                    title: 'Penjualan Bersih',

                    actionLabel: 'Lihat laporan',
                    actionIcon: Icons.assessment_outlined,
                    onPressed: () {
                      if (_owner) _shortcut(DashboardShortcut.reports);
                    },
                  ),
                  _heading('Penjualan harian'),
                  SalesLineChart(points: data.period.dailyTotals(data.daily)),

                  _heading('Status Stok'),
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
                  _heading('Aksi Kelola'),
                  AppCard(
                    onTap: () => _openManagement(const MonitorScreen()),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primarySubtle,
                            borderRadius: BorderRadius.circular(
                              AppRadius.squircle,
                            ),
                          ),
                          child: const Icon(
                            Icons.space_dashboard_outlined,
                            color: AppColors.primary,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Monitor Toko',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Pantau stok rak & tata letak 3D isometrik',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: AppColors.muted,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  LayoutBuilder(
                    builder: (context, constraints) => Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        _managementPod(
                          constraints,
                          'Tambah Produk',
                          Icons.add,
                          _adding ? null : _addProduct,
                        ),
                        _managementPod(
                          constraints,
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
                        _managementPod(
                          constraints,
                          'Label Barcode',
                          Icons.barcode_reader,
                          () => _openManagement(const BarcodeLabelsScreen()),
                        ),
                        _managementPod(
                          constraints,
                          'Laporan',
                          Icons.assessment_outlined,
                          () {
                            if (_owner) _shortcut(DashboardShortcut.reports);
                          },
                        ),
                      ],
                    ),
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
                  const Text('Nota transaksi kasir terbaru'),
                  const SizedBox(height: AppSpacing.sm),
                  Builder(
                    builder: (context) {
                      final now = DateTime.now();
                      final sourceRows = data.recent.isNotEmpty
                          ? data.recent
                          : data.daily;
                      final nonFuture = sourceRows
                          .where((t) => !t.createdAt.toLocal().isAfter(now))
                          .toList();
                      final realTransactions = nonFuture
                          .where((t) => !t.id.endsWith('-RG1'))
                          .toList();
                      final displayRows =
                          (realTransactions.isNotEmpty
                                  ? realTransactions
                                  : nonFuture)
                              .take(5)
                              .toList();

                      return AppCard(
                        child: Column(
                          children: [
                            if (displayRows.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: AppSpacing.md,
                                ),
                                child: Text('Belum ada nota transaksi.'),
                              ),
                            for (final row in displayRows) ...[
                              DashboardTransactionRow(
                                receiptId: row.id,
                                transaction: CompletedTransaction(
                                  id: row.id,
                                  title: row.summaryTitle,
                                  amount: row.totalAmount,
                                  timeLabel:
                                      '${_date(row.createdAt.toLocal())} · ${TimeOfDay.fromDateTime(row.createdAt.toLocal()).format(context)}',
                                  itemCount: row.itemCount,
                                  paymentMethod: row.paymentMethod,
                                ),
                              ),
                              if (row != displayRows.last)
                                const Divider(height: 1),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                  _action(
                    'Lihat semua nota',
                    Icons.receipt_long_outlined,
                    () => _shortcut(DashboardShortcut.reports),
                  ),
                  DashboardShortcutsSection(onShortcutSelected: _shortcut),
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

  Widget _managementPod(
    BoxConstraints constraints,
    String label,
    IconData icon,
    VoidCallback? action,
  ) => SizedBox(
    width: (constraints.maxWidth - AppSpacing.xs) / 2,
    child: DashboardActionPod(
      icon: icon,
      label: label,
      bgColor: AppColors.primarySubtle,
      iconColor: AppColors.primary,
      onTap: action,
    ),
  );

  Widget _stockLine(IconData icon, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: Row(
      children: [
        Container(
          width: AppSpacing.minTouchTarget,
          height: AppSpacing.minTouchTarget,
          decoration: const BoxDecoration(
            color: AppColors.primarySubtle,
            borderRadius: AppRadius.controlBorder,
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

String _date(DateTime date) => '${date.day}/${date.month}/${date.year}';
