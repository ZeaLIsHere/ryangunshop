import 'package:flutter/widgets.dart';

/// Token radius RyanGunshop.
///
/// Satu sistem radius yang konsisten: kontrol dan input 12 dp, kartu 12 dp,
/// panel besar 16 dp, objek denah 6-10 dp agar tetap terasa seperti komponen
/// tata ruang. Tombol tidak dipill.
abstract final class AppRadius {
  static const double control = 14;
  static const double controlCompact = 10;
  static const double controlExpanded = 16;

  static const double fixture = 10;
  static const double fixtureCompact = 8;
  static const double fixtureExpanded = 12;

  /// Kartu daftar, kartu produk, dan modul aksi (rounded-2xl).
  static const double card = 16;
  static const double cardLarge = 20;

  /// Panel hero bento dan kontainer metrik besar (rounded-3xl).
  static const double panel = 24;

  /// Wadah ikon aksi cepat squircle.
  static const double squircle = 14;

  /// Kapsul penuh untuk tombol CTA utama dan filter chips.
  static const double pill = 9999;

  static const BorderRadius controlBorder = BorderRadius.all(
    Radius.circular(control),
  );
  static const BorderRadius controlCompactBorder = BorderRadius.all(
    Radius.circular(controlCompact),
  );
  static const BorderRadius fixtureBorder = BorderRadius.all(
    Radius.circular(fixture),
  );
  static const BorderRadius cardBorder = BorderRadius.all(
    Radius.circular(card),
  );
  static const BorderRadius cardLargeBorder = BorderRadius.all(
    Radius.circular(cardLarge),
  );
  static const BorderRadius panelBorder = BorderRadius.all(
    Radius.circular(panel),
  );
  static const BorderRadius pillBorder = BorderRadius.all(
    Radius.circular(pill),
  );
  static const BorderRadius sheetBorder = BorderRadius.vertical(
    top: Radius.circular(28),
  );
}
