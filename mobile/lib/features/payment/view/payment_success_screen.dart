import 'package:flutter/material.dart';

import '../../../core/format/rupiah.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/primary_action.dart';
import '../../../core/widgets/sample_badge.dart';
import '../../checkout/model/cart_item.dart';
import '../model/payment_preview.dart';

/// Ringkasan hasil simulasi, tanpa klaim transaksi atau stok nyata.
class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({
    required this.totalAmount,
    required this.method,
    required this.items,
    this.cashReceived,
    this.changeAmount,
    this.onNewTransaction,
    super.key,
  });

  final int totalAmount;
  final PaymentMethod method;
  final List<CartItem> items;
  final int? cashReceived;
  final int? changeAmount;
  final VoidCallback? onNewTransaction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCash = method == PaymentMethod.cash;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Ringkasan Simulasi')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screen),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.md),
              Center(
                child: Icon(
                  isCash ? Icons.check_circle_outline : Icons.info_outline,
                  size: AppSpacing.minTouchTarget,
                  color: isCash ? AppColors.success : AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                isCash ? 'Simulasi Tunai Selesai' : 'Status QRIS Contoh',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Pratinjau ini tidak mencatat transaksi, mengubah stok, atau mengirim pembayaran.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.panelBorder,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: SampleBadge(label: 'Ringkasan contoh'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text('Daftar Barang', style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xs),
                    for (final item in items) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xxs,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${item.productName} (${item.quantity} × ${formatRupiah(item.unitPrice)})',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              formatRupiah(item.subtotal),
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    const Divider(),
                    _SummaryRow(
                      label: 'Total',
                      value: formatRupiah(totalAmount),
                      prominent: true,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _SummaryRow(
                      label: 'Metode',
                      value: isCash ? 'Tunai (contoh)' : 'QRIS (contoh)',
                    ),
                    if (isCash && cashReceived != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      _SummaryRow(
                        label: 'Uang diterima',
                        value: formatRupiah(cashReceived!),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      _SummaryRow(
                        label: 'Kembalian',
                        value: formatRupiah(changeAmount ?? 0),
                        prominent: true,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryAction(
                label: 'Transaksi Baru',
                icon: Icons.add_shopping_cart,
                onPressed: () {
                  onNewTransaction?.call();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.prominent = false,
  });

  final String label;
  final String value;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: prominent
                ? theme.textTheme.titleSmall
                : theme.textTheme.bodyMedium,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          value,
          style: prominent
              ? theme.textTheme.titleSmall?.copyWith(color: AppColors.primary)
              : theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}
