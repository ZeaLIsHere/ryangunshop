/// Token jarak RyanGunshop.
///
/// Jarak dasar 4 dp dengan kelipatan lazim 8, 12, 16, 24, dan 32 dp, serta
/// padding layar ponsel 16 dp sesuai `DESIGN.md`.
abstract final class AppSpacing {
  static const double base = 4;
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  /// Padding layar ponsel.
  static const double screen = 16;

  /// Target sentuh minimum sesuai pedoman aksesibilitas.
  static const double minTouchTarget = 48;
}
