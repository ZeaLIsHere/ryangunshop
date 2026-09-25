import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Menampilkan bottom sheet dengan judul, isi, dan tombol tutup yang seragam.
///
/// Bentuk sheet mengikuti tema, dan isinya dapat digulir bila lebih tinggi dari layar.
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required String title,
  required Widget child,
  bool isScrollControlled = true,
  bool showCloseButton = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    builder: (_) => AppBottomSheet(
      title: title,
      showCloseButton: showCloseButton,
      child: child,
    ),
  );
}

/// Isi bottom sheet yang dipakai oleh [showAppBottomSheet].
class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({
    required this.title,
    required this.child,
    this.showCloseButton = true,
    super.key,
  });

  final String title;
  final Widget child;
  final bool showCloseButton;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.screen,
          right: AppSpacing.screen,
          bottom: AppSpacing.screen + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title, style: theme.textTheme.headlineSmall),
                ),
                if (showCloseButton)
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    tooltip: 'Tutup',
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Flexible(child: SingleChildScrollView(child: child)),
          ],
        ),
      ),
    );
  }
}
