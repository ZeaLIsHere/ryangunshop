import 'package:flutter/material.dart';

import '../../../core/format/rupiah.dart';
import '../../../core/data/app_database.dart';
import '../../../core/data/transaction_repository.dart';
import '../../../core/session/app_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/brand_spinner.dart';
import '../../../core/widgets/primary_action.dart';
import '../../../core/widgets/sample_badge.dart';
import '../model/cart_item.dart';
import '../model/cart_scenario.dart';
import '../view_model/cart_view_model.dart';
import '../../payment/view/payment_sheet.dart';

/// Layar kasir dan keranjang transaksi RyanGunshop.
class CartCheckoutScreen extends StatelessWidget {
  const CartCheckoutScreen({
    this.onOpenScanner,
    this.onOpenCatalog,
    this.transactionRepository,
    super.key,
  });

  final VoidCallback? onOpenScanner;
  final VoidCallback? onOpenCatalog;
  final TransactionRepository? transactionRepository;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = AppSessionScope.of(context);
    final cart = session.cart;
    final localTransactions =
        transactionRepository ?? session.transactionRepository;

    if (!session.isLocalCartReady) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                session.isLocalCartLoadFailed
                    ? Icons.error_outline
                    : Icons.hourglass_empty,
                color: session.isLocalCartLoadFailed
                    ? AppColors.error
                    : AppColors.primary,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                session.isLocalCartLoadFailed
                    ? 'Keranjang lokal gagal dimuat'
                    : 'Memuat keranjang lokal',
                style: theme.textTheme.titleMedium,
              ),
              if (session.isLocalCartLoadFailed)
                TextButton.icon(
                  onPressed: session.loadLocalCart,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba lagi'),
                ),
            ],
          ),
        ),
      );
    }

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
                  vertical: AppSpacing.xs,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                    bottom: BorderSide(color: AppColors.primaryLight),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          margin: const EdgeInsets.only(right: AppSpacing.xs),
                          padding: const EdgeInsets.all(AppSpacing.xxs),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: AppRadius.controlCompactBorder,
                          ),
                          child: Image.asset(
                            'assets/icon/02_keranjang.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.point_of_sale_outlined,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
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
                          icon: const Icon(Icons.qr_code_scanner),
                          label: const Text('Scan'),
                          onPressed: onOpenScanner,
                        ),
                        if (!cart.isEmpty) ...[
                          const SizedBox(width: AppSpacing.xs),
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
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        SampleBadge(
                          label: localTransactions == null
                              ? 'Keranjang contoh'
                              : 'Keranjang lokal',
                        ),
                        const Spacer(),
                        PopupMenuButton<CartScenario>(
                          tooltip: 'Pilih Skenario Keranjang',
                          icon: const Icon(Icons.more_horiz),
                          onSelected: cart.selectScenario,
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: CartScenario.ready,
                              child: Text('Tampilkan keranjang'),
                            ),
                            PopupMenuItem(
                              value: CartScenario.loading,
                              child: Text('Memuat'),
                            ),
                            PopupMenuItem(
                              value: CartScenario.failure,
                              child: Text('Gagal'),
                            ),
                            PopupMenuItem(
                              value: CartScenario.offline,
                              child: Text('Offline'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (session.isLocalCartSaveFailed)
                      Text(
                        'Perubahan keranjang belum tersimpan di perangkat.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                  ],
                ),
              ),

              Expanded(child: _buildCartBody(context, cart)),

              // Bottom Order Summary Bar
              if (!cart.isEmpty &&
                  cart.scenario != CartScenario.loading &&
                  cart.scenario != CartScenario.failure)
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
                              fontFeatures: AppTypography.tabularFigures,
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
                                fontFeatures: AppTypography.tabularFigures,
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
                              fontFeatures: AppTypography.tabularFigures,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      PrimaryAction(
                        label: 'Lanjut ke Pembayaran',
                        icon: Icons.print,
                        onPressed: cart.total <= 0
                            ? null
                            : () {
                                PaymentSheet.show(
                                  context,
                                  totalAmount: cart.total,
                                  cartItems: cart.items,
                                  onPaymentCompleted: () {
                                    cart.clearCart();
                                    if (session.database != null) {
                                      session.loadLocalSummary();
                                    }
                                  },
                                  onCashConfirmed: localTransactions == null
                                      ? null
                                      : (received, change) async {
                                          await session.flushCartDraft();
                                          final id =
                                              'TRX-${DateTime.now().microsecondsSinceEpoch}';
                                          await localTransactions.checkout(
                                            transactionId: id,
                                            paymentMethod: 'cash',
                                            totalAmount: cart.total,
                                            discountAmount: cart.discount,
                                            cashReceived: received,
                                            changeAmount: change,
                                            lines: [
                                              for (final item in cart.items)
                                                CheckoutLine(
                                                  productId: item.productId,
                                                  quantity: item.quantity,
                                                  unitPrice: item.unitPrice,
                                                  subtotal: item.subtotal,
                                                ),
                                            ],
                                          );
                                          return id;
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

  Widget _buildCartBody(BuildContext context, CartViewModel cart) {
    switch (cart.scenario) {
      case CartScenario.loading:
        return _buildScenarioMessage(
          context,
          icon: Icons.hourglass_top_outlined,
          color: AppColors.primary,
          title: 'Memuat keranjang contoh',
          description: 'Data contoh sedang disiapkan untuk pratinjau.',
          onRetry: cart.resetScenario,
          showSpinner: true,
        );
      case CartScenario.failure:
        return _buildScenarioMessage(
          context,
          icon: Icons.error_outline,
          color: AppColors.error,
          title: 'Keranjang gagal dimuat',
          description: 'Ini skenario contoh. Coba tampilkan keranjang lagi.',
          onRetry: cart.resetScenario,
        );
      case CartScenario.offline:
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.screen),
              child: Row(
                children: [
                  const Icon(
                    Icons.cloud_off_outlined,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Mode offline contoh · keranjang tetap dapat digunakan.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: cart.isEmpty
                  ? _buildEmptyView(context)
                  : _buildItems(context, cart),
            ),
          ],
        );
      case CartScenario.ready:
        return cart.isEmpty
            ? _buildEmptyView(context)
            : _buildItems(context, cart);
    }
  }

  Widget _buildItems(BuildContext context, CartViewModel cart) {
    final theme = Theme.of(context);
    final totalPay = cart.total;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screen),
      children: [
        // Hero Order Card (Violet Gradient referensi kasir_pembayaran)
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primaryDark,
                Color(0xFF4C1D95),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'KASIR MEJA 01 • SHIFT SIANG',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Pesanan',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        formatRupiah(totalPay),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                          fontFeatures: AppTypography.tabularFigures,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // 3 Quick Cashier Action Pods
        Row(
          children: [
            Expanded(
              child: _CashierQuickPod(
                icon: Icons.fastfood_outlined,
                label: 'Tambah Menu',
                bgColor: const Color(0xFFFFF7ED),
                iconColor: const Color(0xFFEA580C),
                onTap: onOpenCatalog ?? () {},
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _CashierQuickPod(
                icon: Icons.receipt_long,
                label: 'Keranjang (${cart.totalItems})',
                bgColor: const Color(0xFFF5F3FF),
                iconColor: const Color(0xFF7C3AED),
                isActive: true,
                onTap: () {},
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _CashierQuickPod(
                icon: Icons.local_offer_outlined,
                label: cart.discount > 0
                    ? 'Diskon ${formatRupiah(cart.discount)}'
                    : 'Voucher/Diskon',
                bgColor: const Color(0xFFECFDF5),
                iconColor: const Color(0xFF059669),
                onTap: () => _openDiscountDialog(context, cart),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        // Section Header Rincian Barang Belanja
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Rincian Barang Belanja',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.canvas,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.primaryLight),
              ),
              child: const Text(
                'DAFTAR PESANAN',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: AppColors.muted,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        for (final item in cart.items) ...[
          _CartItemTile(
            item: item,
            onQuantityChanged: (quantity) {
              cart.updateQuantity(item.productId, quantity);
            },
            onRemove: () => cart.removeItem(item.productId),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
      ],
    );
  }

  Widget _buildScenarioMessage(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String description,
    required VoidCallback onRetry,
    bool showSpinner = false,
  }) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screen),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: AppSpacing.minTouchTarget),
            const SizedBox(height: AppSpacing.xs),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              description,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            if (showSpinner && !MediaQuery.disableAnimationsOf(context)) ...[
              const SizedBox(height: AppSpacing.md),
              const BrandSpinner(label: 'Memuat keranjang contoh'),
            ],
            const SizedBox(height: AppSpacing.lg),
            PrimaryAction(
              label: 'Tampilkan Keranjang Contoh',
              icon: Icons.refresh,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
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
            Image.asset(
              'assets/icon/02_keranjang.png',
              width: 64,
              height: 64,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(
                Icons.shopping_cart_outlined,
                size: 56,
                color: AppColors.muted,
              ),
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

  void _openDiscountDialog(BuildContext context, CartViewModel cart) {
    final controller = TextEditingController(
      text: cart.discount > 0 ? cart.discount.toString() : '',
    );
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Atur Diskon Transaksi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Nominal Diskon (Rp)',
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 6,
              children: [
                ActionChip(
                  label: const Text('Rp 2.000'),
                  onPressed: () => controller.text = '2000',
                ),
                ActionChip(
                  label: const Text('Rp 5.000'),
                  onPressed: () => controller.text = '5000',
                ),
                ActionChip(
                  label: const Text('Rp 10.000'),
                  onPressed: () => controller.text = '10000',
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              cart.setDiscount(0);
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Hapus Diskon'),
          ),
          FilledButton(
            onPressed: () {
              final val = int.tryParse(controller.text) ?? 0;
              cart.setDiscount(val);
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Terapkan'),
          ),
        ],
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
            width: AppSpacing.minTouchTarget,
            height: AppSpacing.minTouchTarget,
            decoration: BoxDecoration(
              color: AppColors.primarySubtle,
              borderRadius: AppRadius.fixtureBorder,
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F9FF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _rackTagFor(item.productId),
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  item.productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${formatRupiah(item.unitPrice)} / ${item.unit}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  formatRupiah(item.subtotal),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontFeatures: AppTypography.tabularFigures,
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
                  icon: const Icon(Icons.remove),
                  tooltip: item.quantity == 1
                      ? 'Hapus Produk'
                      : 'Kurangi Kuantitas',
                  onPressed: () => onQuantityChanged(item.quantity - 1),
                ),
                Text(
                  '${item.quantity}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
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

  String _rackTagFor(String productId) {
    if (productId.contains('1')) return 'SKU-01';
    if (productId.contains('2')) return 'SKU-02';
    if (productId.contains('3')) return 'SKU-03';
    if (productId.contains('4')) return 'SKU-04';
    return 'PRODUK';
  }
}

class _CashierQuickPod extends StatelessWidget {
  const _CashierQuickPod({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.iconColor,
    required this.onTap,
    this.isActive = false,
  });

  final IconData icon;
  final String label;
  final Color bgColor;
  final Color iconColor;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : AppColors.primaryLight,
              width: isActive ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10.5,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                  color: isActive ? AppColors.primary : AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
