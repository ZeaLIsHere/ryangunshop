import 'package:flutter/material.dart';

import '../../../core/format/rupiah.dart';
import '../../../core/session/app_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/sample_badge.dart';
import '../../catalog/model/catalog_product.dart';
import '../sample/statistics_sample.dart';

/// Layar statistik penjualan dan stok berbasis Bento Grid.
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  List<CatalogProduct>? _localProducts;
  int? _dataRevision;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final revision = AppSessionScope.maybeOf(context)?.dataRevision;
    if (_localProducts == null || revision != _dataRevision) {
      _dataRevision = revision;
      _loadLocalProducts();
    }
  }

  Future<void> _loadLocalProducts() async {
    final repo = AppSessionScope.maybeOf(context)?.productRepository;
    if (repo == null) return;
    try {
      final records = await repo.listProducts();
      if (!mounted) return;
      setState(() {
        _localProducts = records.map(CatalogProduct.fromRecord).toList();
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = AppSessionScope.maybeOf(context);
    final isLocal = session?.productRepository != null;

    final StatisticsDataSet data;
    if (session != null) {
      final todayTotal = session.todayRevenue;
      final todayCount = session.todayTransactionCount;
      final itemsSold = session.recentTransactions.fold<int>(
        0,
        (sum, tx) => sum + tx.itemCount,
      );
      data = StatisticsDataSet(
        total: todayTotal,
        previousTotal: 0,
        transactions: todayCount,
        itemsSold: itemsSold,
        grossProfit: 0,
        payments: const [],
        peakTitle: 'Waktu transaksi terbanyak',
        peakHours: const [
          HourBucket(label: 'Pagi', transactions: 0),
          HourBucket(label: 'Siang', transactions: 0),
          HourBucket(label: 'Sore', transactions: 0),
          HourBucket(label: 'Malam', transactions: 0),
        ],
        trendTitle: 'Tren penjualan',
        trend: [
          const SalesPoint(label: 'Sen', total: 0),
          const SalesPoint(label: 'Sel', total: 0),
          const SalesPoint(label: 'Rab', total: 0),
          const SalesPoint(label: 'Kam', total: 0),
          const SalesPoint(label: 'Jum', total: 0),
          const SalesPoint(label: 'Sab', total: 0),
          SalesPoint(label: 'Hari ini', total: todayTotal),
        ],
        topProducts: const [],
        slowMoving: const [],
      );
    } else {
      data = const StatisticsDataSet(
        total: 0,
        previousTotal: 0,
        transactions: 0,
        itemsSold: 0,
        grossProfit: 0,
        payments: [],
        peakTitle: 'Waktu transaksi terbanyak',
        peakHours: [
          HourBucket(label: 'Pagi', transactions: 0),
          HourBucket(label: 'Siang', transactions: 0),
          HourBucket(label: 'Sore', transactions: 0),
          HourBucket(label: 'Malam', transactions: 0),
        ],
        trendTitle: 'Tren penjualan',
        trend: [
          SalesPoint(label: 'Sen', total: 0),
          SalesPoint(label: 'Sel', total: 0),
          SalesPoint(label: 'Rab', total: 0),
          SalesPoint(label: 'Kam', total: 0),
          SalesPoint(label: 'Jum', total: 0),
          SalesPoint(label: 'Sab', total: 0),
          SalesPoint(label: 'Hari ini', total: 0),
        ],
        topProducts: [],
        slowMoving: [],
      );
    }

    final products = _localProducts ?? const <CatalogProduct>[];

    final lowStock = products
        .where((p) => p.stockStatus == ProductStockStatus.low)
        .toList();
    final inventoryValue = products.fold<int>(
      0,
      (sum, p) => sum + p.price * p.stock,
    );
    final inventoryItems = products.fold<int>(0, (sum, p) => sum + p.stock);
    final marginProducts = products.where((p) => p.costPrice > 0).toList()
      ..sort((a, b) => b.marginPercent.compareTo(a.marginPercent));

    // Kategori produk
    final categoryCounts = <String, int>{};
    for (final p in products) {
      categoryCounts[p.category] = (categoryCounts[p.category] ?? 0) + 1;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Statistik')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screen),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    margin: const EdgeInsets.only(right: AppSpacing.sm),
                    padding: const EdgeInsets.all(AppSpacing.xxs),
                    decoration: BoxDecoration(
                      color: AppColors.primarySubtle,
                      borderRadius: BorderRadius.circular(AppRadius.squircle),
                    ),
                    child: Image.asset(
                      'assets/icon/05_statistik.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.insights_outlined,
                        size: 24,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ringkasan warung',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.ink,
                          ),
                        ),
                        Text(
                          'Performa inventaris, aset & margin produk',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                        if (!isLocal) ...[
                          const SizedBox(height: 4),
                          const SampleBadge(label: 'Belum ada data'),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // BENTO 1: Hero Nilai Stok & Omzet (Featured Big Card)
              _BentoHeroCard(
                inventoryValue: inventoryValue,
                todayRevenue: data.total,
                transactions: data.transactions,
                itemsSold: data.itemsSold,
              ),
              const SizedBox(height: AppSpacing.sm),

              // BENTO 2: Kesehatan Stok & Efisiensi Margin (2-Up Bento)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _BentoInventoryHealthCard(
                        totalItems: inventoryItems,
                        productCount: products.length,
                        lowStockCount: lowStock.length,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _BentoMarginEfficiencyCard(
                        marginProducts: marginProducts,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // BENTO 3: Distribusi Kategori Toko
              if (categoryCounts.isNotEmpty) ...[
                _BentoCategoryCard(
                  categoryCounts: categoryCounts,
                  totalProducts: products.length,
                ),
                const SizedBox(height: AppSpacing.sm),
              ],

              // BENTO 4: Tren Penjualan & Pembayaran (Row / Bento)
              _BentoSectionContainer(
                title: data.trendTitle,
                subtitle: 'Aktivitas penjualan periode mingguan',
                child: _WeeklyChart(points: data.trend),
              ),
              const SizedBox(height: AppSpacing.sm),

              _BentoSectionContainer(
                title: 'Metode pembayaran',
                subtitle: 'Komposisi cara bayar transaksi',
                child: _PaymentSplit(slices: data.payments),
              ),
              const SizedBox(height: AppSpacing.sm),

              _BentoSectionContainer(
                title: data.peakTitle,
                subtitle: 'Jam sibuk transaksi belanja',
                child: _PeakHours(buckets: data.peakHours),
              ),
              const SizedBox(height: AppSpacing.sm),

              // BENTO 5: Produk Terlaris & Lambat Laku
              _BentoSectionContainer(
                title: 'Produk terlaris',
                subtitle: 'Barang dengan frekuensi pembelian tertinggi',
                child: data.topProducts.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        child: Center(
                          child: Text(
                            'Belum ada data transaksi produk',
                            style: TextStyle(color: AppColors.muted),
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          for (var i = 0; i < data.topProducts.length; i++)
                            _ProductRow(
                              rank: i + 1,
                              product: data.topProducts[i],
                              isLast: i == data.topProducts.length - 1,
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: AppSpacing.sm),

              _BentoSectionContainer(
                title: 'Produk lambat laku',
                subtitle: 'Barang dengan perputaran stok rendah',
                child: data.slowMoving.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        child: Center(
                          child: Text(
                            'Belum ada data produk lambat laku',
                            style: TextStyle(color: AppColors.muted),
                          ),
                        ),
                      )
                    : _SlowMoving(products: data.slowMoving),
              ),
              const SizedBox(height: AppSpacing.sm),

              // BENTO 6: Peringkat Margin Keuntungan Produk
              _BentoSectionContainer(
                title: 'Margin produk',
                subtitle: 'Selisih harga jual terhadap modal barang',
                child: marginProducts.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        child: Center(
                          child: Text(
                            'Belum ada produk dengan harga modal',
                            style: TextStyle(color: AppColors.muted),
                          ),
                        ),
                      )
                    : _MarginList(products: marginProducts.take(5).toList()),
              ),
              const SizedBox(height: AppSpacing.sm),

              // BENTO 7: Rincian Stok & Restok
              _BentoSectionContainer(
                title: 'Stok',
                subtitle: 'Daftar barang yang perlu diperhatikan',
                child: _StockDetails(
                  inventoryItems: inventoryItems,
                  lowStock: lowStock,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

String _percent(double value) =>
    '${value.toStringAsFixed(1).replaceAll('.', ',')}%';

/// Bento Hero: Menampilkan Nilai Aset Inventaris & Ringkasan Penjualan
class _BentoHeroCard extends StatelessWidget {
  const _BentoHeroCard({
    required this.inventoryValue,
    required this.todayRevenue,
    required this.transactions,
    required this.itemsSold,
  });

  final int inventoryValue;
  final int todayRevenue;
  final int transactions;
  final int itemsSold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: AppRadius.panelBorder,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Estimasi nilai stok',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.surface.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.storefront_outlined,
                      size: 14,
                      color: AppColors.surface,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Aset Toko',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.surface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatRupiah(inventoryValue),
              style: AppTypography.total(
                color: AppColors.surface,
                fontSize: 32,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: AppColors.surface.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Omzet hari ini',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.surface.withValues(alpha: 0.75),
                        ),
                      ),
                      Text(
                        formatRupiah(todayRevenue),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppColors.surface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Aktivitas',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.surface.withValues(alpha: 0.75),
                        ),
                      ),
                      Text(
                        '$transactions Nota · $itemsSold Item',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppColors.surface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bento Tile 2A: Kesehatan Inventaris Barang
class _BentoInventoryHealthCard extends StatelessWidget {
  const _BentoInventoryHealthCard({
    required this.totalItems,
    required this.productCount,
    required this.lowStockCount,
  });

  final int totalItems;
  final int productCount;
  final int lowStockCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primarySubtle,
              borderRadius: BorderRadius.circular(AppRadius.squircle),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 20,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '$totalItems',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
              fontFeatures: AppTypography.tabularFigures,
            ),
          ),
          Text(
            'Total item tersimpan',
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.circular(AppRadius.controlCompact),
                ),
                child: Text(
                  '$productCount varian',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.muted,
                  ),
                ),
              ),
              if (lowStockCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(
                      AppRadius.controlCompact,
                    ),
                  ),
                  child: Text(
                    '$lowStockCount menipis',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Bento Tile 2B: Efisiensi & Potensi Margin Laba
class _BentoMarginEfficiencyCard extends StatelessWidget {
  const _BentoMarginEfficiencyCard({required this.marginProducts});

  final List<CatalogProduct> marginProducts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avgMargin = marginProducts.isEmpty
        ? 0.0
        : marginProducts.fold<double>(0.0, (sum, p) => sum + p.marginPercent) /
              marginProducts.length;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.squircle),
            ),
            child: const Icon(
              Icons.trending_up,
              size: 20,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _percent(avgMargin),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.success,
              fontFeatures: AppTypography.tabularFigures,
            ),
          ),
          Text(
            'Rata-rata margin laba',
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.circular(AppRadius.controlCompact),
            ),
            child: Text(
              '${marginProducts.length} produk termodal',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bento Tile 3: Distribusi Kategori Toko
class _BentoCategoryCard extends StatelessWidget {
  const _BentoCategoryCard({
    required this.categoryCounts,
    required this.totalProducts,
  });

  final Map<String, int> categoryCounts;
  final int totalProducts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sorted = categoryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Komposisi kategori produk',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '${categoryCounts.length} kategori',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Multi-segment category bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  for (var i = 0; i < sorted.length; i++)
                    Expanded(
                      flex: sorted[i].value,
                      child: ColoredBox(color: _categoryColor(i)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              for (var i = 0; i < sorted.take(4).length; i++)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _categoryColor(i),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${sorted[i].key} (${sorted[i].value})',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.ink,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _categoryColor(int index) {
    const palette = [
      AppColors.primary,
      AppColors.accent,
      Color(0xFF3B82F6),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFFEC4899),
    ];
    return palette[index % palette.length];
  }
}

/// Kontainer Seragam untuk Sub-Bagian Bento
class _BentoSectionContainer extends StatelessWidget {
  const _BentoSectionContainer({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart({required this.points});

  final List<SalesPoint> points;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxTotal = points.fold<int>(
      1,
      (max, p) => p.total > max ? p.total : max,
    );

    return SizedBox(
      height: 140,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final point in points)
            Expanded(
              child: Semantics(
                label: '${point.label}: ${formatRupiah(point.total)}',
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Spacer(),
                    Container(
                      width: 18,
                      height: (point.total / maxTotal) * 88,
                      decoration: BoxDecoration(
                        color: point.total == maxTotal
                            ? AppColors.primary
                            : AppColors.primaryLight,
                        borderRadius: AppRadius.fixtureBorder,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      point.label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PaymentSplit extends StatelessWidget {
  const _PaymentSplit({required this.slices});

  final List<PaymentSlice> slices;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (slices.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Center(
          child: Text(
            'Belum ada data metode pembayaran',
            style: TextStyle(color: AppColors.muted),
          ),
        ),
      );
    }
    final total = slices.fold<int>(0, (sum, s) => sum + s.total);
    const colors = [AppColors.primary, AppColors.accent];

    return Column(
      children: [
        ClipRRect(
          borderRadius: AppRadius.fixtureBorder,
          child: SizedBox(
            height: 10,
            child: total == 0
                ? Container(color: AppColors.primaryLight)
                : Row(
                    children: [
                      for (var i = 0; i < slices.length; i++)
                        if (slices[i].total > 0)
                          Expanded(
                            flex: slices[i].total,
                            child: ColoredBox(color: colors[i % colors.length]),
                          ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (var i = 0; i < slices.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: colors[i % colors.length],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    slices[i].label,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                Text(
                  '${formatRupiah(slices[i].total)} · '
                  '${(total == 0 ? 0 : (slices[i].total / total * 100).round())}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                    fontFeatures: AppTypography.tabularFigures,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PeakHours extends StatelessWidget {
  const _PeakHours({required this.buckets});

  final List<HourBucket> buckets;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxCount = buckets.fold<int>(
      1,
      (max, b) => b.transactions > max ? b.transactions : max,
    );

    return Column(
      children: [
        for (final bucket in buckets)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Text(
                    bucket.label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                      fontFeatures: AppTypography.tabularFigures,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: ClipRRect(
                    borderRadius: AppRadius.fixtureBorder,
                    child: LinearProgressIndicator(
                      value: bucket.transactions / maxCount,
                      minHeight: 8,
                      backgroundColor: AppColors.primaryLight,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                SizedBox(
                  width: 24,
                  child: Text(
                    '${bucket.transactions}',
                    textAlign: TextAlign.right,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFeatures: AppTypography.tabularFigures,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({
    required this.rank,
    required this.product,
    required this.isLast,
  });

  final int rank;
  final TopProduct product;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.primarySubtle,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$rank',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '${product.sold} ${product.unit}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                  fontFeatures: AppTypography.tabularFigures,
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1),
      ],
    );
  }
}

class _SlowMoving extends StatelessWidget {
  const _SlowMoving({required this.products});

  final List<TopProduct> products;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < products.length; i++) ...[
          Row(
            children: [
              const Icon(
                Icons.trending_down,
                size: 18,
                color: AppColors.warning,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  products[i].name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '${products[i].sold} ${products[i].unit}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                  fontFeatures: AppTypography.tabularFigures,
                ),
              ),
            ],
          ),
          if (i != products.length - 1)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Divider(height: 1),
            ),
        ],
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Kandidat evaluasi harga atau promo.',
          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }
}

class _MarginList extends StatelessWidget {
  const _MarginList({required this.products});

  final List<CatalogProduct> products;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < products.length; i++) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  products[i].name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '${formatRupiah(products[i].margin)} · '
                '${_percent(products[i].marginPercent)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                  fontFeatures: AppTypography.tabularFigures,
                ),
              ),
            ],
          ),
          if (i != products.length - 1)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Divider(height: 1),
            ),
        ],
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Dihitung dari selisih harga jual dan harga modal produk.',
          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }
}

class _StockDetails extends StatelessWidget {
  const _StockDetails({required this.inventoryItems, required this.lowStock});

  final int inventoryItems;
  final List<CatalogProduct> lowStock;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 18,
              color: AppColors.warning,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                'Perlu restok (${lowStock.length})',
                style: theme.textTheme.titleSmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        if (lowStock.isEmpty)
          Text(
            'Semua stok di atas ambang menipis.',
            style: theme.textTheme.bodyMedium,
          )
        else
          for (final product in lowStock)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '${product.stock} ${product.unit}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.bold,
                      fontFeatures: AppTypography.tabularFigures,
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}
