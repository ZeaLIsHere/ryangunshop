import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ryangunshop/core/session/app_session.dart';
import 'package:ryangunshop/core/theme/app_theme.dart';
import 'package:ryangunshop/features/settings/sample/settings_sample.dart';
import 'package:ryangunshop/features/settings/view/settings_screen.dart';

void main() {
  testWidgets('peran pemilik dan kasir menentukan hak akses tanpa pemilih peran demo', (tester) async {
    _usePhoneViewport(tester);
    final session = AppSession();
    addTearDown(session.dispose);

    // 1. Uji peran Pemilik
    await session.registerOwner(
      name: 'Pemilik Toko',
      email: 'pemilik@toko.com',
      password: 'password123',
      storeName: 'Toko Ryan',
    );

    await tester.pumpWidget(_host(const SettingsScreen(), session));
    await tester.pumpAndSettle();

    expect(find.text(SettingsSample.floorPlanAccessAllowed), findsOneWidget);
    expect(find.text(SettingsSample.floorPlanAccessLocked), findsNothing);
    expect(find.text(SettingsSample.rolesSectionTitle), findsNothing);
    expect(find.text('Kelola Kasir & Undangan'), findsOneWidget);

    // 2. Uji peran Kasir
    await session.registerCashier(
      name: 'Kasir Satu',
      email: 'kasir@toko.com',
      password: 'password123',
    );

    await tester.pumpWidget(_host(const SettingsScreen(), session));
    await tester.pumpAndSettle();

    expect(session.isCashier, isTrue);
    expect(find.text(SettingsSample.floorPlanAccessLocked), findsOneWidget);
    expect(find.text(SettingsSample.floorPlanAccessAllowed), findsNothing);
    expect(find.text('Kelola Kasir & Undangan'), findsNothing);
    expect(find.text(SettingsSample.rolesSectionTitle), findsNothing);
  });

  testWidgets('profil warung kosong tidak memakai data contoh', (tester) async {
    _usePhoneViewport(tester);
    final session = AppSession();
    addTearDown(session.dispose);

    await tester.pumpWidget(_host(const SettingsScreen(), session));
    await tester.pumpAndSettle();

    expect(find.text('Profil warung belum diatur'), findsOneWidget);
    expect(find.text(SettingsSample.storeProfile.name), findsNothing);
    expect(find.text(SettingsSample.sampleBadge), findsNothing);
    expect(find.text('Belum ada printer terhubung'), findsOneWidget);
    expect(
      find.textContaining('Sinkronisasi cloud belum tersedia'),
      findsOneWidget,
    );
  });
}

Widget _host(Widget child, AppSession session) {
  return AppSessionScope(
    session: session,
    child: MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: child),
    ),
  );
}

void _usePhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}
