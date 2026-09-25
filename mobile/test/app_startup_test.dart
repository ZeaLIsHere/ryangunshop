import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ryangunshop/app/app.dart';
import 'package:ryangunshop/app/startup/app_startup_state.dart';
import 'package:ryangunshop/features/onboarding/sample/onboarding_sample.dart';

void main() {
  setUp(AppStartupState.resetForTesting);

  testWidgets('splash berlanjut ke perkenalan saat pertama dibuka', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(const RyanGunshopApp());

    expect(find.text('RyanGunshop'), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text(OnboardingSample.pages.first.title), findsOneWidget);
    expect(find.text('Lewati'), findsOneWidget);
  });

  testWidgets('perkenalan dapat dilewati menuju kerangka utama', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(const RyanGunshopApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lewati'));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('splash melewati perkenalan bila sudah pernah dilihat', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    AppStartupState.markOnboardingSeen();

    await tester.pumpWidget(const RyanGunshopApp());
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Lewati'), findsNothing);
  });
}

void _usePhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}
