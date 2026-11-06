import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/ryan_app_logo.dart';
import '../routing/app_router.dart';
import '../startup/app_startup_state.dart';

/// Layar pembuka dengan satu signature motion sekitar 1,45 detik.
///
/// Logo melakukan scale dan fade di atas kanvas slate blue bergradasi, lalu copy
/// serta status muncul berurutan, dan layar berikutnya masuk lewat crossfade
/// 280 ms. Bila pengguna menonaktifkan animasi, seluruh transisi menjadi instan.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  /// Durasi signature motion pembuka.
  static const Duration motionDuration = Duration(milliseconds: 1450);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: SplashScreen.motionDuration,
  );

  late final Animation<double> _logoScale = Tween<double>(
    begin: 0.92,
    end: 1,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  late final Animation<double> _logoOpacity = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.45, curve: Curves.easeOut),
  );

  late final Animation<double> _copyOpacity = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.4, 1, curve: Curves.easeOut),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runSignatureMotion());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _runSignatureMotion() async {
    if (!mounted) {
      return;
    }

    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      _controller.value = 1;
    } else {
      await _controller.forward();
    }

    if (!mounted) {
      return;
    }
    _openNextScreen(reduceMotion);
  }

  void _openNextScreen(bool reduceMotion) {
    final navigator = Navigator.of(context);
    final hasSeenOnboarding = AppStartupState.hasSeenOnboarding;
    if (!hasSeenOnboarding) {
      AppStartupState.markOnboardingSeen();
    }

    navigator.pushReplacement(
      AppRouter.crossfadeRoute(
        hasSeenOnboarding ? AppRoutes.shell : AppRoutes.onboarding,
        reduceMotion: reduceMotion,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryDark, AppColors.ink],
            stops: [0, 0.55, 1],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Cahaya lembut di belakang logo.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.15),
                      radius: 0.9,
                      colors: [
                        AppColors.accent.withValues(alpha: 0.30),
                        AppColors.accent.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FadeTransition(
                      opacity: _logoOpacity,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: AppRadius.panelBorder,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.ink.withValues(alpha: 0.35),
                                blurRadius: 40,
                                offset: const Offset(0, 18),
                              ),
                            ],
                          ),
                          child: const RyanAppLogo(
                            size: 88,
                            showWordmark: false,
                            assetPath: RyanAppLogo.defaultAssetPath,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FadeTransition(
                      opacity: _copyOpacity,
                      child: Column(
                        children: [
                          Text(
                            'RyanGunshop',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.displaySmall?.copyWith(
                              color: AppColors.surface,
                              letterSpacing: -0.8,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Menyiapkan aplikasi…',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.surface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Garis progres tipis di bawah layar.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.screen),
                  child: ClipRRect(
                    borderRadius: AppRadius.fixtureBorder,
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) => LinearProgressIndicator(
                        value: reduceMotion ? 1 : _controller.value,
                        minHeight: 3,
                        backgroundColor: AppColors.surface.withValues(
                          alpha: 0.15,
                        ),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.accent,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
