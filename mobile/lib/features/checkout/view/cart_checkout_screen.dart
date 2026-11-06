import 'package:flutter/material.dart';

import '../../../core/format/rupiah.dart';
import '../../../core/session/app_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/primary_action.dart';
import '../model/cart_item.dart';
import '../../payment/view/payment_sheet.dart';

/// Layar kasir dan keranjang transaksi RyanGunshop.
class CartCheckoutScreen extends StatelessWidget {
  const CartCheckoutScreen({this.onOpenScanner, this.onOpenCatalog, super.key});

  final VoidCallback? onOpenScanner;
  final VoidCallback? onOpenCatalog;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = AppSessionScope.of(context);
    final cart = session.cart;

    return ListenableBuilder(
      listenable: cart,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.canvas,
          body: Column(
            children: [
              // Top Quick Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screen,
                  vertical: AppSpacing.sm,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                    bottom: BorderSide(color: AppColors.primaryLight),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Transaksi Kasir',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${cart.totalItems} barang dalam keranjang',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.qr_code_scanner, size: 18),
                      label: const Text('Scan'),
                      onPressed: onOpenScanner,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    if (!cart.isEmpty)
                      IconButton(
                        icon: const Icon(
                          Icons.delete_sweep_outlined,
                          color: AppColors.error,
                        ),
                        tooltip: 'Kosongkan Keranjang',
                        onPressed: () {
                          _confirmClearCart(context, cart.clearCart);
                        },
                      ),
                  ],
                ),
              ),

              // Cart Items List or Empty View
              Expanded(
                child: cart.isEmpty
                    ? _buildEmptyView(context)
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.screen),
                        itemCount: cart.items.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: AppSpacing.xs),
                        itemBuilder: (context, index) {
                          final item = cart.items[index];
                          return _CartItemTile(
                            item: item,
                            onQuantityChanged: (qty) {
                              cart.updateQuantity(item.productId, qty);
                            },
                            onRemove: () {
                              cart.removeItem(item.productId);
                            },
                          );
                        },
                      ),
              ),

              // Bottom Order Summary Bar
              if (!cart.isEmpty)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.screen),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.panel),
                    ),
                    border: const Border(
                      top: BorderSide(color: AppColors.primaryLight),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryDark.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Subtotal (${cart.totalItems} item)',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                          Text(
                            formatRupiah(cart.subtotal),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (cart.discount > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Diskon',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.success,
                                ),
                              ),
                            ),
                            Text(
                              '- ${formatRupiah(cart.discount)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xs),
                      const Divider(height: 1),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Total Pembayaran',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            formatRupiah(cart.total),
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      PrimaryAction(
                        label: 'Lanjut ke Pembayaran',
                        icon: Icons.payment,
                        onPressed: () {
                          PaymentSheet.show(
                            context,
                            totalAmount: cart.total,
                            cartItems: cart.items,
                            onPaymentCompleted: () {
                              cart.clearCart();
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyView(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screen),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.shopping_cart_outlined,
              size: 56,
              color: AppColors.muted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Keranjang Masih Kosong',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Mulai transaksi dengan memindai barcode atau memilih barang dari katalog.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              alignment: WrapAlignment.center,
              children: [
                FilledButton.icon(
                  icon: const Icon(Icons.qr_code_scanner, size: 18),
                  label: const Text('Pindai Barcode'),
                  onPressed: onOpenScanner,
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.inventory_2_outlined, size: 18),
                  label: const Text('Pilih dari Katalog'),
                  onPressed: onOpenCatalog,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClearCart(BuildContext context, VoidCallback onClear) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kosongkan Keranjang?'),
        content: const Text(
          'Seluruh barang yang telah dimasukkan ke kasir akan dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              onClear();
              Navigator.of(context).pop();
            },
            child: const Text('Kosongkan'),
          ),
        ],
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  final CartItem item;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: AppRadius.fixtureBorder,
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              color: AppColors.primaryDark,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${formatRupiah(item.unitPrice)} / ${item.unit}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatRupiah(item.subtotal),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          // Stepper: [-] [qty] [+]
          Container(
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: AppRadius.controlBorder,
              border: Border.all(color: AppColors.primaryLight),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 16),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Kurangi Kuantitas',
                  onPressed: () => onQuantityChanged(item.quantity - 1),
                ),
                Text(
                  '${item.quantity}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 16),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Tambah Kuantitas',
                  onPressed: () => onQuantityChanged(item.quantity + 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
