import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Permukaan kartu ringkas untuk daftar dan ringkasan.
///
/// Memakai bentuk dan warna dari tema, jadi tidak perlu mengatur radius atau elevasi
/// lagi di dalam fitur.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.onTap,
    this.padding,
    this.semanticLabel,
    super.key,
  });

  final Widget child;

  /// Bila diisi, seluruh permukaan kartu dapat ditekan.
  final VoidCallback? onTap;

  /// Padding isi kartu; bawaan 16 dp sesuai jarak layar ponsel.
  final EdgeInsetsGeometry? padding;

  /// Label semantik kartu, misalnya "Rak minuman, 12 produk".
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    Widget content = Padding(
      padding: padding ?? const EdgeInsets.all(AppSpacing.md),
      child: child,
    );

    final tap = onTap;
    if (tap != null) {
      content = InkWell(onTap: tap, child: content);
    }

    final card = Card(child: content);
    final label = semanticLabel;
    if (label == null) {
      return card;
    }
    return Semantics(label: label, button: tap != null, child: card);
  }
}
