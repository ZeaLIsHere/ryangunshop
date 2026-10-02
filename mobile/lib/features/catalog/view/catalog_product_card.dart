import 'package:flutter/material.dart';

import '../../../core/format/rupiah.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/sample_badge.dart';
import '../model/catalog_product.dart';

class CatalogProductCard extends StatelessWidget {
  const CatalogProductCard({required this.product, super.key});

  final CatalogProduct product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, color, label) = switch (product.stockStatus) {
      ProductStockStatus.available => (
        Icons.inventory_2_outlined,
        AppColors.muted,
        'Stok contoh: ${product.stock} ${product.unit}',
      ),
      ProductStockStatus.low => (
        Icons.warning_amber_rounded,
        AppColors.warning,
        'Menipis (contoh): ${product.stock} ${product.unit}',
      ),
      ProductStockStatus.empty => (
        Icons.remove_circle_outline,
        AppColors.error,
        'Habis (contoh): 0 ${product.unit}',
      ),
    };

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(product.name, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xxs),
          Text(product.locationLabel, style: theme.textTheme.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xxs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '${formatRupiah(product.price)} / ${product.unit}',
                style: theme.textTheme.labelLarge,
              ),
              const SampleBadge(),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: AppSpacing.lg),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(color: color),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
