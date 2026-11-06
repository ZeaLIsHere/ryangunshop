import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ryangunshop/core/format/rupiah.dart';
import 'package:ryangunshop/core/session/app_session.dart';
import 'package:ryangunshop/core/theme/app_theme.dart';
import 'package:ryangunshop/features/checkout/view/cart_checkout_screen.dart';
import 'package:ryangunshop/features/payment/model/payment_preview.dart';
import 'package:ryangunshop/features/payment/view/payment_sheet.dart';
import 'package:ryangunshop/features/payment/view/payment_success_screen.dart';

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
    expect(find.text('Kembalian'), findsOneWidget);
    expect(find.text(formatRupiah(0)), findsWidgets);

    // Tekan chip 50.000
    final chip50k = find.text(formatRupiah(50000));
    await tester.ensureVisible(chip50k);
    await tester.tap(chip50k);
    await tester.pumpAndSettle();

    // 50000 - 23000 = 27000
    expect(find.text(formatRupiah(27000)), findsOneWidget);
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

    expect(find.text('Pembayaran Berhasil!'), findsOneWidget);
    expect(find.text('Cetak Struk'), findsOneWidget);
    expect(find.text('Transaksi Baru'), findsOneWidget);
    expect(find.text(formatRupiah(27000)), findsOneWidget);
  });

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
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.3)),
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
}

void _usePhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}
