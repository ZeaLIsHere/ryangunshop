import 'package:flutter/widgets.dart';

/// Token radius RyanGunshop.
///
/// Satu sistem radius yang konsisten: kontrol dan input 12 dp, kartu 12 dp,
/// panel besar 16 dp, objek denah 6-10 dp agar tetap terasa seperti komponen
/// tata ruang. Tombol tidak dipill.
abstract final class AppRadius {
  static const double control = 12;
  static const double controlCompact = 10;
  static const double controlExpanded = 14;

  static const double fixture = 8;
  static const double fixtureCompact = 6;
  static const double fixtureExpanded = 10;

  /// Kartu daftar dan ringkasan.
  static const double card = 12;

  /// Panel besar, hero kecil, dan permukaan penuh lebar.
  static const double panel = 16;

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
  static const BorderRadius panelBorder = BorderRadius.all(
    Radius.circular(panel),
  );
  static const BorderRadius sheetBorder = BorderRadius.vertical(
    top: Radius.circular(controlExpanded),
  );
}
