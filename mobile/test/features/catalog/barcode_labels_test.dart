import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:ryangunshop/core/data/app_database.dart';
import 'package:ryangunshop/core/data/drift_product_repository.dart';
import 'package:ryangunshop/core/data/in_memory_product_repository.dart';
import 'package:ryangunshop/core/data/product_record.dart';
import 'package:ryangunshop/core/session/app_session.dart';
import 'package:ryangunshop/core/session/user_role.dart';
import 'package:ryangunshop/features/catalog/model/barcode_labels.dart';
import 'package:ryangunshop/features/catalog/view/barcode_labels_screen.dart';
import 'package:share_plus/share_plus.dart';

ProductRecord product(String id, {String? barcode}) => ProductRecord(
  id: id,
  name: 'Produk $id',
  barcode: barcode,
  salePrice: 12500,
  costPrice: 9000,
  stock: 17,
  category: 'Minuman',
  unit: 'botol',
  fixtureId: 'rak-2',
  locationLabel: 'Rak belakang',
  lowStockThreshold: 3,
);

class PausedRepository extends InMemoryProductRepository {
  PausedRepository(super.seed);
  Completer<void>? pause;
  int writes = 0;
  @override
  Future<List<ProductRecord>> listProducts() async {
    await pause?.future;
    return super.listProducts();
  }

  @override
  Future<void> save(ProductRecord product) async {
    writes++;
    await super.save(product);
  }
}

class FailingRepository extends InMemoryProductRepository {
  FailingRepository(super.seed);
  @override
  Future<void> save(ProductRecord product) async {
    if (product.id == 'b') throw StateError('Disk penuh');
    await super.save(product);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Internal RG stable, collision checked, not EAN; existing code unchanged',
    () async {
      final code = internalBarcode('a', []);
      expect(code, startsWith('RG'));
      expect(internalBarcode('a', []), code);
      expect(internalBarcode('a', [code]), '$code-1');
      final repository = InMemoryProductRepository([
        product('existing', barcode: '0012345678905'),
        product('a'),
        product('b'),
        product('collision', barcode: code),
      ]);
      final original = await persistInternalBarcode(
        repository,
        'existing',
        canManage: () => true,
      );
      expect(original.barcode, '0012345678905');
      final saved = await persistInternalBarcode(
        repository,
        'a',
        canManage: () => true,
      );
      expect(saved.barcode, '$code-1');
      expect((await repository.findByBarcode(saved.barcode!))!.id, 'a');
      expect(saved.salePrice, 12500);
      expect(saved.costPrice, 9000);
      expect(saved.stock, 17);
      expect(saved.category, 'Minuman');
      expect(saved.unit, 'botol');
      expect(saved.fixtureId, 'rak-2');
      expect(saved.locationLabel, 'Rak belakang');
      expect(saved.lowStockThreshold, 3);
      expect(
        (await persistInternalBarcode(
          repository,
          'a',
          canManage: () => true,
        )).barcode,
        saved.barcode,
      );
      expect(
        (await persistInternalBarcode(
          repository,
          'b',
          canManage: () => true,
        )).barcode,
        isNot(saved.barcode),
      );
    },
  );

  test(
    'SQLite persists generated barcode; reopened repository exports exact code',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = DriftProductRepository(database);
      await repository.save(product('local'));
      await repository.save(product('packaging', barcode: '0012345678905'));
      final saved = await persistInternalBarcode(
        repository,
        'local',
        canManage: () => true,
      );
      final reopened = DriftProductRepository(database);
      final found = await reopened.findByBarcode(saved.barcode!);
      expect(found!.id, 'local');
      expect(found.costPrice, 9000);
      expect(found.stock, 17);
      expect((await reopened.findByBarcode('0012345678905'))!.id, 'packaging');
      final document = BarcodeLabelsDocument([BarcodeLabelLine(found, 17)]);
      expect(document.lines.single.product.barcode, saved.barcode);
      expect(latin1.decode(await document.pdf()), startsWith('%PDF-'));
      expect(document.pageCount, 2);
    },
  );

  test('Reject unprintable code, unsafe length and quantities', () {
    expect(barcodeLabelError('ABC-0123'), isNull);
    for (final code in [null, '', 'abc\n', 'é', ' ABC', 'x' * 25]) {
      expect(barcodeLabelError(code), isNotNull);
    }
    final p = product('a', barcode: 'AB123');
    for (final quantity in [-1, 0, 101]) {
      expect(() => BarcodeLabelLine(p, quantity), throwsArgumentError);
    }
    expect(() => BarcodeLabelsDocument([]), throwsArgumentError);
    expect(
      () => BarcodeLabelsDocument([
        for (var i = 0; i < 6; i++) BarcodeLabelLine(p, 100),
      ]),
      throwsArgumentError,
    );
  });

  test('Real PDF A4 multipage vector labels, same encoded persisted code and quiet zones', () async {
    final repository = InMemoryProductRepository([product('a')]);
    final saved = await persistInternalBarcode(
      repository,
      'a',
      canManage: () => true,
    );
    final document = BarcodeLabelsDocument([BarcodeLabelLine(saved, 33)]);
    expect(document.pageCount, 3);
    final bytes = await document.pdf();
    final pdf = latin1.decode(bytes);
    expect(pdf, startsWith('%PDF-'));
    expect(RegExp(r'/Type\s*/Page\b').allMatches(pdf).length, 3);
    expect(pdf, contains('/MediaBox'));
    expect(pdf, contains('595.275'));
    final bars = pw.Barcode.code128()
        .make(
          saved.barcode!,
          width:
              BarcodeLabelsDocument.labelWidth -
              BarcodeLabelsDocument.quietZone * 2,
          height: 28,
          drawText: false,
        )
        .whereType<pw.BarcodeBar>()
        .toList();
    expect(bars.where((b) => b.black).length, greaterThan(20));
    expect(
      bars.every(
        (b) =>
            b.left >= 0 &&
            b.left + b.width <=
                BarcodeLabelsDocument.labelWidth -
                    2 * BarcodeLabelsDocument.quietZone +
                    0.001,
      ),
      isTrue,
    );
    final module = bars.map((b) => b.width).reduce((a, b) => a < b ? a : b);
    expect(BarcodeLabelsDocument.quietZone, greaterThanOrEqualTo(module * 10));
    for (final code in [
      'A',
      '123',
      saved.barcode!,
      'ABCDEFGHIJKLMNOPQRSTUVWX',
    ]) {
      final geometry = barcodeLabelGeometry(
        code,
        BarcodeLabelsDocument.labelWidth,
      );
      final bars = pw.Barcode.code128()
          .make(code, width: geometry.bars, height: 28, drawText: false)
          .whereType<pw.BarcodeBar>();
      final module = bars
          .map((bar) => bar.width)
          .reduce((a, b) => a < b ? a : b);
      expect(geometry.quiet + 0.001, greaterThanOrEqualTo(module * 10));
    }
    expect(bars.first.black, isTrue);
    expect(bars.last.black, isTrue);
    expect(
      8 * (BarcodeLabelsDocument.labelHeight + BarcodeLabelsDocument.gap),
      lessThan(841.89 - 2 * BarcodeLabelsDocument.margin),
    );
    Uint8List? shared;
    await exportBarcodeLabels(
      repository: repository,
      quantities: {'a': 1},
      showPrice: false,
      canManage: () => true,
      share: (bytes) async {
        shared = bytes;
        return const ShareResult('', ShareResultStatus.dismissed);
      },
    );
    expect(shared, isNotNull);
    expect(
      (await repository.findByBarcode(saved.barcode!))!.barcode,
      saved.barcode,
    );
  });

  test('Owner revoked while loading stops persistence and export', () async {
    final repository = PausedRepository([product('a')]);
    var owner = true;
    repository.pause = Completer<void>();
    final saving = persistInternalBarcode(
      repository,
      'a',
      canManage: () => owner,
    );
    owner = false;
    repository.pause!.complete();
    await expectLater(saving, throwsStateError);
    expect(repository.writes, 0);
    owner = true;
    repository.pause = Completer<void>();
    var shares = 0;
    final exporting = exportBarcodeLabels(
      repository: repository,
      quantities: {'a': 1},
      showPrice: true,
      canManage: () => owner,
      share: (_) async {
        shares++;
        return const ShareResult('', ShareResultStatus.success);
      },
    );
    owner = false;
    repository.pause!.complete();
    await expectLater(exporting, throwsStateError);
    expect(shares, 0);
  });

  test(
    'Owner revoked after PDF starts prevents share; share error propagates',
    () async {
      final repository = InMemoryProductRepository([
        product('a', barcode: '00123'),
      ]);
      var checks = 0;
      var shares = 0;
      await expectLater(
        exportBarcodeLabels(
          repository: repository,
          quantities: {'a': 1},
          showPrice: true,
          canManage: () => ++checks < 3,
          share: (_) async {
            shares++;
            return const ShareResult('', ShareResultStatus.success);
          },
        ),
        throwsStateError,
      );
      expect(shares, 0);
      await expectLater(
        exportBarcodeLabels(
          repository: repository,
          quantities: {'a': 1},
          showPrice: true,
          canManage: () => true,
          share: (_) async => throw StateError('share failed'),
        ),
        throwsStateError,
      );
      await expectLater(
        exportBarcodeLabels(
          repository: InMemoryProductRepository([product('a')]),
          quantities: {'a': 1},
          showPrice: true,
          canManage: () => true,
          share: (_) async {
            shares++;
            return const ShareResult('', ShareResultStatus.success);
          },
        ),
        throwsArgumentError,
      );
      expect(shares, 0);
    },
  );

  Future<void> screen(
    WidgetTester tester,
    AppSession session,
    InMemoryProductRepository repository, {
    BarcodeLabelShare? share,
  }) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      AppSessionScope(
        session: session,
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          ),
          home: BarcodeLabelsScreen(
            repository: repository,
            share:
                share ??
                (_) async => const ShareResult('', ShareResultStatus.dismissed),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Owner preview at 360dp scale 1.3, search, qty and share failure retry',
    (tester) async {
      final session = AppSession();
      addTearDown(session.dispose);
      await screen(
        tester,
        session,
        InMemoryProductRepository([product('a', barcode: '00123')]),
        share: (_) async => throw StateError('share failed'),
      );
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byType(BarcodeLabelPreview),
        100,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.byType(BarcodeLabelPreview), findsOneWidget);
      await tester.tap(find.byTooltip('Tambah label Produk a'));
      await tester.pump();
      expect(
        find.text('2 label • 1 halaman A4 • maks. 500 label'),
        findsOneWidget,
      );
      await tester.tap(find.text('Bagikan PDF A4'));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, 700));
      await tester.pumpAndSettle();

      expect(find.textContaining('PDF belum dibagikan.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      session.selectRole(UserRole.cashier);
      await tester.pumpAndSettle();
      expect(find.text('Akses terbatas'), findsOneWidget);
      expect(find.text('Bagikan PDF A4'), findsNothing);
    },
  );

  testWidgets('Search filters products; cancelling confirmation never writes', (
    tester,
  ) async {
    final session = AppSession();
    addTearDown(session.dispose);
    final repository = PausedRepository([product('a'), product('b')]);
    await screen(tester, session, repository);
    await tester.enterText(find.byType(TextField), 'Produk a');
    await tester.pumpAndSettle();
    expect(find.widgetWithText(CheckboxListTile, 'Produk a'), findsOneWidget);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    expect(find.text('Produk b'), findsNothing);
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buat kode internal (1 produk)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(repository.writes, 0);
    expect(
      repository.snapshot.every((product) => product.barcode == null),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Cashier direct route blocked; empty catalogue offers real catalogue',
    (tester) async {
      final session = AppSession();
      addTearDown(session.dispose);
      session.selectRole(UserRole.cashier);
      await screen(tester, session, InMemoryProductRepository());
      expect(find.text('Akses terbatas'), findsOneWidget);
      session.selectRole(UserRole.owner);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Buka katalog / tambah produk'),
        100,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.text('Buka katalog / tambah produk'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Explicit confirmation, partial failure preserves successful code',
    (tester) async {
      final session = AppSession();
      addTearDown(session.dispose);
      final repository = FailingRepository([product('a'), product('b')]);
      await screen(tester, session, repository);
      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Produk b'),
        150,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Produk b'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Buat kode internal (2 produk)'));
      await tester.pumpAndSettle();
      expect(repository.snapshot.every((p) => p.barcode == null), isTrue);
      await tester.tap(find.text('Simpan kode'));
      await tester.pumpAndSettle();
      expect(repository.snapshot.first.barcode, startsWith('RG'));
      expect(repository.snapshot.last.barcode, isNull);
      expect(
        find.textContaining('1 dari 2 kode terverifikasi tersimpan.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
