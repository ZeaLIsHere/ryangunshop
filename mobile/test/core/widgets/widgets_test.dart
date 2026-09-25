import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ryangunshop/core/theme/app_spacing.dart';
import 'package:ryangunshop/core/theme/app_theme.dart';
import 'package:ryangunshop/core/widgets/widgets.dart';

Widget _host(Widget child) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.screen),
        child: child,
      ),
    ),
  );
}

void main() {
  group('PrimaryAction', () {
    testWidgets('menampilkan label dan memanggil aksi', (tester) async {
      var pressed = 0;
      await tester.pumpWidget(
        _host(PrimaryAction(label: 'Mulai pindai', onPressed: () => pressed++)),
      );

      expect(find.text('Mulai pindai'), findsOneWidget);

      await tester.tap(find.text('Mulai pindai'));
      expect(pressed, 1);
    });

    testWidgets('memenuhi target sentuh minimal', (tester) async {
      await tester.pumpWidget(
        _host(PrimaryAction(label: 'Mulai pindai', onPressed: () {})),
      );

      final size = tester.getSize(find.byType(FilledButton));
      expect(size.height, greaterThanOrEqualTo(AppSpacing.minTouchTarget));
    });

    testWidgets('tidak memanggil aksi selama memuat', (tester) async {
      var pressed = 0;
      await tester.pumpWidget(
        _host(
          PrimaryAction(
            label: 'Menyimpan',
            isLoading: true,
            onPressed: () => pressed++,
          ),
        ),
      );

      expect(find.byType(BrandSpinner), findsOneWidget);

      await tester.tap(find.byType(FilledButton), warnIfMissed: false);
      expect(pressed, 0);
    });
  });

  group('AppCard', () {
    testWidgets('memanggil aksi saat ditekan', (tester) async {
      var pressed = 0;
      await tester.pumpWidget(
        _host(
          AppCard(onTap: () => pressed++, child: const Text('Rak minuman')),
        ),
      );

      await tester.tap(find.text('Rak minuman'));
      expect(pressed, 1);
    });
  });

  group('AppTextField', () {
    testWidgets('menampilkan pesan validasi', (tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(
        _host(
          Form(
            key: formKey,
            child: AppTextField(
              label: 'Nama produk',
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Nama wajib diisi'
                  : null,
            ),
          ),
        ),
      );

      formKey.currentState!.validate();
      await tester.pump();

      expect(find.text('Nama wajib diisi'), findsOneWidget);
    });
  });

  group('BrandSpinner', () {
    testWidgets('menampilkan label status', (tester) async {
      await tester.pumpWidget(
        _host(const BrandSpinner(label: 'Memuat data contoh')),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Memuat data contoh'), findsOneWidget);
    });
  });

  group('RyanAppLogo', () {
    testWidgets('memakai penanda sementara selama aset belum ada', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const RyanAppLogo(size: 48)));

      expect(find.text('RyanGunshop'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });
  });

  group('showAppConfirmDialog', () {
    testWidgets('mengembalikan true hanya setelah konfirmasi', (tester) async {
      bool? result;
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) => PrimaryAction(
              label: 'Buka konfirmasi',
              onPressed: () async {
                result = await showAppConfirmDialog(
                  context: context,
                  title: 'Hapus produk?',
                  message: 'Tindakan ini tidak dapat dibatalkan.',
                  confirmLabel: 'Hapus',
                  isDestructive: true,
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Buka konfirmasi'));
      await tester.pumpAndSettle();
      expect(find.text('Hapus produk?'), findsOneWidget);
      expect(result, isNull);

      await tester.tap(find.widgetWithText(FilledButton, 'Hapus'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });
  });

  group('showAppBottomSheet', () {
    testWidgets('menampilkan judul dan isi', (tester) async {
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) => PrimaryAction(
              label: 'Buka sheet',
              onPressed: () => showAppBottomSheet<void>(
                context: context,
                title: 'Pilih produk',
                child: const Text('Isi sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Buka sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Pilih produk'), findsOneWidget);
      expect(find.text('Isi sheet'), findsOneWidget);
    });
  });
}
