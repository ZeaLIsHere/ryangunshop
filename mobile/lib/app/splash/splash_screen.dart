import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/ryan_app_logo.dart';
import '../routing/app_router.dart';
import '../startup/app_startup_state.dart';

/// Layar pembuka dengan satu signature motion sekitar 1,45 detik.
///
/// Logo melakukan scale dan fade, lalu copy serta status muncul berurutan, dan
/// layar berikutnya masuk lewat crossfade 280 ms. Bila pengguna menonaktifkan
/// animasi, seluruh transisi menjadi instan.
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
    begin: 0.9,
    end: 1,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  late final Animation<double> _logoOpacity = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.5, curve: Curves.easeOut),
  );

  late final Animation<double> _copyOpacity = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.45, 1, curve: Curves.easeOut),
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
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screen),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _logoScale,
                child: FadeTransition(
                  opacity: _logoOpacity,
                  child: const RyanAppLogo(size: 96, showWordmark: false),
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
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Menyiapkan aplikasi',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.primaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
