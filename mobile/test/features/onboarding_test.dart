import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ryangunshop/core/theme/app_theme.dart';
import 'package:ryangunshop/features/onboarding/sample/onboarding_sample.dart';
import 'package:ryangunshop/features/onboarding/view/onboarding_screen.dart';
import 'package:ryangunshop/features/onboarding/view_model/onboarding_view_model.dart';

void main() {
  test('view model memindahkan halaman dan mengenali halaman terakhir', () {
    final viewModel = OnboardingViewModel();

    expect(viewModel.currentIndex, 0);
    expect(viewModel.pageCount, OnboardingSample.pages.length);
    expect(viewModel.isLastPage, isFalse);

    viewModel.onPageChanged(OnboardingSample.pages.length - 1);

    expect(viewModel.currentIndex, OnboardingSample.pages.length - 1);
    expect(viewModel.isLastPage, isTrue);

    viewModel.dispose();
  });

  testWidgets('tombol Lanjut berpindah halaman lalu berubah jadi Mulai', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const OnboardingScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text(OnboardingSample.pages.first.title), findsOneWidget);

    for (var index = 1; index < OnboardingSample.pages.length; index++) {
      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();
    }

    expect(find.text(OnboardingSample.pages.last.title), findsOneWidget);
    expect(find.text('Mulai'), findsOneWidget);
  });
}
