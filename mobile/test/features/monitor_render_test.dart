import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ryangunshop/core/data/product_record.dart';
import 'package:ryangunshop/core/session/app_session.dart';
import 'package:ryangunshop/core/theme/app_theme.dart';
import 'package:ryangunshop/features/monitor/model/monitor_layout.dart';
import 'package:ryangunshop/features/monitor/view/monitor_screen.dart';
import 'package:ryangunshop/features/monitor/view_model/monitor_view_model.dart';

void main() {
  for (final width in [360.0, 1024.0]) {
    testWidgets('render Monitor $width dp skala 1,3', (tester) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final session = AppSession();
      addTearDown(session.dispose);
      final template = MonitorTemplate.wallsAndCenter.create();
      final layout = template.copyWith(
        assignments: {
          'coffee': template.fixtures.first.id,
          'water': template.fixtures
              .lastWhere((f) => f.type == MonitorFixtureType.fridge)
              .id,
        },
      );
      final model = MonitorViewModel(
        loadLayout: () async => (layout: layout, revision: 1),
        saveLayout: (value, revision) async =>
            (layout: value, revision: revision + 1),
        canEdit: () => true,
        loadProducts: () async => const [
          ProductRecord(
            id: 'coffee',
            name: 'Kopi Susu 20 g',
            salePrice: 2000,
            stock: 2,
            unit: 'sachet',
          ),
          ProductRecord(
            id: 'water',
            name: 'Air Mineral 600 ml',
            salePrice: 3500,
            stock: 0,
            unit: 'botol',
          ),
        ],
      );
      addTearDown(model.dispose);
      final capture = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: capture,
          child: AppSessionScope(
            session: session,
            child: MaterialApp(
              theme: AppTheme.light(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(1.3)),
                child: child!,
              ),
              home: MonitorScreen(viewModel: model),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final boundary =
          capture.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        expect(data, isNotNull);
        final directory = await Directory('build/monitor-previews')
            .create(recursive: true);
        await File('${directory.path}/monitor-${width.toInt()}.png')
            .writeAsBytes(data!.buffer.asUint8List());
      });
    });
  }
}
