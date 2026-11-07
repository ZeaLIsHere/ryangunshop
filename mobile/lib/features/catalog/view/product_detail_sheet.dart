import 'package:flutter/material.dart';

import '../../../core/format/rupiah.dart';
import '../../../core/session/app_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/primary_action.dart';
import '../model/catalog_product.dart';
import 'product_form_screen.dart';

/// Bottom sheet untuk melihat detail produk, mengedit, atau memasukkan ke kasir.
class ProductDetailSheet extends StatelessWidget {
  const ProductDetailSheet({
    required this.product,
    this.existingProducts = const [],
    this.onProductUpdated,
    super.key,
  });

  final CatalogProduct product;
  final List<CatalogProduct> existingProducts;
  final ValueChanged<CatalogProduct>? onProductUpdated;

  static Future<void> show(
    BuildContext context, {
    required CatalogProduct product,
    List<CatalogProduct> existingProducts = const [],
    ValueChanged<CatalogProduct>? onProductUpdated,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductDetailSheet(
        product: product,
        existingProducts: existingProducts,
        onProductUpdated: onProductUpdated,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = AppSessionScope.of(context);
    final isLow = product.stockStatus == ProductStockStatus.low;
    final isEmpty = product.stockStatus == ProductStockStatus.empty;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(AppSpacing.screen),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.muted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Product Title & Barcode
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (product.barcode != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.qr_code,
                            size: 14,
                            color: AppColors.muted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            product.barcode!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.muted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Tutup',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),

          // Price & Stock Overview Card
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: AppRadius.controlBorder,
              border: Border.all(color: AppColors.primaryLight),
            ),
            child: Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.sm,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Harga Jual',
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                    Text(
                      formatRupiah(product.price),
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'per ${product.unit}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Status Stok',
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isEmpty
                            ? AppColors.error.withValues(alpha: 0.1)
                            : isLow
                            ? AppColors.warning.withValues(alpha: 0.1)
                            : AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isEmpty
                            ? 'Stok Habis'
                            : isLow
                            ? 'Stok Menipis (${product.stock})'
                            : 'Stok Aman (${product.stock})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isEmpty
                              ? AppColors.error
                              : isLow
                              ? AppColors.warning
                              : AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit Produk'),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    final updated = await Navigator.of(context)
                        .push<CatalogProduct>(
                          MaterialPageRoute(
                            builder: (_) => ProductFormScreen(
                              initialProduct: product,
                              existingProducts: existingProducts,
                            ),
                          ),
                        );
                    if (updated != null) {
                      onProductUpdated?.call(updated);
                    }
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: PrimaryAction(
                  label: '+ Kasir',
                  icon: Icons.add_shopping_cart,
                  onPressed: isEmpty
                      ? null
                      : () {
                          session.cart.addProduct(product);
                          Navigator.of(context).pop();
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
              ),
            ],
          ),
        ],
      ),
    );
  }
}
