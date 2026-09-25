import 'package:flutter/widgets.dart';

/// Token radius RyanGunshop.
///
/// Kontrol dan sheet memakai 10-14 dp, sedangkan objek denah memakai 6-10 dp
/// agar tetap terasa seperti komponen tata ruang.
abstract final class AppRadius {
  static const double control = 12;
  static const double controlCompact = 10;
  static const double controlExpanded = 14;

  static const double fixture = 8;
  static const double fixtureCompact = 6;
  static const double fixtureExpanded = 10;

  static const BorderRadius controlBorder = BorderRadius.all(
    Radius.circular(control),
  );
  static const BorderRadius fixtureBorder = BorderRadius.all(
    Radius.circular(fixture),
  );
  static const BorderRadius sheetBorder = BorderRadius.vertical(
    top: Radius.circular(controlExpanded),
  );
}
