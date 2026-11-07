import 'package:flutter/material.dart';

/// Token tipografi RyanGunshop (Plus Jakarta Sans / Modern Geometric Sans).
///
/// Hierarki modern geometris dengan Plus Jakarta Sans untuk seluruh tampilan POS,
/// dengan tracking negatif rapat pada display & headline, serta tabular figures
/// pada nominal rupiah dan kuantitas barang.
abstract final class AppTypography {
  static const String primaryFontFamily = 'Plus Jakarta Sans';
  static const List<String> fontFallbacks = <String>['sans-serif'];

  static const double displayHeroSize = 32;
  static const double pageTitleSize = 28;
  static const double sectionTitleSize = 20;
  static const double labelSize = 16;
  static const double bodySize = 14;
  static const double captionSize = 12;

  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semibold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;

  /// Keluarga serif sistem untuk aksen editorial pada angka total.
  static const String serifFamily = 'serif';

  /// Angka rata lebar agar kolom nominal dan kuantitas tidak bergeser.
  static const List<FontFeature> tabularFigures = <FontFeature>[
    FontFeature.tabularFigures(),
  ];

  /// Skala teks yang dipakai aplikasi.
  static TextTheme textTheme({required Color ink, required Color muted}) {
    return const TextTheme().copyWith(
      // Judul hero omzet / saldo.
      displayMedium: TextStyle(
        fontFamily: primaryFontFamily,
        fontFamilyFallback: fontFallbacks,
        fontSize: displayHeroSize,
        fontWeight: bold,
        color: ink,
        height: 1.12,
        letterSpacing: -0.64,
        fontFeatures: tabularFigures,
      ),
      // Judul halaman.
      displaySmall: TextStyle(
        fontFamily: primaryFontFamily,
        fontFamilyFallback: fontFallbacks,
        fontSize: pageTitleSize,
        fontWeight: bold,
        color: ink,
        height: 1.14,
        letterSpacing: -0.6,
      ),
      // Judul halaman untuk layar yang memakai headlineMedium.
      headlineMedium: TextStyle(
        fontFamily: primaryFontFamily,
        fontFamilyFallback: fontFallbacks,
        fontSize: pageTitleSize,
        fontWeight: bold,
        color: ink,
        height: 1.14,
        letterSpacing: -1.0,
      ),
      // Judul bagian.
      headlineSmall: TextStyle(
        fontFamily: primaryFontFamily,
        fontFamilyFallback: fontFallbacks,
        fontSize: sectionTitleSize,
        fontWeight: semibold,
        color: ink,
        height: 1.2,
        letterSpacing: -0.4,
      ),
      // Angka ringkasan dan judul kartu besar.
      titleLarge: TextStyle(
        fontFamily: primaryFontFamily,
        fontFamilyFallback: fontFallbacks,
        fontSize: 22,
        fontWeight: semibold,
        color: ink,
        height: 1.2,
        letterSpacing: -0.4,
        fontFeatures: tabularFigures,
      ),
      // Label penting.
      titleMedium: TextStyle(
        fontFamily: primaryFontFamily,
        fontFamilyFallback: fontFallbacks,
        fontSize: labelSize,
        fontWeight: semibold,
        color: ink,
        height: 1.3,
        letterSpacing: -0.15,
      ),
      titleSmall: TextStyle(
        fontFamily: primaryFontFamily,
        fontFamilyFallback: fontFallbacks,
        fontSize: bodySize,
        fontWeight: semibold,
        color: ink,
        height: 1.3,
      ),
      labelLarge: TextStyle(
        fontFamily: primaryFontFamily,
        fontFamilyFallback: fontFallbacks,
        fontSize: bodySize,
        fontWeight: semibold,
        color: ink,
        height: 1.2,
      ),
      bodyLarge: TextStyle(
        fontFamily: primaryFontFamily,
        fontFamilyFallback: fontFallbacks,
        fontSize: 16,
        fontWeight: regular,
        color: ink,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontFamily: primaryFontFamily,
        fontFamilyFallback: fontFallbacks,
        fontSize: bodySize,
        fontWeight: regular,
        color: ink,
        height: 1.5,
      ),
      labelMedium: TextStyle(
        fontFamily: primaryFontFamily,
        fontFamilyFallback: fontFallbacks,
        fontSize: bodySize,
        fontWeight: medium,
        color: muted,
        height: 1.3,
      ),
      // Metadata.
      bodySmall: TextStyle(
        fontFamily: primaryFontFamily,
        fontFamilyFallback: fontFallbacks,
        fontSize: captionSize,
        fontWeight: regular,
        color: muted,
        height: 1.45,
      ),
      labelSmall: TextStyle(
        fontFamily: primaryFontFamily,
        fontFamilyFallback: fontFallbacks,
        fontSize: 11,
        fontWeight: medium,
        color: muted,
        height: 1.3,
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
      height: 1.1,
      letterSpacing: -0.5,
      fontFeatures: tabularFigures,
    );
  }
}
