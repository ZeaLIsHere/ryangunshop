import 'package:flutter/material.dart';

import '../../../core/format/rupiah.dart';
import '../../../core/session/app_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/category_icon.dart';
import '../model/catalog_product.dart';

class CatalogProductCard extends StatelessWidget {
  const CatalogProductCard({required this.product, this.onTap, super.key});

  final CatalogProduct product;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = AppSessionScope.of(context);
    final (icon, color, label) = switch (product.stockStatus) {
      ProductStockStatus.available => (
        Icons.inventory_2_outlined,
        AppColors.muted,
        'Stok: ${product.stock} ${product.unit}',
      ),
      ProductStockStatus.low => (
        Icons.warning_amber_rounded,
        AppColors.warning,
        'Menipis: ${product.stock} ${product.unit}',
      ),
      ProductStockStatus.empty => (
        Icons.remove_circle_outline,
        AppColors.error,
        'Habis: 0 ${product.unit}',
      ),
    };

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: AppSpacing.minTouchTarget,
              height: AppSpacing.minTouchTarget,
              decoration: BoxDecoration(
                color: AppColors.primarySubtle,
                borderRadius: AppRadius.controlBorder,
              ),
              child: Center(
                child: CategoryIcon(
                  category: product.category,
                  size: AppSpacing.lg,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            product.name,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            '${product.category} · ${product.locationLabel}',
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
          if (product.barcode?.isNotEmpty ?? false) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'Barcode: ${product.barcode}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.muted,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${formatRupiah(product.price)} / ${product.unit}',
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: AppSpacing.md),
              const SizedBox(width: AppSpacing.xxs),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ListenableBuilder(
            listenable: session.cart,
            builder: (context, _) {
              final inCart = session.cart.items
                  .where((item) => item.productId == product.id)
                  .fold(0, (sum, item) => sum + item.quantity);
              return Tooltip(
                message: 'Tambah ke Kasir',
                child: FilledButton.tonalIcon(
                  icon: const Icon(
                    Icons.add_shopping_cart,
                    size: AppSpacing.lg,
                  ),
                  label: const Text('Kasir'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(
                      AppSpacing.minTouchTarget,
                      AppSpacing.minTouchTarget,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xxs,
                    ),
                  ),
                  onPressed: inCart >= product.stock
                      ? null
                      : () {
                          session.cart.addProduct(product);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${product.name} dimasukkan ke kasir',
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
