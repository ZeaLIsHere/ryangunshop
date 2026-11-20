import 'package:flutter/material.dart';

import 'dart:ui' as ui;

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
import '../../../core/session/completed_transaction.dart';
import 'dashboard_components.dart';
import '../../monitor/view/monitor_screen.dart';

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
    return (products: products, daily: daily, period: period);
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
                  _SalesChart(points: data.period.dailyTotals(data.daily)),

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
                  const Text('Nota dalam periode terpilih'),
                  const SizedBox(height: AppSpacing.sm),
                  AppCard(
                    child: Column(
                      children: [
                        if (data.daily.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: AppSpacing.md,
                            ),
                            child: Text('Belum ada nota pada periode ini.'),
                          ),
                        for (final row in data.daily.take(5)) ...[
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
                          if (row != data.daily.take(5).last)
                            const Divider(height: 1),
                        ],
                      ],
                    ),
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

class _SalesChart extends StatefulWidget {
  const _SalesChart({required this.points});
  final List<({DateTime date, int total})> points;

  @override
  State<_SalesChart> createState() => _SalesChartState();
}

class _SalesChartState extends State<_SalesChart> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final points = widget.points;
    final maximum = points.fold<int>(
      0,
      (value, point) => point.total > value ? point.total : value,
    );

    final selectedIdx =
        (_selectedIndex != null && _selectedIndex! < points.length)
        ? _selectedIndex!
        : (points.isNotEmpty ? points.length - 1 : 0);
    final selectedPoint = points.isNotEmpty ? points[selectedIdx] : null;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Penjualan bersih',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      selectedPoint != null
                          ? formatRupiah(selectedPoint.total)
                          : formatRupiah(0),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              if (selectedPoint != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primarySubtle,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    _date(selectedPoint.date),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final chartWidth = constraints.maxWidth;
              const chartHeight = 150.0;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanDown: (details) =>
                    _handleTouch(details.localPosition.dx, chartWidth),
                onPanUpdate: (details) =>
                    _handleTouch(details.localPosition.dx, chartWidth),
                child: CustomPaint(
                  size: Size(chartWidth, chartHeight),
                  painter: _LineChartPainter(
                    points: points,
                    maximum: maximum,
                    selectedIndex: selectedIdx,
                    primaryColor: AppColors.primary,
                    gridColor: AppColors.borderSubtle,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildDateAxis(context, points),
          const SizedBox(height: AppSpacing.xs),
          Text(
            points.length > 1
                ? 'Sentuh grafik untuk melihat nominal per tanggal · Maksimum ${formatRupiah(maximum)}'
                : 'Maksimum omzet hari ini ${formatRupiah(maximum)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.muted,
              fontSize: 11,
            ),
          ),
          for (final point in points)
            Semantics(
              container: true,
              label: '${_date(point.date)}: ${formatRupiah(point.total)}',
              child: const SizedBox(width: 1, height: 1),
            ),
        ],
      ),
    );
  }

  void _handleTouch(double dx, double width) {
    if (widget.points.length <= 1 || width <= 0) return;
    final count = widget.points.length;
    final index = ((dx / width) * (count - 1)).round().clamp(0, count - 1);
    if (_selectedIndex != index) {
      setState(() => _selectedIndex = index);
    }
  }

  Widget _buildDateAxis(
    BuildContext context,
    List<({DateTime date, int total})> points,
  ) {
    final theme = Theme.of(context);
    if (points.isEmpty) return const SizedBox.shrink();
    if (points.length == 1) {
      return Center(
        child: Text(
          '${points.first.date.day}/${points.first.date.month}',
          style: theme.textTheme.labelSmall?.copyWith(color: AppColors.muted),
        ),
      );
    }

    final count = points.length;
    const maxLabels = 4;
    final displayedIndices = <int>[];
    if (count <= maxLabels) {
      for (var i = 0; i < count; i++) {
        displayedIndices.add(i);
      }
    } else {
      final step = (count - 1) / (maxLabels - 1);
      for (var i = 0; i < maxLabels; i++) {
        final idx = (i * step).round().clamp(0, count - 1);
        if (!displayedIndices.contains(idx)) {
          displayedIndices.add(idx);
        }
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final idx in displayedIndices)
          Flexible(
            child: Text(
              '${points[idx].date.day}/${points[idx].date.month}',
              textAlign: idx == displayedIndices.first
                  ? TextAlign.start
                  : (idx == displayedIndices.last
                        ? TextAlign.end
                        : TextAlign.center),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: idx == _selectedIndex
                    ? AppColors.primary
                    : AppColors.muted,
                fontWeight: idx == _selectedIndex
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
      ],
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.points,
    required this.maximum,
    required this.selectedIndex,
    required this.primaryColor,
    required this.gridColor,
  });

  final List<({DateTime date, int total})> points;
  final int maximum;
  final int selectedIndex;
  final Color primaryColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final width = size.width;
    final height = size.height;
    const topMargin = 16.0;
    const bottomMargin = 12.0;
    final chartHeight = height - topMargin - bottomMargin;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final gridSteps = [0.0, 0.5, 1.0];
    for (final step in gridSteps) {
      final y = topMargin + chartHeight * (1.0 - step);
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
    }

    final List<Offset> coords = [];
    if (points.length == 1) {
      final total = points.first.total;
      final yEnd = maximum > 0
          ? topMargin + chartHeight * (1.0 - (total / maximum))
          : topMargin + chartHeight;
      coords.add(Offset(0, topMargin + chartHeight));
      coords.add(Offset(width, yEnd));
    } else {
      for (var i = 0; i < points.length; i++) {
        final x = (i / (points.length - 1)) * width;
        final ratio = maximum > 0 ? (points[i].total / maximum) : 0.0;
        final y = topMargin + chartHeight * (1.0 - ratio);
        coords.add(Offset(x, y));
      }
    }

    if (coords.length >= 2) {
      final linePath = Path();
      linePath.moveTo(coords.first.dx, coords.first.dy);

      for (var i = 0; i < coords.length - 1; i++) {
        final p0 = i > 0 ? coords[i - 1] : coords[i];
        final p1 = coords[i];
        final p2 = coords[i + 1];
        final p3 = i < coords.length - 2 ? coords[i + 2] : p2;

        final cp1x = p1.dx + (p2.dx - p0.dx) / 5.0;
        final cp1y = p1.dy + (p2.dy - p0.dy) / 5.0;
        final cp2x = p2.dx - (p3.dx - p1.dx) / 5.0;
        final cp2y = p2.dy - (p3.dy - p1.dy) / 5.0;

        linePath.cubicTo(cp1x, cp1y, cp2x, cp2y, p2.dx, p2.dy);
      }

      final fillPath = Path.from(linePath);
      fillPath.lineTo(width, topMargin + chartHeight);
      fillPath.lineTo(0, topMargin + chartHeight);
      fillPath.close();

      final fillPaint = Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, topMargin),
          Offset(0, topMargin + chartHeight),
          [
            primaryColor.withValues(alpha: 0.28),
            primaryColor.withValues(alpha: 0.0),
          ],
        )
        ..style = PaintingStyle.fill;
      canvas.drawPath(fillPath, fillPaint);

      final strokePaint = Paint()
        ..color = primaryColor
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      canvas.drawPath(linePath, strokePaint);
    }

    final activeOffset = points.length == 1
        ? coords.last
        : coords[selectedIndex.clamp(0, coords.length - 1)];

    final guidePaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.35)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    _drawDashedLine(
      canvas,
      Offset(activeOffset.dx, topMargin),
      Offset(activeOffset.dx, topMargin + chartHeight),
      guidePaint,
    );

    final haloPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(activeOffset, 9, haloPaint);

    final dotBorderPaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    final dotFillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(activeOffset, 5, dotFillPaint);
    canvas.drawCircle(activeOffset, 5, dotBorderPaint);
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const dashHeight = 4.0;
    const dashSpace = 3.0;
    var startY = p1.dy;
    while (startY < p2.dy) {
      canvas.drawLine(
        Offset(p1.dx, startY),
        Offset(p1.dx, (startY + dashHeight).clamp(p1.dy, p2.dy)),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(_LineChartPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.maximum != maximum ||
      oldDelegate.selectedIndex != selectedIndex ||
      oldDelegate.primaryColor != primaryColor;
}
