import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ryangunshop/core/session/app_session.dart';
import 'package:ryangunshop/core/theme/app_theme.dart';
import 'package:ryangunshop/features/panorama/model/panorama_zone.dart';
import 'package:ryangunshop/features/panorama/view/panorama_viewer_screen.dart';

void main() {
  testWidgets(
    'PanoramaViewerScreen merender kanvas 360 dan chip pemilih zona',
    (tester) async {
      _usePhoneViewport(tester);
      final session = AppSession();
      addTearDown(session.dispose);

      await tester.pumpWidget(
        AppSessionScope(
          session: session,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const PanoramaViewerScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(PanoramaSample.zones.first.name), findsWidgets);
      expect(
        find.byType(ChoiceChip),
        findsNWidgets(PanoramaSample.zones.length),
      );

      // Berpindah zona
      final secondZone = PanoramaSample.zones[1];
      final secondChip = find.text(secondZone.name);
      await tester.ensureVisible(secondChip);
      await tester.pumpAndSettle();
      await tester.tap(secondChip);
      await tester.pumpAndSettle();

      expect(find.text(secondZone.name), findsWidgets);
    },
  );
}

void _usePhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}
