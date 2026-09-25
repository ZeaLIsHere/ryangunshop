import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';
import '../core/theme/app_theme.dart';

/// Akar aplikasi RyanGunshop.
///
/// Tahap ini baru menyiapkan tema. Shell, splash, dan onboarding dibangun pada
/// fase berikutnya, sehingga layar di bawah hanya penanda sementara.
class RyanGunshopApp extends StatelessWidget {
  const RyanGunshopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RyanGunshop',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const _PlaceholderScreen(),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screen),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('RyanGunshop', style: theme.textTheme.displaySmall),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Kerangka UI siap. Shell, splash, dan onboarding menyusul '
                  'pada fase berikutnya.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
