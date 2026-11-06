import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/format/rupiah.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/primary_action.dart';
import '../../checkout/model/cart_item.dart';
import '../model/payment_preview.dart';
import 'payment_success_screen.dart';

/// Bottom sheet pemilihan dan proses pembayaran kasir (Tunai & QRIS).
class PaymentSheet extends StatefulWidget {
  const PaymentSheet({
    required this.totalAmount,
    required this.cartItems,
    this.onPaymentCompleted,
    super.key,
  });

  final int totalAmount;
  final List<CartItem> cartItems;
  final VoidCallback? onPaymentCompleted;

  /// Gambar QRIS contoh untuk pratinjau pembayaran; belum terhubung gateway.
  static const String qrisSampleAsset = 'assets/branding/QRIS.jpeg';

  static Future<void> show(
    BuildContext context, {
    required int totalAmount,
    required List<CartItem> cartItems,
    VoidCallback? onPaymentCompleted,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: PaymentSheet(
          totalAmount: totalAmount,
          cartItems: cartItems,
          onPaymentCompleted: onPaymentCompleted,
        ),
      ),
    );
  }

  @override
  State<PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<PaymentSheet> {
  PaymentMethod _selectedMethod = PaymentMethod.cash;
  final TextEditingController _cashController = TextEditingController();
  int _cashReceived = 0;

  // QRIS states
  QrisStatus _qrisStatus = QrisStatus.awaitingPayment;
  int _qrisCountdownSeconds = 300; // 5 menit
  Timer? _qrisTimer;

  @override
  void initState() {
    super.initState();
    _cashReceived = widget.totalAmount;
    _cashController.text = widget.totalAmount.toString();
    _startQrisTimer();
  }

  void _startQrisTimer() {
    _qrisTimer?.cancel();
    _qrisTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_qrisCountdownSeconds > 0) {
        if (mounted) {
          setState(() => _qrisCountdownSeconds--);
        }
      } else {
        timer.cancel();
        if (mounted) {
          setState(() => _qrisStatus = QrisStatus.expired);
        }
      }
    });
  }

  @override
  void dispose() {
    _qrisTimer?.cancel();
    _cashController.dispose();
    super.dispose();
  }

  int get _changeAmount => _cashReceived - widget.totalAmount;
  bool get _isCashValid => _cashReceived >= widget.totalAmount;

  void _completePayment(PaymentMethod method) {
    widget.onPaymentCompleted?.call();
    Navigator.of(context).pop(); // Tutup sheet
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PaymentSuccessScreen(
          totalAmount: widget.totalAmount,
          method: method,
          items: widget.cartItems,
          cashReceived: method == PaymentMethod.cash ? _cashReceived : null,
          changeAmount: method == PaymentMethod.cash ? _changeAmount : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.sheetBorder,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(
                top: AppSpacing.sm,
                bottom: AppSpacing.xs,
              ),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.muted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Total Tagihan Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
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
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          formatRupiah(widget.totalAmount),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
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
          ),
          const SizedBox(height: AppSpacing.sm),

          // Method Selector Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: SegmentedButton<PaymentMethod>(
              segments: const [
                ButtonSegment(
                  value: PaymentMethod.cash,
                  label: Text('Tunai (Cash)'),
                  icon: Icon(Icons.money),
                ),
                ButtonSegment(
                  value: PaymentMethod.qris,
                  label: Text('QRIS Dinamis'),
                  icon: Icon(Icons.qr_code_2),
                ),
              ],
              selected: {_selectedMethod},
              onSelectionChanged: (set) {
                setState(() => _selectedMethod = set.first);
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),

          // Tab Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.screen),
              child: _selectedMethod == PaymentMethod.cash
                  ? _buildCashView(theme)
                  : _buildQrisView(theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashView(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Uang Diterima',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: _cashController,
          keyboardType: TextInputType.number,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            prefixText: 'Rp ',
            prefixStyle: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
            border: OutlineInputBorder(borderRadius: AppRadius.controlBorder),
          ),
          onChanged: (val) {
            final parsed = int.tryParse(val.replaceAll(RegExp(r'\D'), '')) ?? 0;
            setState(() => _cashReceived = parsed);
          },
        ),
        const SizedBox(height: AppSpacing.sm),

        // Quick amount chip buttons
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ActionChip(
              label: const Text('Uang Pas'),
              onPressed: () {
                setState(() {
                  _cashReceived = widget.totalAmount;
                  _cashController.text = widget.totalAmount.toString();
                });
              },
            ),
            for (final amount in [20000, 50000, 100000, 200000])
              if (amount >= widget.totalAmount || amount == 20000)
                ActionChip(
                  label: Text(formatRupiah(amount)),
                  onPressed: () {
                    setState(() {
                      _cashReceived = amount;
                      _cashController.text = amount.toString();
                    });
                  },
                ),
          ],
        ),

        const SizedBox(height: AppSpacing.lg),

        // Kembalian Display Card
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: _isCashValid
                ? AppColors.success.withValues(alpha: 0.1)
                : AppColors.error.withValues(alpha: 0.1),
            borderRadius: AppRadius.controlBorder,
            border: Border.all(
              color: _isCashValid
                  ? AppColors.success.withValues(alpha: 0.3)
                  : AppColors.error.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _isCashValid ? 'Kembalian' : 'Uang Kurang',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _isCashValid ? AppColors.success : AppColors.error,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    formatRupiah(_isCashValid ? _changeAmount : -_changeAmount),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _isCashValid ? AppColors.success : AppColors.error,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        PrimaryAction(
          label: 'Selesaikan Pembayaran Tunai',
          icon: Icons.check,
          onPressed: _isCashValid
              ? () => _completePayment(PaymentMethod.cash)
              : null,
        ),
      ],
    );
  }

  Widget _buildQrisView(ThemeData theme) {
    final minutes = (_qrisCountdownSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_qrisCountdownSeconds % 60).toString().padLeft(2, '0');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Column(
            children: [
              Text(
                'Scan QRIS untuk Membayar',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'RyanGunshop • Merchant ID: RG-009182',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _qrisStatus == QrisStatus.expired
                      ? AppColors.error.withValues(alpha: 0.1)
                      : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _qrisStatus == QrisStatus.expired
                      ? 'Status: QRIS Kadaluarsa'
                      : 'Status: Menunggu Pembayaran',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _qrisStatus == QrisStatus.expired
                        ? AppColors.error
                        : AppColors.primaryDark,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Gambar QRIS (contoh) untuk pratinjau pembayaran.
              Container(
                width: 220,
                height: 220,
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.panelBorder,
                  border: Border.all(color: AppColors.primaryLight, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryDark.withValues(alpha: 0.08),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: AppRadius.controlBorder,
                  child: Image.asset(
                    PaymentSheet.qrisSampleAsset,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium,
                    errorBuilder: (context, error, stackTrace) => CustomPaint(
                      painter: _QrisCodePainter(amount: widget.totalAmount),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: AppColors.muted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Berlaku: $minutes:$seconds',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                'QR contoh untuk pratinjau',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        PrimaryAction(
          label: 'Verifikasi Pembayaran QRIS',
          icon: Icons.check_circle_outline,
          onPressed: () => _completePayment(PaymentMethod.qris),
        ),
      ],
    );
  }
}

/// Custom painter untuk menggambar pola matriks QRIS dinamis.
class _QrisCodePainter extends CustomPainter {
  const _QrisCodePainter({required this.amount});

  final int amount;

  @override
  void paint(Canvas canvas, Size size) {
    final darkPaint = Paint()..color = const Color(0xFF191A2E);

    const int gridSize = 19;
    final cellSize = size.width / gridSize;

    // Helper draw position finder square
    void drawFinder(double startX, double startY) {
      final outerRect = Rect.fromLTWH(
        startX,
        startY,
        cellSize * 5,
        cellSize * 5,
      );
      canvas.drawRect(outerRect, darkPaint);

      final innerWhite = Rect.fromLTWH(
        startX + cellSize,
        startY + cellSize,
        cellSize * 3,
        cellSize * 3,
      );
      canvas.drawRect(innerWhite, Paint()..color = Colors.white);

      final centerDark = Rect.fromLTWH(
        startX + cellSize * 1.5,
        startY + cellSize * 1.5,
        cellSize * 2,
        cellSize * 2,
      );
      canvas.drawRect(centerDark, darkPaint);
    }

    // Three QR corners
    drawFinder(0, 0);
    drawFinder((gridSize - 5) * cellSize, 0);
    drawFinder(0, (gridSize - 5) * cellSize);

    // Simulated data dots
    final randomSeed = amount.hashCode;
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        // Skip corner finder zones
        if ((r < 5 && c < 5) ||
            (r < 5 && c >= gridSize - 5) ||
            (r >= gridSize - 5 && c < 5)) {
          continue;
        }

        if (((r * 7 + c * 13 + randomSeed) % 3) == 0) {
          final rect = Rect.fromLTWH(
            c * cellSize + 0.5,
            r * cellSize + 0.5,
            cellSize - 1,
            cellSize - 1,
          );
          canvas.drawRect(rect, darkPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrisCodePainter oldDelegate) =>
      oldDelegate.amount != amount;
}
