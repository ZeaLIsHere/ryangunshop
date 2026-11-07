import 'package:flutter/material.dart';

import '../../../core/format/rupiah.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/sample_badge.dart';
import '../../catalog/model/catalog_product.dart';
import '../../catalog/sample/catalog_sample.dart';
import '../sample/statistics_sample.dart';

/// Layar statistik penjualan dan stok dengan data contoh.
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  StatisticsPeriod _period = StatisticsPeriod.today;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = StatisticsSample.forPeriod(_period);
    final products = CatalogSample.products;
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

    return Scaffold(
      appBar: AppBar(title: const Text('Statistik')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screen),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    margin: const EdgeInsets.only(right: AppSpacing.xs),
                    padding: const EdgeInsets.all(AppSpacing.xxs),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: AppRadius.controlCompactBorder,
                    ),
                    child: Image.asset(
                      'assets/icon/05_statistik.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.insights_outlined,
                        size: 20,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Ringkasan warung',
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                  const SampleBadge(),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final period in StatisticsPeriod.values)
                    ChoiceChip(
                      label: Text(period.label),
                      selected: period == _period,
                      onSelected: (_) => setState(() => _period = period),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _SummaryHero(data: data),
              const SizedBox(height: AppSpacing.sm),
              _MetricGrid(data: data, activeProducts: products.length),
              const SizedBox(height: AppSpacing.lg),
              _SectionTitle(text: data.trendTitle),
              const SizedBox(height: AppSpacing.sm),
              _WeeklyChart(points: data.trend),
              const SizedBox(height: AppSpacing.lg),
              _SectionTitle(text: data.peakTitle),
              const SizedBox(height: AppSpacing.sm),
              _PeakHours(buckets: data.peakHours),
              const SizedBox(height: AppSpacing.lg),
              _SectionTitle(text: 'Metode pembayaran'),
              const SizedBox(height: AppSpacing.sm),
              _PaymentSplit(slices: data.payments),
              const SizedBox(height: AppSpacing.lg),
              _SectionTitle(text: 'Produk terlaris'),
              const SizedBox(height: AppSpacing.sm),
              AppCard(
                child: Column(
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
              const SizedBox(height: AppSpacing.lg),
              _SectionTitle(text: 'Produk lambat laku'),
              const SizedBox(height: AppSpacing.sm),
              _SlowMoving(products: data.slowMoving),
              const SizedBox(height: AppSpacing.lg),
              _SectionTitle(text: 'Margin produk'),
              const SizedBox(height: AppSpacing.sm),
              _MarginList(products: marginProducts.take(4).toList()),
              const SizedBox(height: AppSpacing.lg),
              _SectionTitle(text: 'Stok'),
              const SizedBox(height: AppSpacing.sm),
              _StockCard(
                inventoryValue: inventoryValue,
                inventoryItems: inventoryItems,
                lowStock: lowStock,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.headlineSmall);
  }
}

String _percent(double value) =>
    '${value.toStringAsFixed(1).replaceAll('.', ',')}%';

class _SummaryHero extends StatelessWidget {
  const _SummaryHero({required this.data});

  final StatisticsDataSet data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final change = data.changePercent;
    final up = change >= 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: AppRadius.panelBorder,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.24),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Omzet',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.surface.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatRupiah(data.total),
              style: AppTypography.total(
                color: AppColors.surface,
                fontSize: 34,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.16),
              borderRadius: AppRadius.fixtureBorder,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  up ? Icons.trending_up : Icons.trending_down,
                  size: 16,
                  color: AppColors.surface,
                ),
                const SizedBox(width: AppSpacing.xxs),
                Flexible(
                  child: Text(
                    '${up ? 'Naik' : 'Turun'} ${_percent(change.abs())} '
                    'vs periode sebelumnya',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.surface,
                      fontWeight: FontWeight.w600,
                    ),
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

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.data, required this.activeProducts});

  final StatisticsDataSet data;
  final int activeProducts;

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      _MetricTile(
        icon: Icons.receipt_long_outlined,
        label: 'Transaksi',
        value: '${data.transactions}',
      ),
      _MetricTile(
        icon: Icons.inventory_2_outlined,
        label: 'Item terjual',
        value: '${data.itemsSold}',
      ),
      _MetricTile(
        icon: Icons.payments_outlined,
        label: 'Rata-rata',
        value: formatRupiah(data.average),
      ),
      _MetricTile(
        icon: Icons.category_outlined,
        label: 'Produk aktif',
        value: '$activeProducts',
      ),
      _MetricTile(
        icon: Icons.savings_outlined,
        label: 'Laba kotor',
        value: formatRupiah(data.grossProfit),
      ),
      _MetricTile(
        icon: Icons.percent_outlined,
        label: 'Margin',
        value: _percent(data.marginPercent),
      ),
    ];

    return Column(
      children: [
        for (var i = 0; i < tiles.length; i += 2) ...[
          Row(
            children: [
              Expanded(child: tiles[i]),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: i + 1 < tiles.length
                    ? tiles[i + 1]
                    : const SizedBox.shrink(),
              ),
            ],
          ),
          if (i + 2 < tiles.length) const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(height: AppSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontFeatures: AppTypography.tabularFigures,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: theme.textTheme.bodySmall),
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

    return AppCard(
      child: SizedBox(
        height: 168,
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
                        height: (point.total / maxTotal) * 108,
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
    final total = slices.fold<int>(0, (sum, s) => sum + s.total);
    const colors = [AppColors.primary, AppColors.accent];

    return AppCard(
      child: Column(
        children: [
          ClipRRect(
            borderRadius: AppRadius.fixtureBorder,
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  for (var i = 0; i < slices.length; i++)
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
      ),
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

    return AppCard(
      child: Column(
        children: [
          for (final bucket in buckets)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
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
                        minHeight: 10,
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
      ),
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
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$rank',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.primaryDark,
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
    return AppCard(
      child: Column(
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
      ),
    );
  }
}

class _MarginList extends StatelessWidget {
  const _MarginList({required this.products});

  final List<CatalogProduct> products;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
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
            'Estimasi dari harga jual dan modal (data contoh).',
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _StockCard extends StatelessWidget {
  const _StockCard({
    required this.inventoryValue,
    required this.inventoryItems,
    required this.lowStock,
  });

  final int inventoryValue;
  final int inventoryItems;
  final List<CatalogProduct> lowStock;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _kv(
            theme,
            'Estimasi nilai stok',
            formatRupiah(inventoryValue),
            bold: true,
          ),
          const SizedBox(height: AppSpacing.xxs),
          _kv(theme, 'Total item tersimpan', '$inventoryItems'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Divider(height: 1),
          ),
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
      ),
    );
  }

  Widget _kv(ThemeData theme, String label, String value, {bool bold = false}) {
    return Row(
      children: [
        Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              fontFeatures: AppTypography.tabularFigures,
            ),
          ),
        ),
      ],
    );
  }
}
