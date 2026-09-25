import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Spinner slate blue dengan label status yang jujur.
///
/// Spinner hanya menandakan proses berjalan, bukan keberhasilan. Bila perlu, sertakan
/// label yang menyebut keadaan sebenarnya.
class BrandSpinner extends StatelessWidget {
  const BrandSpinner({
    this.label,
    this.size = 24,
    this.color,
    this.labelStyle,
    super.key,
  });

  /// Label status, misalnya "Memuat data contoh".
  final String? label;

  /// Diameter spinner dalam dp.
  final double size;

  /// Warna spinner; bawaan memakai aksen tema.
  final Color? color;

  /// Gaya teks label; bawaan memakai teks pendukung tema.
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final indicator = Semantics(
      label: 'Memuat',
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: color ?? AppColors.accent,
        ),
      ),
    );

    final text = label;
    if (text == null) {
      return indicator;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        indicator,
        const SizedBox(height: AppSpacing.xs),
        Text(
          text,
          textAlign: TextAlign.center,
          style:
              labelStyle ??
              theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
