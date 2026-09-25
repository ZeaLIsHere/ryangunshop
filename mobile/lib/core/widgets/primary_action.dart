import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'brand_spinner.dart';

/// Satu aksi utama per konteks, misalnya "Mulai pindai".
///
/// Selalu memenuhi target sentuh minimal dan menonaktifkan diri selama proses berjalan
/// supaya aksi tidak terkirim dua kali.
class PrimaryAction extends StatelessWidget {
  const PrimaryAction({
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = true,
    this.semanticHint,
    super.key,
  });

  /// Label tindakan yang dibaca pengguna dan pembaca layar.
  final String label;

  final VoidCallback? onPressed;

  /// Ikon di kiri label. Bersifat pendamping, bukan pengganti label.
  final IconData? icon;

  /// Menampilkan spinner dan menonaktifkan tombol selama proses berjalan.
  final bool isLoading;

  /// Memenuhi lebar induknya. Matikan untuk tombol ringkas di dalam dialog.
  final bool expand;

  /// Petunjuk tambahan untuk pembaca layar, misalnya alasan tombol nonaktif.
  final String? semanticHint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canPress = onPressed != null && !isLoading;

    final text = Text(
      label,
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis,
    );

    final button = FilledButton(
      onPressed: canPress ? onPressed : null,
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLoading) ...[
            BrandSpinner(size: 18, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.xs),
          ] else if (icon != null) ...[
            Icon(icon, size: 20),
            const SizedBox(width: AppSpacing.xs),
          ],
          if (expand) Flexible(child: text) else text,
        ],
      ),
    );

    final content = expand
        ? SizedBox(width: double.infinity, child: button)
        : button;

    final hint = semanticHint;
    if (hint == null) {
      return content;
    }
    return Semantics(hint: hint, child: content);
  }
}
