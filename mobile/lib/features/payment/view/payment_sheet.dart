import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/format/rupiah.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/primary_action.dart';
import '../../../core/widgets/sample_badge.dart';
import '../../checkout/model/cart_item.dart';
import '../model/payment_preview.dart';
import '../sample/payment_sample.dart';
import '../view_model/payment_view_model.dart';
import 'payment_success_screen.dart';

typedef ConfirmCashPayment = Future<String> Function(int received, int change);

/// Pembayaran tunai lokal bila callback tersedia; QRIS tetap pratinjau.
class PaymentSheet extends StatefulWidget {
  const PaymentSheet({
    required this.totalAmount,
    required this.cartItems,
    this.onPaymentCompleted,
    this.onCashConfirmed,
    super.key,
  });

  final int totalAmount;
  final List<CartItem> cartItems;

  /// Dipanggil hanya setelah kasir menyelesaikan simulasi tunai secara eksplisit.
  final VoidCallback? onPaymentCompleted;
  final ConfirmCashPayment? onCashConfirmed;

  static Future<void> show(
    BuildContext context, {
    required int totalAmount,
    required List<CartItem> cartItems,
    VoidCallback? onPaymentCompleted,
    ConfirmCashPayment? onCashConfirmed,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetBorder),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: PaymentSheet(
          totalAmount: totalAmount,
          cartItems: cartItems,
          onPaymentCompleted: onPaymentCompleted,
          onCashConfirmed: onCashConfirmed,
        ),
      ),
    );
  }

  @override
  State<PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<PaymentSheet> {
  late final PaymentViewModel _viewModel;
  final TextEditingController _cashController = TextEditingController();
  bool _isSaving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _viewModel = PaymentViewModel(totalAmount: widget.totalAmount);
  }

  @override
  void dispose() {
    _cashController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _chooseCashAmount(int amount) {
    _cashController.text = amount.toString();
    _viewModel.chooseCashAmount(amount);
  }

  Future<void> _completeCashPreview() async {
    if (!_viewModel.canCompleteCash || _isSaving) return;
    final navigator = Navigator.of(context);
    final items = List<CartItem>.of(widget.cartItems);
    final cashReceived = _viewModel.cashReceived!;
    final change = _viewModel.change!;

    String? transactionId;
    if (widget.onCashConfirmed != null) {
      setState(() {
        _isSaving = true;
        _saveError = null;
      });
      try {
        transactionId = await widget.onCashConfirmed!(cashReceived, change);
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _isSaving = false;
          _saveError = 'Transaksi gagal disimpan. Periksa stok dan harga produk, lalu coba lagi.';
        });
        return;
      }
      if (!mounted) return;
    }

    widget.onPaymentCompleted?.call();
    navigator.pop();
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => PaymentSuccessScreen(
          totalAmount: widget.totalAmount,
          method: PaymentMethod.cash,
          items: items,
          cashReceived: cashReceived,
          changeAmount: change,
          transactionId: transactionId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.sheetBorder,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screen,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Pembayaran',
                          style: theme.textTheme.bodySmall,
                        ),
                        Text(
                          formatRupiah(widget.totalAmount),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontFeatures: AppTypography.tabularFigures,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Tutup Pembayaran',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screen,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SampleBadge(
                  label: widget.onCashConfirmed == null
                      ? 'Simulasi pembayaran'
                      : 'Tunai lokal • QRIS simulasi',
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screen,
              ),
              child: SegmentedButton<PaymentMethod>(
                segments: const [
                  ButtonSegment(
                    value: PaymentMethod.cash,
                    label: Text('Tunai'),
                    icon: Icon(Icons.payments_outlined),
                  ),
                  ButtonSegment(
                    value: PaymentMethod.qris,
                    label: Text('QRIS'),
                    icon: Icon(Icons.qr_code_2),
                  ),
                ],
                selected: {_viewModel.method},
                onSelectionChanged: (selection) {
                  _viewModel.selectMethod(selection.first);
                },
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.screen),
                child: _viewModel.method == PaymentMethod.cash
                    ? _buildCashView(context)
                    : _buildQrisView(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCashView(BuildContext context) {
    final theme = Theme.of(context);
    final received = _viewModel.cashReceived;
    final valid = _viewModel.canCompleteCash;
    final insufficient = received != null && !valid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Uang Diterima', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: _cashController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Nominal uang diterima',
            prefixText: 'Rp ',
            hintText: 'Masukkan nominal',
          ),
          onChanged: _viewModel.setCashInput,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'NOMINAL CEPAT UANG PAS',
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppColors.muted,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            ActionChip(
              backgroundColor: const Color(0xFFECFDF5),
              side: const BorderSide(color: Color(0xFF10B981)),
              label: const Text(
                'Uang Pas',
                style: TextStyle(
                  color: Color(0xFF059669),
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () => _chooseCashAmount(widget.totalAmount),
            ),
            for (final amount in PaymentSample.quickCashAmounts)
              if (amount >= widget.totalAmount)
                ActionChip(
                  label: Text(formatRupiah(amount)),
                  onPressed: () => _chooseCashAmount(amount),
                ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: valid
                ? const Color(0xFFECFDF5)
                : insufficient
                ? AppColors.error.withValues(alpha: 0.1)
                : AppColors.canvas,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: valid ? const Color(0xFF6CF8BB) : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: valid
                      ? AppColors.success
                      : insufficient
                      ? AppColors.error
                      : AppColors.muted,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  valid
                      ? Icons.change_circle
                      : insufficient
                      ? Icons.warning_amber_rounded
                      : Icons.info_outline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (valid)
                      const Text(
                        'KEMBALIAN PELANGGAN',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF059669),
                          letterSpacing: 0.5,
                        ),
                      ),
                    Text(
                      valid
                          ? 'Kembalian: ${formatRupiah(_viewModel.change!)}'
                          : insufficient
                          ? 'Uang kurang: ${formatRupiah(widget.totalAmount - received)}'
                          : 'Masukkan uang diterima untuk menghitung kembalian.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: valid ? FontWeight.bold : FontWeight.normal,
                        color: valid ? const Color(0xFF059669) : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        PrimaryAction(
          label: _isSaving
              ? 'Menyimpan transaksi...'
              : widget.onCashConfirmed == null
              ? 'Selesaikan Simulasi Tunai'
              : 'Simpan Transaksi Tunai',
          icon: Icons.check,
          onPressed: valid && !_isSaving ? _completeCashPreview : null,
        ),
        if (_saveError != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            _saveError!,
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.error),
          ),
        ],
        const SizedBox(height: AppSpacing.xs),
        Text(
          widget.onCashConfirmed == null
              ? 'Simulasi ini tidak mencatat transaksi atau mengurangi stok.'
              : 'Nota dan stok disimpan di perangkat setelah pembayaran tunai dikonfirmasi.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }

  Widget _buildQrisView(BuildContext context) {
    final theme = Theme.of(context);
    final status = _viewModel.qrisStatus;
    final (icon, color, title, description) = switch (status) {
      QrisStatus.creating => (
        Icons.hourglass_top_outlined,
        AppColors.primary,
        'Membuat QRIS contoh',
        'Tahap ini hanya pratinjau; tidak ada permintaan ke penyedia pembayaran.',
      ),
      QrisStatus.awaitingPayment => (
        Icons.schedule_outlined,
        AppColors.warning,
        'Menunggu pembayaran contoh',
        'Tidak ada QR yang dapat dibayar atau status yang diverifikasi.',
      ),
      QrisStatus.paid => (
        Icons.info_outline,
        AppColors.success,
        'Status dibayar (simulasi)',
        'Status ini hanya contoh. Keranjang tidak diubah dan transaksi tidak diselesaikan.',
      ),
      QrisStatus.expired => (
        Icons.timer_off_outlined,
        AppColors.error,
        'QRIS contoh kedaluwarsa',
        'Ulangi pratinjau atau pilih tunai untuk mencoba alur pembayaran.',
      ),
      QrisStatus.failed => (
        Icons.error_outline,
        AppColors.error,
        'QRIS contoh gagal',
        'Tidak ada pembayaran yang diproses. Coba ulang pratinjau.',
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: AppSpacing.xs),
            Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
            PopupMenuButton<QrisStatus>(
              tooltip: 'Pilih Status QRIS Contoh',
              icon: const Icon(Icons.tune),
              onSelected: _viewModel.selectQrisStatus,
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: QrisStatus.creating,
                  child: Text('Membuat'),
                ),
                PopupMenuItem(
                  value: QrisStatus.awaitingPayment,
                  child: Text('Menunggu'),
                ),
                PopupMenuItem(value: QrisStatus.paid, child: Text('Dibayar')),
                PopupMenuItem(
                  value: QrisStatus.expired,
                  child: Text('Kedaluwarsa'),
                ),
                PopupMenuItem(value: QrisStatus.failed, child: Text('Gagal')),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(description, style: theme.textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: const BoxDecoration(
            color: AppColors.canvas,
            borderRadius: AppRadius.panelBorder,
          ),
          child: Column(
            children: [
              const Icon(
                Icons.qr_code_2,
                size: AppSpacing.minTouchTarget,
                color: AppColors.muted,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'QRIS contoh tidak dapat dipindai',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (status == QrisStatus.creating)
          PrimaryAction(
            label: 'Tampilkan Status Menunggu',
            icon: Icons.arrow_forward,
            onPressed: () =>
                _viewModel.selectQrisStatus(QrisStatus.awaitingPayment),
          )
        else if (status == QrisStatus.expired || status == QrisStatus.failed)
          PrimaryAction(
            label: 'Ulangi Simulasi QRIS',
            icon: Icons.refresh,
            onPressed: () => _viewModel.selectQrisStatus(QrisStatus.creating),
          ),
      ],
    );
  }
}
