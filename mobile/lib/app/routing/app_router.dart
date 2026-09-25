import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/primary_action.dart';
import '../shell/app_shell.dart';

/// Nama rute yang dikenal aplikasi.
///
/// Rute fitur ditambahkan di sini seiring fiturnya selesai agar setiap layar punya
/// satu titik masuk yang jelas. Denah, katalog, kasir, dan pengaturan tidak perlu
/// rute terpisah karena diakses lewat navigasi bawah di dalam [AppShell].
abstract final class AppRoutes {
  /// Kerangka utama berisi navigasi bawah.
  static const String shell = '/';
}

/// Pembuat rute aplikasi.
abstract final class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.shell:
        return MaterialPageRoute<dynamic>(
          builder: (_) => const AppShell(),
          settings: settings,
        );
      default:
        return MaterialPageRoute<dynamic>(
          builder: (_) => _UnknownRouteView(routeName: settings.name),
          settings: settings,
        );
    }
  }
}

/// Tampilan untuk rute yang belum terdaftar.
///
/// Sengaja menyediakan tindakan lanjutan, bukan hanya pesan kosong.
class _UnknownRouteView extends StatelessWidget {
  const _UnknownRouteView({required this.routeName});

  final String? routeName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Layar tidak ditemukan')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screen),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.help_outline,
                  size: 48,
                  color: AppColors.muted,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Rute ${routeName ?? '-'} belum terdaftar pada aplikasi.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                PrimaryAction(
                  label: 'Kembali ke denah',
                  icon: Icons.arrow_back,
                  expand: false,
                  onPressed: () => _backToShell(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _backToShell(BuildContext context) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.pushReplacementNamed(AppRoutes.shell);
    }
  }
}
