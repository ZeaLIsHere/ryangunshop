import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ryangunshop/app/app.dart';
import 'package:ryangunshop/app/shell/app_shell.dart';
import 'package:ryangunshop/app/startup/app_startup_state.dart';
import 'package:ryangunshop/core/session/app_session.dart';
import 'package:ryangunshop/features/auth/view/login_screen.dart';
import 'package:ryangunshop/features/onboarding/sample/onboarding_sample.dart';

void main() {
  setUp(AppStartupState.resetForTesting);

  testWidgets('navigator dibuat ulang setelah penyimpanan lokal siap', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    final session = _StartupSession();
    addTearDown(session.dispose);

    await tester.pumpWidget(RyanGunshopApp(session: session));
    await tester.pump();
    expect(find.text('Menyiapkan data kasir lokal'), findsOneWidget);
    final loadingNavigator = tester.state(find.byType(Navigator));

    session.finishLoading();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(tester.state(find.byType(Navigator)), isNot(same(loadingNavigator)));
    expect(find.text(OnboardingSample.pages.first.title), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

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

  testWidgets(
    'perkenalan dapat dilewati menuju halaman login bila belum masuk akun',
    (tester) async {
      _usePhoneViewport(tester);
      await tester.pumpWidget(const RyanGunshopApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lewati'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    },
  );

  testWidgets('splash melewati perkenalan menuju login bila belum masuk akun', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    AppStartupState.markOnboardingSeen();

    await tester.pumpWidget(const RyanGunshopApp());
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Lewati'), findsNothing);
  });

  testWidgets(
    'splash langsung menuju kerangka utama jika pengguna sudah login',
    (tester) async {
      _usePhoneViewport(tester);
      AppStartupState.markOnboardingSeen();

      final session = AppSession();
      addTearDown(session.dispose);
      await session.registerOwner(
        name: 'Pemilik Toko',
        email: 'pemilik@toko.com',
        password: 'password123',
        storeName: 'Toko Ryan',
      );

      await tester.pumpWidget(RyanGunshopApp(session: session));
      await tester.pumpAndSettle();

      expect(find.byType(AppShell), findsOneWidget);
      expect(find.text('Lewati'), findsNothing);
    },
  );
}

class _StartupSession extends AppSession {
  bool _ready = false;

  @override
  bool get isLocalCartReady => _ready;

  void finishLoading() {
    _ready = true;
    notifyListeners();
  }
}

void _usePhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}
