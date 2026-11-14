import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ryangunshop/app/app.dart';
import 'package:ryangunshop/app/shell/app_shell.dart';
import 'package:ryangunshop/app/shell/shell_destination.dart';
import 'package:ryangunshop/core/data/product_record.dart';
import 'package:ryangunshop/core/session/app_session.dart';
import 'package:ryangunshop/app/startup/app_startup_state.dart';
import 'package:ryangunshop/core/session/user_role.dart';
import 'package:ryangunshop/features/catalog/model/catalog_product.dart';
import 'package:ryangunshop/features/payment/view/payment_sheet.dart';
import 'package:ryangunshop/features/payment/view/payment_success_screen.dart';

void main() {
  setUp(AppStartupState.resetForTesting);

  testWidgets(
    'Alur lengkap pengguna: onboarding hingga simulasi kasir tanpa nota tersimpan',
    (tester) async {
      // 1. Viewport ponsel standar
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final session = AppSession();
      addTearDown(session.dispose);
      await tester.pumpWidget(RyanGunshopApp(session: session));
      expect(find.text('RyanGunshop'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.text('Lewati'), findsOneWidget);

      // Lewati onboarding ke AppShell
      await tester.tap(find.text('Lewati'));
      await tester.pumpAndSettle();

      expect(find.byType(AppShell), findsOneWidget);

      // Beranda pemilik menyediakan pengelolaan; Kasir tetap lewat navigasi.
      expect(find.text('Beranda'), findsWidgets);
      expect(find.text('Kelola warung'), findsOneWidget);
      expect(find.text('Tambah Produk'), findsOneWidget);
      expect(find.text('Kelola Stok'), findsOneWidget);
      expect(find.text('Label Barcode'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('0 nota'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Penjualan bersih: Rp 0'), findsOneWidget);
      expect(find.text('Rata-rata per nota: Rp 0'), findsOneWidget);

      session.cart.addProduct(
        const CatalogProduct(
          id: 'contoh-produk-1',
          name: 'Beras pandan wangi 1 kg',
          price: 16000,
          stock: 12,
          unit: 'bungkus',
          fixtureId: '',
          locationLabel: '',
          category: 'Sembako',
        ),
      );

      // Buka Kasir tanpa mengubah keranjang yang sudah terisi.
      await tester.tap(find.byTooltip(ShellDestination.cashier.label));
      await tester.pumpAndSettle();

      // Verifikasi layar kasir & keranjang terisi
      expect(find.text('Transaksi Kasir'), findsOneWidget);
      expect(find.text('KASIR MEJA 01 • SHIFT SIANG'), findsOneWidget);
      expect(find.text('Rincian Barang Belanja'), findsOneWidget);
      expect(find.text('DAFTAR PESANAN'), findsOneWidget);
      expect(find.text('Lanjut ke Pembayaran'), findsOneWidget);

      // 5. Lanjut ke Pembayaran
      await tester.tap(find.text('Lanjut ke Pembayaran'));
      await tester.pumpAndSettle();

      expect(find.byType(PaymentSheet), findsOneWidget);
      expect(find.text('NOMINAL CEPAT UANG PAS'), findsOneWidget);

      // Tekan Uang Pas
      await tester.tap(find.text('Uang Pas'));
      await tester.pumpAndSettle();

      expect(find.text('KEMBALIAN PELANGGAN'), findsOneWidget);
      expect(find.text('Kembalian: Rp 0'), findsOneWidget);

      // Selesaikan pembayaran tunai
      await tester.tap(find.text('Simpan Transaksi Tunai'));
      await tester.pumpAndSettle();

      // 6. Layar Ringkasan Pembayaran Sukses & Struk
      expect(find.byType(PaymentSuccessScreen), findsOneWidget);
      expect(find.text('Transaksi Tunai Tersimpan'), findsOneWidget);
      expect(find.text('Cetak Struk (Bluetooth)'), findsOneWidget);

      // Cetak struk bluetooth
      final printBtn = find.text('Cetak Struk (Bluetooth)');
      await tester.ensureVisible(printBtn);
      await tester.pumpAndSettle();
      await tester.tap(printBtn);
      await tester.pump();
      expect(find.textContaining('Mencetak nota'), findsOneWidget);
      // Bersihkan snackbar seketika agar tidak menghalangi tombol di bawahnya
      ScaffoldMessenger.of(tester.element(find.byType(PaymentSuccessScreen)))
          .clearSnackBars();
      await tester.pumpAndSettle();

      // Tekan Transaksi Baru untuk kembali ke menu utama
      final newTrxBtn = find.text('Transaksi Baru');
      await tester.ensureVisible(newTrxBtn);
      await tester.pumpAndSettle();
      await tester.tap(newTrxBtn);
      await tester.pumpAndSettle();

      // 7. Transaksi riil tercatat di Beranda!
      await tester.tap(find.text(ShellDestination.home.label));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('1 nota'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Penjualan bersih: Rp 16.000'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Nota terbaru'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Nota terbaru'), findsOneWidget);
    },
  );

  testWidgets(
    'Alur pengguna: Katalog -> Pilih Produk -> Masuk Keranjang Kasir',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      AppStartupState.markOnboardingSeen();

      final session = AppSession();
      addTearDown(session.dispose);
      await session.productRepository.save(
        const ProductRecord(
          id: 'contoh-produk-1',
          name: 'Beras pandan wangi 1 kg',
          salePrice: 16000,
          stock: 12,
          unit: 'bungkus',
          category: 'Sembako',
        ),
      );

      await tester.pumpWidget(RyanGunshopApp(session: session));
      await tester.pumpAndSettle();

      // 1. Pindah ke tab Katalog
      await tester.tap(find.text(ShellDestination.catalog.label));
      await tester.pumpAndSettle();

      expect(find.text('Beras pandan wangi 1 kg'), findsOneWidget);

      // 2. Ketuk salah satu produk untuk membuka detail
      await tester.ensureVisible(find.text('Beras pandan wangi 1 kg'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Beras pandan wangi 1 kg'));
      await tester.pumpAndSettle();

      expect(find.text('Harga Jual'), findsOneWidget);
      expect(find.text('+ Kasir'), findsOneWidget);

      // 3. Tambah ke keranjang
      await tester.tap(find.text('+ Kasir'));
      await tester.pumpAndSettle();

      // 4. Buka tab Kasir
      await tester.tap(find.byTooltip(ShellDestination.cashier.label));
      await tester.pumpAndSettle();

      expect(find.text('Transaksi Kasir'), findsOneWidget);
      expect(find.text('Beras pandan wangi 1 kg'), findsWidgets);
    },
  );

  testWidgets(
    'Alur pengguna: Pengaturan Peran -> Hak akses edit denah berubah',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      AppStartupState.markOnboardingSeen();

      final session = AppSession();
      addTearDown(session.dispose);

      await tester.pumpWidget(RyanGunshopApp(session: session));
      await tester.pumpAndSettle();

      // Awalnya peran Pemilik -> boleh edit denah
      expect(session.canEditFloorPlan, isTrue);

      // Buka Pengaturan via App Bar
      await tester.tap(find.byTooltip('Pengaturan'));
      await tester.pumpAndSettle();

      expect(find.text('Peran Pengguna'), findsOneWidget);
      expect(find.text('Kasir'), findsOneWidget);

      // Pilih peran Kasir
      await tester.tap(find.text('Kasir'));
      await tester.pumpAndSettle();

      expect(session.role, UserRole.cashier);
      expect(session.canEditFloorPlan, isFalse);
    },
  );
}
