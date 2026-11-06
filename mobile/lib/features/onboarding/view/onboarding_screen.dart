import 'package:flutter/material.dart';

import '../../../app/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/primary_action.dart';
import '../model/onboarding_page.dart';
import '../sample/onboarding_sample.dart';
import '../view_model/onboarding_view_model.dart';

/// Perkenalan tiga halaman untuk penggunaan pertama.
///
/// Dapat dilewati, menampilkan indikator progres, dan menghormati pengaturan
/// pengurangan animasi pada perangkat.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final OnboardingViewModel _viewModel = OnboardingViewModel();
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  bool get _reduceMotion => MediaQuery.disableAnimationsOf(context);

  void _goToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: _reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  void _finish() {
    Navigator.of(context).pushReplacement(
      AppRouter.crossfadeRoute(AppRoutes.shell, reduceMotion: _reduceMotion),
    );
  }

  void _onAdvance() {
    if (_viewModel.isLastPage) {
      _finish();
      return;
    }
    _goToPage(_viewModel.currentIndex + 1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            return Column(
              children: [
                // Bar atas: identitas di kiri, lewati di kanan.
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screen,
                    AppSpacing.sm,
                    AppSpacing.xs,
                    0,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.storefront_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'RyanGunshop',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _finish,
                        child: const Text('Lewati'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _viewModel.pageCount,
                    onPageChanged: _viewModel.onPageChanged,
                    itemBuilder: (context, index) => _OnboardingPageView(
                      page: OnboardingSample.pages[index],
                    ),
                  ),
                ),
                _OnboardingProgress(
                  currentIndex: _viewModel.currentIndex,
                  pageCount: _viewModel.pageCount,
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.screen),
                  child: PrimaryAction(
                    label: _viewModel.isLastPage ? 'Mulai' : 'Lanjut',
                    icon: _viewModel.isLastPage
                        ? Icons.check
                        : Icons.arrow_forward,
                    onPressed: _onAdvance,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Ilustrasi geometris, judul, dan keterangan satu halaman.
class _OnboardingPageView extends StatelessWidget {
  const _OnboardingPageView({required this.page});

  final OnboardingPage page;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 236,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primaryLight, AppColors.surface],
              ),
              borderRadius: AppRadius.panelBorder,
              border: Border.all(color: AppColors.primaryLight),
            ),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryDark.withValues(alpha: 0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(page.icon, size: 56, color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

/// Indikator progres perkenalan.
///
/// Maknanya tidak bergantung pada warna saja karena disertai label semantik.
class _OnboardingProgress extends StatelessWidget {
  const _OnboardingProgress({
    required this.currentIndex,
    required this.pageCount,
  });

  final int currentIndex;
  final int pageCount;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Halaman ${currentIndex + 1} dari $pageCount',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var index = 0; index < pageCount; index++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: index == currentIndex ? 28 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
              decoration: BoxDecoration(
                color: index == currentIndex
                    ? AppColors.primary
                    : AppColors.primaryLight,
                borderRadius: AppRadius.fixtureBorder,
              ),
            ),
        ],
      ),
    );
  }
}
