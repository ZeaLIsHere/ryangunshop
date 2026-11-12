import 'package:flutter/material.dart';

import '../../../core/format/rupiah.dart';
import '../../../core/session/app_session.dart';
import '../../../core/session/user_role.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/category_icon.dart';
import '../../../core/widgets/primary_action.dart';
import '../model/catalog_product.dart';
import 'product_form_screen.dart';

/// Bottom sheet untuk melihat detail produk, mengedit, atau memasukkan ke kasir.
class ProductDetailSheet extends StatelessWidget {
  const ProductDetailSheet({
    required this.product,
    this.existingProducts = const [],
    this.isLocal = false,
    this.onProductUpdated,
    this.onProductDeleted,
    super.key,
  });

  final CatalogProduct product;
  final List<CatalogProduct> existingProducts;
  final bool isLocal;
  final ValueChanged<CatalogProduct>? onProductUpdated;
  final ValueChanged<CatalogProduct>? onProductDeleted;

  static Future<void> show(
    BuildContext context, {
    required CatalogProduct product,
    List<CatalogProduct> existingProducts = const [],
    bool isLocal = false,
    ValueChanged<CatalogProduct>? onProductUpdated,
    ValueChanged<CatalogProduct>? onProductDeleted,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductDetailSheet(
        product: product,
        existingProducts: existingProducts,
        isLocal: isLocal,
        onProductUpdated: onProductUpdated,
        onProductDeleted: onProductDeleted,
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
                    Row(
                      children: [
                        CategoryIcon(category: product.category, size: 14),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${product.category} \u00b7 ${product.locationLabel}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (session.role == UserRole.owner && onProductDeleted != null)
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                  ),
                  tooltip: 'Hapus Produk',
                  onPressed: () => _confirmDelete(context),
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
                    final navigator = Navigator.of(context);
                    navigator.pop();
                    final updated = await navigator.push<CatalogProduct>(
                      MaterialPageRoute(
                        builder: (_) => ProductFormScreen(
                          initialProduct: product,
                          existingProducts: existingProducts,
                          isLocal: isLocal,
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

  void _confirmDelete(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Produk?'),
        content: Text('Produk "${product.name}" akan dihapus secara permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && context.mounted) {
        Navigator.of(context).pop();
        onProductDeleted?.call(product);
      }
    });
  }
}
