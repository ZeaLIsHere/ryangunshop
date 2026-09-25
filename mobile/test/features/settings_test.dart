import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ryangunshop/core/session/app_session.dart';
import 'package:ryangunshop/core/session/user_role.dart';
import 'package:ryangunshop/core/theme/app_theme.dart';
import 'package:ryangunshop/features/settings/sample/settings_sample.dart';
import 'package:ryangunshop/features/settings/view/settings_screen.dart';

void main() {
  testWidgets('memilih peran kasir mengunci mode edit denah', (tester) async {
    _usePhoneViewport(tester);
    final session = AppSession();
    addTearDown(session.dispose);

    await tester.pumpWidget(_host(const SettingsScreen(), session));
    await tester.pumpAndSettle();

    expect(find.text(SettingsSample.floorPlanAccessAllowed), findsOneWidget);
    expect(find.text(SettingsSample.floorPlanAccessLocked), findsNothing);

    final cashierOption = find.text(UserRole.cashier.label);
    await tester.ensureVisible(cashierOption);
    await tester.pumpAndSettle();
    await tester.tap(cashierOption);
    await tester.pumpAndSettle();

    expect(session.role, UserRole.cashier);
    expect(find.text(SettingsSample.floorPlanAccessLocked), findsOneWidget);
    expect(find.text(SettingsSample.floorPlanAccessAllowed), findsNothing);
  });

  testWidgets('info warung ditandai sebagai data contoh', (tester) async {
    _usePhoneViewport(tester);
    final session = AppSession();
    addTearDown(session.dispose);

    await tester.pumpWidget(_host(const SettingsScreen(), session));
    await tester.pumpAndSettle();

    final badge = find.text(SettingsSample.sampleBadge);
    await tester.ensureVisible(badge);
    await tester.pumpAndSettle();

    expect(badge, findsOneWidget);
    expect(find.text(SettingsSample.storeProfile.name), findsOneWidget);
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
