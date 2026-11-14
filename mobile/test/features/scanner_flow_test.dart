import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ryangunshop/core/data/app_database.dart';
import 'package:ryangunshop/core/data/drift_product_repository.dart';
import 'package:ryangunshop/core/data/in_memory_product_repository.dart';
import 'package:ryangunshop/core/data/product_record.dart';
import 'package:ryangunshop/core/session/app_session.dart';
import 'package:ryangunshop/core/session/user_role.dart';
import 'package:ryangunshop/core/theme/app_theme.dart';
import 'package:ryangunshop/features/catalog/model/catalog_product.dart';
import 'package:ryangunshop/features/checkout/view/cart_checkout_screen.dart';
import 'package:ryangunshop/features/checkout/view_model/cart_view_model.dart';
import 'package:ryangunshop/features/scanner/model/scanner_scenario.dart';
import 'package:ryangunshop/features/scanner/view/product_scanner_screen.dart';
import 'package:ryangunshop/features/scanner/view/scanner_camera.dart';
import 'package:ryangunshop/features/scanner/view_model/scanner_view_model.dart';

const product = ProductRecord(
  id: 'kopi',
  barcode: '899123',
  name: 'Kopi lokal',
  salePrice: 7000,
  stock: 4,
  category: 'Minuman',
);

class FakeCamera extends ScannerCamera {
  ValueChanged<String>? emit;
  @override
  bool supported = true;
  @override
  bool running = false;
  @override
  bool requesting = false;
  @override
  bool denied = false;
  @override
  bool torchOn = false;
  @override
  bool get torchAvailable => running;
  @override
  String? error;
  int starts = 0;
  bool closed = false;
  @override
  Widget preview(ValueChanged<String> onCode) {
    emit = onCode;
    return const SizedBox.expand();
  }

  @override
  Future<void> start() async {
    starts++;
    running = !denied;
    notifyListeners();
  }

  @override
  Future<void> stop() async {
    running = false;
    notifyListeners();
  }

  @override
  Future<void> toggleTorch() async {
    torchOn = !torchOn;
    notifyListeners();
  }

  @override
  Future<void> close() async {
    closed = true;
    running = false;
    dispose();
  }
}

class FailingRepository extends InMemoryProductRepository {
  FailingRepository() : super([product]);
  bool fail = true;
  Completer<void>? gate;
  @override
  Future<ProductRecord?> findByBarcode(String barcode) async {
    await gate?.future;
    if (fail) throw StateError('DB unavailable');
    return super.findByBarcode(barcode);
  }

  @override
  Future<List<ProductRecord>> listProducts() async {
    if (fail) throw StateError('DB unavailable');
    return super.listProducts();
  }
}

void main() {
  testWidgets(
    'kasir barcode asing tanpa tambah, pencarian manual tetap tersedia',
    (tester) async {
      final session = AppSession()..selectRole(UserRole.cashier);
      addTearDown(session.dispose);
      final camera = FakeCamera();
      await showScanner(tester, session: session, camera: camera);
      camera.emit!('BARU');
      await tester.pumpAndSettle();
      expect(find.text('Produk tidak ditemukan'), findsOneWidget);
      expect(find.text('Tambah Produk'), findsNothing);
      expect(
        find.text(
          'Barcode belum terdaftar. Cari produk manual atau minta pemilik menambahkannya.',
        ),
        findsOneWidget,
      );
      await tapText(tester, 'Cari Produk Manual');
      expect(find.byType(TextField), findsOneWidget);
      expect(await session.productRepository.listProducts(), isEmpty);
    },
  );

  testWidgets('scanner menolak hasil formulir setelah peran berubah', (
    tester,
  ) async {
    final session = AppSession();
    addTearDown(session.dispose);
    final camera = FakeCamera();
    await showScanner(tester, session: session, camera: camera);
    camera.emit!('BARU');
    await tester.pumpAndSettle();
    await tapText(tester, 'Tambah Produk');
    final context = tester.element(find.byType(TextFormField).first);
    session.selectRole(UserRole.cashier);
    Navigator.of(context).pop(CatalogProduct.fromRecord(product));
    await tester.pumpAndSettle();
    expect(await session.productRepository.listProducts(), isEmpty);
    expect(find.text('Tambah Produk'), findsNothing);
  });
  testWidgets(
    'barcode baru membuka formulir terisi dan benar-benar tersimpan',
    (tester) async {
      final session = AppSession();
      addTearDown(session.dispose);
      final camera = FakeCamera();
      await showScanner(tester, session: session, camera: camera);
      camera.emit!('899NEW');
      await tester.pumpAndSettle();
      await tapText(tester, 'Tambah Produk');
      expect(camera.running, isFalse);
      final barcode = find.widgetWithText(
        TextFormField,
        'Barcode / SKU (Opsional)',
      );
      expect(tester.widget<TextFormField>(barcode).controller!.text, '899NEW');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nama Produk *'),
        'Teh baru',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Harga Jual *'),
        '5000',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Stok Saat Ini *'),
        '3',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tapText(tester, 'Simpan Produk');
      expect(
        (await session.productRepository.findByBarcode('899NEW'))?.name,
        'Teh baru',
      );
      expect(session.cart.isEmpty, isTrue);
      await tapText(tester, 'Konfirmasi ke Keranjang');
      expect(session.cart.totalItems, 1);
    },
  );

  testWidgets(
    'katalog kosong tidak menyuntik sampel; manual error dapat retry',
    (tester) async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final session = AppSession(database: database);
      addTearDown(session.dispose);
      final camera = FakeCamera();
      await showScanner(tester, session: session, camera: camera);
      camera.emit!('899123');
      await tester.pumpAndSettle();
      expect(find.text('Produk tidak ditemukan'), findsOneWidget);
      expect(await session.productRepository.listProducts(), isEmpty);
      await tester.tap(find.byTooltip('Cari Produk Manual'));
      await tester.pumpAndSettle();
      expect(find.text('Belum ada produk di katalog'), findsOneWidget);
      final nav = Navigator.of(tester.element(find.byType(TextField)));
      nav.pop();
      await tester.pumpAndSettle();
      final repo = FailingRepository();
      final model = ScannerViewModel(repository: repo);
      addTearDown(model.dispose);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await showScanner(
        tester,
        session: session,
        camera: FakeCamera(),
        model: model,
      );
      await tester.tap(find.byTooltip('Cari Produk Manual'));
      await tester.pumpAndSettle();
      expect(find.text('Katalog gagal dibaca. Coba lagi.'), findsOneWidget);
      expect(find.text('Belum ada produk di katalog'), findsNothing);
      repo.fail = false;
      await tapText(tester, 'Coba Lagi');
      expect(find.text('Kopi lokal'), findsOneWidget);
    },
  );
  test(
    'lookup error berbeda dari tidak ditemukan; retry mempertahankan kode',
    () async {
      final repo = FailingRepository();
      final model = ScannerViewModel(repository: repo);
      addTearDown(model.dispose);
      await model.detect(product.barcode!);
      expect(model.scenario, ScannerScenario.failure);
      expect(model.code, product.barcode);
      repo.fail = false;
      await model.retryLookup();
      expect(model.detectedProduct?.id, product.id);
      model.reset();
      await model.detect('unknown');
      expect(model.scenario, ScannerScenario.empty);
      expect(model.error, isNull);
    },
  );

  test(
    'frame berulang terkunci; konfirmasi sekali; jumlah dan stok segar',
    () async {
      final repo = FailingRepository()..fail = false;
      final model = ScannerViewModel(repository: repo);
      final cart = CartViewModel();
      addTearDown(model.dispose);
      addTearDown(cart.dispose);
      repo.gate = Completer();
      final first = model.detect(product.barcode!);
      await model.detect('wrong');
      expect(model.code, product.barcode);
      repo.gate!.complete();
      await first;
      expect(cart.isEmpty, isTrue);
      model.changeQuantity(0);
      expect(model.quantity, 1);
      model.changeQuantity(5);
      expect(model.quantity, 1);
      model.changeQuantity(3);
      await repo.save(product.copyWith(stock: 2));
      await model.confirm(cart);
      expect(cart.isEmpty, isTrue);
      expect(model.quantity, 2);
      await Future.wait([model.confirm(cart), model.confirm(cart)]);
      expect(cart.totalItems, 2);
      await model.confirm(cart);
      await model.detect(product.barcode!);
      expect(cart.totalItems, 2);
      model.reset();
      await model.detect(product.barcode!);
      await model.confirm(cart);
      expect(cart.totalItems, 2);
      expect(model.error, contains('Stok tidak cukup'));
      await repo.save(product.copyWith(stock: 0));
      await model.confirm(cart);
      expect(model.detectedProduct!.stock, 0);
      expect(cart.totalItems, 2);
    },
  );

  test(
    'perubahan harga, produk dihapus dan error revalidasi tidak menambah',
    () async {
      final repo = FailingRepository()..fail = false;
      final model = ScannerViewModel(repository: repo);
      final cart = CartViewModel();
      addTearDown(model.dispose);
      addTearDown(cart.dispose);
      await model.detect(product.barcode!);
      repo.fail = true;
      await model.confirm(cart);
      expect(model.error, contains('gagal diperiksa'));
      expect(cart.isEmpty, isTrue);
      repo.fail = false;
      await repo.save(
        const ProductRecord(
          id: 'kopi',
          barcode: '899123',
          name: 'Kopi lokal',
          salePrice: 9000,
          stock: 4,
        ),
      );
      await model.confirm(cart);
      expect(model.error, contains('Harga berubah'));
      expect(cart.isEmpty, isTrue);
      await repo.delete(product.id);
      await model.confirm(cart);
      expect(model.scenario, ScannerScenario.empty);
      expect(cart.isEmpty, isTrue);
    },
  );

  testWidgets(
    'callback kamera nyata, lampu, konfirmasi, pindai lagi dan checkout',
    (tester) async {
      final session = AppSession();
      await session.productRepository.save(product);
      final camera = FakeCamera();
      await showScanner(tester, session: session, camera: camera);
      expect(camera.running, isTrue);
      expect(find.text('Data contoh'), findsNothing);
      expect(find.text('Coba Pindai Contoh'), findsNothing);
      await tester.tap(find.byTooltip('Nyalakan Lampu'));
      await tester.pumpAndSettle();
      expect(camera.torchOn, isTrue);
      camera.emit!(product.barcode!);
      camera.emit!(product.barcode!);
      await tester.pumpAndSettle();
      expect(camera.running, isFalse);
      expect(find.text('Barcode: 899123'), findsOneWidget);
      expect(session.cart.isEmpty, isTrue);
      await tapText(tester, 'Detail Produk');
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(camera.running, isFalse);
      await tapText(tester, 'Tutup');
      await tapText(tester, 'Konfirmasi ke Keranjang');
      expect(session.cart.totalItems, 1);
      await tapText(tester, 'Kembali ke Kasir');
      expect(find.byType(CartCheckoutScreen), findsOneWidget);
      expect(camera.running, isFalse);
      Navigator.of(tester.element(find.byType(CartCheckoutScreen))).pop();
      await tester.pumpAndSettle();
      expect(camera.running, isFalse);
      await tapText(tester, 'Pindai Lagi');
      expect(camera.running, isTrue);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      expect(camera.closed, isTrue);
      session.dispose();
    },
  );

  testWidgets(
    'pencarian manual lokal tanpa sampel; pause resume lifecycle dan rute',
    (tester) async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      await DriftProductRepository(database).save(product);
      final session = AppSession(database: database);
      addTearDown(session.dispose);
      final camera = FakeCamera();
      await showScanner(tester, session: session, camera: camera);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pumpAndSettle();
      expect(camera.running, isFalse);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(camera.running, isTrue);
      await tester.tap(find.byTooltip('Cari Produk Manual'));
      await tester.pumpAndSettle();
      expect(camera.running, isFalse);
      expect(find.text('Pencarian produk lokal'), findsOneWidget);
      expect(find.text('Kopi lokal'), findsOneWidget);
      expect(find.text('Minyak goreng 1 liter'), findsNothing);
      await tester.enterText(find.byType(TextField), 'missing');
      await tester.pumpAndSettle();
      expect(find.text('Produk tidak ditemukan'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '899123');
      await tester.pumpAndSettle();
      await tapText(tester, 'Kopi lokal');
      await tapText(tester, 'Konfirmasi ke Keranjang');
      expect(session.cart.totalItems, 1);
      await tapText(tester, 'Pindai Lagi');
      expect(camera.running, isTrue);
      final nav = Navigator.of(
        tester.element(find.byType(ProductScannerScreen)),
      );
      unawaited(
        nav.push(
          MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('Other route')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(camera.running, isFalse);
      nav.pop();
      await tester.pumpAndSettle();
      expect(camera.running, isTrue);
    },
  );

  testWidgets(
    'izin ditolak dan error kamera tetap menyediakan manual; 360dp skala 1,3',
    (tester) async {
      final session = AppSession();
      addTearDown(session.dispose);
      final camera = FakeCamera()
        ..denied = true
        ..error = 'Izinkan kamera lewat Pengaturan Android.';
      await showScanner(tester, session: session, camera: camera);
      expect(find.text('Izin kamera ditolak'), findsOneWidget);
      expect(find.byTooltip('Nyalakan Lampu'), findsNothing);
      await tester.tap(find.byTooltip('Cari Produk Manual'));
      await tester.pumpAndSettle();
      expect(find.text('Belum ada produk di katalog'), findsOneWidget);
      Navigator.of(tester.element(find.text('Belum ada produk di katalog')))
          .pop();
      await tester.pumpAndSettle();
      camera.denied = false;
      camera.error = 'Kamera dipakai aplikasi lain';
      camera.notifyListeners();
      await tester.pumpAndSettle();
      expect(find.text('Kamera gagal'), findsOneWidget);
      camera.error = null;
      await tapText(tester, 'Coba Izin / Kamera Lagi');
      expect(camera.running, isTrue);
      expect(tester.takeException(), isNull);
      final semantics = tester.ensureSemantics();
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      semantics.dispose();
    },
  );

  testWidgets('DB kosong bukan katalog sampel; unknown dan retry DB error', (
    tester,
  ) async {
    final session = AppSession();
    addTearDown(session.dispose);
    final repo = FailingRepository();
    final model = ScannerViewModel(repository: repo);
    addTearDown(model.dispose);
    final camera = FakeCamera();
    await showScanner(tester, session: session, camera: camera, model: model);
    camera.emit!('unknown');
    await tester.pumpAndSettle();
    expect(find.text('Katalog gagal dibaca'), findsOneWidget);
    expect(find.text('Produk tidak ditemukan'), findsNothing);
    repo.fail = false;
    await tapText(tester, 'Coba Pencarian Lagi');
    expect(find.text('Produk tidak ditemukan'), findsOneWidget);
    expect(find.text('Barcode: unknown'), findsOneWidget);
    expect(session.cart.isEmpty, isTrue);
    await tapText(tester, 'Pindai Lagi');
    await tester.tap(find.byTooltip('Cari Produk Manual'));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byType(TextField))).pop();
    await tester.pumpAndSettle();
    expect(camera.running, isTrue);
  });
}

Future<void> tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.pumpAndSettle();
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

Future<void> showScanner(
  WidgetTester tester, {
  required AppSession session,
  required FakeCamera camera,
  ScannerViewModel? model,
}) async {
  tester.view.physicalSize = const Size(360, 800);
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
        home: ProductScannerScreen(camera: camera, viewModel: model),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
