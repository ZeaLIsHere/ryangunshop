import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ryangunshop/core/format/rupiah.dart';
import 'package:ryangunshop/core/session/app_session.dart';
import 'package:ryangunshop/core/session/user_role.dart';
import 'package:ryangunshop/core/theme/app_theme.dart';
import 'package:ryangunshop/features/catalog/model/catalog_product.dart';
import 'package:ryangunshop/features/catalog/view/catalog_product_card.dart';
import 'package:ryangunshop/features/catalog/view/product_catalog.dart';
import 'package:ryangunshop/features/catalog/view_model/catalog_view_model.dart';

CatalogProduct product(int index) => CatalogProduct(
  id: 'p$index',
  name:
      '${index.toString().padLeft(3, '0')} Beras pandan wangi kemasan keluarga sangat panjang',
  price: 123456789,
  stock: index == 1 ? 0 : 2,
  unit: 'bungkus',
  fixtureId: '',
  locationLabel: 'Rak bahan makanan keluarga',
  category: 'Sembako',
  barcode: '123456789012345678901234567890',
);

void main() {
  for (final entry in {360: 2, 600: 3, 1024: 5}.entries) {
    testWidgets(
      '${entry.key} dp skala 1,3: ${entry.value} kolom dan kartu tanpa potongan',
      (tester) async {
        final session = AppSession()..selectRole(UserRole.cashier);
        addTearDown(session.dispose);
        final vm = CatalogViewModel(
          initialProducts: List.generate(60, product),
        );
        addTearDown(vm.dispose);
        await host(tester, session, vm, entry.key.toDouble());
        expect(find.text('Produk'), findsOneWidget);
        expect(find.text('Katalog Produk'), findsNothing);
        expect(find.byType(FloatingActionButton), findsNothing);
        final cards = find.byType(CatalogProductCard);
        expect(cards.evaluate().length, lessThan(60));
        final first = tester.getTopLeft(cards.at(0));
        for (var i = 1; i < entry.value; i++) {
          expect(tester.getTopLeft(cards.at(i)).dy, first.dy);
          expect(tester.getTopLeft(cards.at(i)).dx, greaterThan(first.dx));
        }

        final card = cards.first;
        for (final text in [
          product(0).name,
          'Barcode: ${product(0).barcode}',
          '${formatRupiah(product(0).price)} / bungkus',
          'Menipis: 2 bungkus',
        ]) {
          final widget = tester.widget<Text>(
            find.descendant(of: card, matching: find.text(text)),
          );
          expect(widget.maxLines, isNull);
          expect(widget.overflow, isNull);
        }
        final add = find.descendant(
          of: card,
          matching: find.byType(FilledButton),
        );
        await tester.ensureVisible(add);
        await tester.pumpAndSettle();
        expect(tester.getSize(add).width, greaterThanOrEqualTo(48));
        expect(tester.getSize(add).height, greaterThanOrEqualTo(48));
        await tester.tap(add);
        await tester.pump();
        await tester.tap(add);
        await tester.pump();
        expect(session.cart.totalItems, 2);
        expect(tester.widget<FilledButton>(add).onPressed, isNull);
        final emptyButton = find.descendant(
          of: cards.at(1),
          matching: find.byType(FilledButton),
        );
        expect(tester.widget<FilledButton>(emptyButton).onPressed, isNull);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('grid menjaga pencarian, detail dan izin pemilik', (
    tester,
  ) async {
    final session = AppSession();
    addTearDown(session.dispose);
    final vm = CatalogViewModel(
      initialProducts: [
        const CatalogProduct(
          id: 'p',
          name: 'Kopi',
          price: 5000,
          stock: 2,
          unit: 'pcs',
          fixtureId: '',
          locationLabel: 'Rak',
          category: 'Minuman',
        ),
      ],
    );
    addTearDown(vm.dispose);
    await host(tester, session, vm, 600);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Kopi');
    await tester.pumpAndSettle();
    expect(find.byType(CatalogProductCard), findsOneWidget);
    final name = find.descendant(
      of: find.byType(CatalogProductCard),
      matching: find.text('Kopi'),
    );
    await tester.ensureVisible(name);
    await tester.tap(name);
    await tester.pumpAndSettle();
    expect(find.text('Edit Produk'), findsOneWidget);
    expect(find.byTooltip('Hapus Produk'), findsOneWidget);
    session.selectRole(UserRole.cashier);
    await tester.pumpAndSettle();
    expect(find.text('Edit Produk'), findsNothing);
    expect(find.byTooltip('Hapus Produk'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<void> host(
  WidgetTester tester,
  AppSession session,
  CatalogViewModel vm,
  double width,
) async {
  tester.view.physicalSize = Size(width, width == 1024 ? 600 : 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    AppSessionScope(
      session: session,
      child: MaterialApp(
        theme: AppTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!,
        ),
        home: Scaffold(
          body: SafeArea(child: ProductCatalog(viewModel: vm)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
