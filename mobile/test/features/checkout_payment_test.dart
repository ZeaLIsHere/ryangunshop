import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ryangunshop/core/format/rupiah.dart';
import 'package:ryangunshop/core/session/app_session.dart';
import 'package:ryangunshop/core/theme/app_theme.dart';
import 'package:ryangunshop/features/checkout/view/cart_checkout_screen.dart';
import 'package:ryangunshop/features/checkout/model/cart_scenario.dart';
import 'package:ryangunshop/features/payment/model/payment_preview.dart';
import 'package:ryangunshop/features/payment/view/payment_sheet.dart';
import 'package:ryangunshop/features/payment/view/payment_success_screen.dart';
import 'package:ryangunshop/features/payment/view_model/payment_view_model.dart';

void main() {
  testWidgets('CartCheckoutScreen menampilkan barang dan menghitung total', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    final session = AppSession();
    addTearDown(session.dispose);

    await tester.pumpWidget(
      AppSessionScope(
        session: session,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const CartCheckoutScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Transaksi Kasir'), findsOneWidget);
    expect(find.text('Lanjut ke Pembayaran'), findsOneWidget);
    expect(find.text(formatRupiah(session.cart.total)), findsWidgets);
  });

  testWidgets('PaymentSheet menghitung kembalian tunai dengan benar', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    final session = AppSession();
    addTearDown(session.dispose);

    await tester.pumpWidget(
      AppSessionScope(
        session: session,
        child: MaterialApp(
          theme: AppTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          ),
          home: Scaffold(
            body: PaymentSheet(
              totalAmount: 23000,
              cartItems: session.cart.items,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Total Pembayaran'), findsOneWidget);
    expect(find.textContaining('Masukkan uang diterima'), findsOneWidget);
    expect(find.text('Selesaikan Simulasi Tunai'), findsOneWidget);

    // Tekan chip 50.000
    final chip50k = find.text(formatRupiah(50000));
    await tester.ensureVisible(chip50k);
    await tester.tap(chip50k);
    await tester.pumpAndSettle();

    // 50000 - 23000 = 27000
    expect(find.text('Kembalian: ${formatRupiah(27000)}'), findsOneWidget);
  });

  testWidgets('PaymentSuccessScreen menampilkan struk digital lengkap', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    final session = AppSession();
    addTearDown(session.dispose);

    await tester.pumpWidget(
      AppSessionScope(
        session: session,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: PaymentSuccessScreen(
            totalAmount: 23000,
            method: PaymentMethod.cash,
            items: session.cart.items,
            cashReceived: 50000,
            changeAmount: 27000,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Simulasi Tunai Selesai'), findsOneWidget);
    expect(find.text('Ringkasan contoh'), findsOneWidget);
    expect(find.text('Transaksi Baru'), findsOneWidget);
    expect(find.text(formatRupiah(27000)), findsOneWidget);
    expect(find.textContaining('tidak mencatat transaksi'), findsOneWidget);
  });

  test('nominal tunai wajib diisi dan mencukupi total', () {
    final viewModel = PaymentViewModel(totalAmount: 23000);
    addTearDown(viewModel.dispose);

    expect(viewModel.canCompleteCash, isFalse);
    expect(viewModel.change, isNull);
    viewModel.setCashInput('20000');
    expect(viewModel.canCompleteCash, isFalse);
    viewModel.setCashInput('50000');
    expect(viewModel.canCompleteCash, isTrue);
    expect(viewModel.change, 27000);
  });

  testWidgets('alur tunai contoh menutup keranjang tanpa klaim stok nyata', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final session = AppSession();
    addTearDown(session.dispose);

    await tester.pumpWidget(
      AppSessionScope(
        session: session,
        child: MaterialApp(
          theme: AppTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          ),
          home: const CartCheckoutScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lanjut ke Pembayaran'));
    await tester.pumpAndSettle();
    expect(find.text('Simulasi pembayaran'), findsOneWidget);
    await tester.ensureVisible(find.text('Uang Pas'));
    await tester.tap(find.text('Uang Pas'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Selesaikan Simulasi Tunai'));
    await tester.tap(find.text('Selesaikan Simulasi Tunai'));
    await tester.pumpAndSettle();

    expect(find.text('Simulasi Tunai Selesai'), findsOneWidget);
    expect(find.textContaining('tidak mencatat transaksi'), findsOneWidget);
    expect(find.text('Pembayaran Berhasil!'), findsNothing);
    expect(session.cart.isEmpty, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'QRIS contoh tidak menyelesaikan transaksi atau menghapus keranjang',
    (tester) async {
      _usePhoneViewport(tester);
      final session = AppSession();
      addTearDown(session.dispose);
      final initialItems = session.cart.totalItems;
      var completed = false;

      await tester.pumpWidget(
        AppSessionScope(
          session: session,
          child: MaterialApp(
            theme: AppTheme.light(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.3)),
              child: child!,
            ),
            home: Scaffold(
              body: PaymentSheet(
                totalAmount: 23000,
                cartItems: session.cart.items,
                onPaymentCompleted: () {
                  completed = true;
                  session.cart.clearCart();
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('QRIS'));
      await tester.pumpAndSettle();
      expect(find.text('Membuat QRIS contoh'), findsOneWidget);
      await tester.tap(find.text('Tampilkan Status Menunggu'));
      await tester.pumpAndSettle();
      expect(find.text('Menunggu pembayaran contoh'), findsOneWidget);

      await tester.tap(find.byTooltip('Pilih Status QRIS Contoh'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dibayar'));
      await tester.pumpAndSettle();
      expect(find.text('Status dibayar (simulasi)'), findsOneWidget);
      expect(find.byType(PaymentSuccessScreen), findsNothing);
      expect(session.cart.totalItems, initialItems);
      expect(completed, isFalse);
    },
  );

  testWidgets('keranjang kosong aman tanpa overflow pada 360 dp skala 1,3', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final session = AppSession();
    addTearDown(session.dispose);
    session.cart.clearCart();

    await tester.pumpWidget(
      AppSessionScope(
        session: session,
        child: MaterialApp(
          theme: AppTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          ),
          home: const CartCheckoutScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Keranjang Masih Kosong'), findsOneWidget);
    expect(find.text('Pindai Barcode'), findsOneWidget);
    expect(find.text('Pilih dari Katalog'), findsOneWidget);
    expect(find.text('Tambah cepat barang populer:'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keranjang contoh menampilkan state memuat, gagal, dan offline', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final session = AppSession();
    addTearDown(session.dispose);

    await tester.pumpWidget(
      AppSessionScope(
        session: session,
        child: MaterialApp(
          theme: AppTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          ),
          home: const CartCheckoutScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    session.cart.selectScenario(CartScenario.loading);
    await tester.pump();
    expect(find.text('Memuat keranjang contoh'), findsWidgets);
    session.cart.selectScenario(CartScenario.failure);
    await tester.pumpAndSettle();
    expect(find.text('Keranjang gagal dimuat'), findsOneWidget);
    session.cart.selectScenario(CartScenario.offline);
    await tester.pumpAndSettle();
    expect(find.textContaining('Mode offline contoh'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final semantics = tester.ensureSemantics();
    try {
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    } finally {
      semantics.dispose();
    }
  });
}

void _usePhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}
