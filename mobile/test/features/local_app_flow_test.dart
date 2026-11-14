import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ryangunshop/app/app.dart';
import 'package:ryangunshop/core/data/app_database.dart';
import 'package:ryangunshop/core/data/drift_product_repository.dart';
import 'package:ryangunshop/core/data/product_record.dart';
import 'package:ryangunshop/core/session/app_session.dart';

void main() {
  testWidgets('aplikasi lokal menampilkan katalog tersimpan dan kasir kosong', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    await DriftProductRepository(database).save(
      const ProductRecord(
        id: 'produk-lokal',
        name: 'Teh lokal',
        salePrice: 5000,
        stock: 3,
        unit: 'botol',
        category: 'Minuman',
        locationLabel: 'Etalase',
      ),
    );
    final session = AppSession(database: database);
    addTearDown(session.dispose);
    await tester.pumpWidget(RyanGunshopApp(session: session));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lewati'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('0 nota'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('0 nota'), findsOneWidget);
    await tester.tap(find.byTooltip('Kasir'));
    await tester.pumpAndSettle();
    expect(find.text('Keranjang lokal'), findsOneWidget);
    expect(find.text('Keranjang Masih Kosong'), findsOneWidget);
    await tester.tap(find.text('Katalog'));
    await tester.pumpAndSettle();
    expect(find.text('Teh lokal'), findsOneWidget);
    expect(find.text('Tersimpan di perangkat'), findsOneWidget);
  });
}
