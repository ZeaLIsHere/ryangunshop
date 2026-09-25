import 'package:flutter/material.dart';

/// Token tipografi RyanGunshop.
///
/// Skala mengikuti `DESIGN.md`: 28 sp judul halaman, 20 sp judul bagian, 16 sp
/// label penting, dan 14 sp metadata. Judul halaman dan angka total memakai
/// serif sistem sebagai aksen editorial, sedangkan label, input, tombol, dan
/// metadata tetap memakai sans-serif sistem agar mudah dibaca cepat.
abstract final class AppTypography {
  static const double pageTitleSize = 28;
  static const double sectionTitleSize = 20;
  static const double labelSize = 16;
  static const double bodySize = 14;
  static const double captionSize = 12;

  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semibold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;

  /// Keluarga serif sistem untuk aksen editorial.
  static const String serifFamily = 'serif';

  /// Skala teks yang dipakai aplikasi.
  static TextTheme textTheme({required Color ink, required Color muted}) {
    return TextTheme(
      displaySmall: TextStyle(
        fontSize: pageTitleSize,
        fontWeight: bold,
        fontFamily: serifFamily,
        color: ink,
        height: 1.2,
      ),
      headlineSmall: TextStyle(
        fontSize: sectionTitleSize,
        fontWeight: semibold,
        color: ink,
        height: 1.25,
      ),
      titleMedium: TextStyle(
        fontSize: labelSize,
        fontWeight: semibold,
        color: ink,
        height: 1.3,
      ),
      labelLarge: TextStyle(
        fontSize: labelSize,
        fontWeight: semibold,
        color: ink,
        height: 1.3,
      ),
      bodyMedium: TextStyle(
        fontSize: bodySize,
        fontWeight: regular,
        color: ink,
        height: 1.45,
      ),
      labelMedium: TextStyle(
        fontSize: bodySize,
        fontWeight: medium,
        color: muted,
        height: 1.3,
      ),
      bodySmall: TextStyle(
        fontSize: captionSize,
        fontWeight: regular,
        color: muted,
        height: 1.4,
      ),
    );
  }

  /// Gaya angka total pembayaran, memakai serif sebagai aksen editorial.
  static TextStyle total({
    required Color color,
    double fontSize = pageTitleSize,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: bold,
      fontFamily: serifFamily,
      color: color,
      height: 1.15,
    );
  }
}
