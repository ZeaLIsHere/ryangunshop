import 'package:flutter/material.dart';

/// Token tipografi RyanGunshop.
///
/// Satu suara sans-serif untuk seluruh hierarki agar tampilan tenang dan padat,
/// dengan tracking negatif yang makin rapat saat ukuran naik. Ukuran inti tetap
/// mengikuti `DESIGN.md`: 28 sp judul halaman, 20 sp judul bagian, 16 sp label
/// penting, dan 14 sp metadata. Serif hanya dipakai sebagai aksen editorial pada
/// angka total pembayaran.
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

  /// Keluarga serif sistem untuk aksen editorial pada angka total.
  static const String serifFamily = 'serif';

  /// Angka rata lebar agar kolom nominal dan kuantitas tidak bergeser.
  static const List<FontFeature> tabularFigures = <FontFeature>[
    FontFeature.tabularFigures(),
  ];

  /// Skala teks yang dipakai aplikasi.
  static TextTheme textTheme({required Color ink, required Color muted}) {
    return const TextTheme().copyWith(
      // Judul halaman.
      displaySmall: TextStyle(
        fontSize: pageTitleSize,
        fontWeight: bold,
        color: ink,
        height: 1.14,
        letterSpacing: -0.6,
      ),
      // Judul halaman untuk layar yang memakai headlineMedium.
      headlineMedium: TextStyle(
        fontSize: pageTitleSize,
        fontWeight: bold,
        color: ink,
        height: 1.14,
        letterSpacing: -1.0,
      ),
      // Judul bagian.
      headlineSmall: TextStyle(
        fontSize: sectionTitleSize,
        fontWeight: semibold,
        color: ink,
        height: 1.2,
        letterSpacing: -0.4,
      ),
      // Angka ringkasan dan judul kartu besar.
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: semibold,
        color: ink,
        height: 1.2,
        letterSpacing: -0.4,
        fontFeatures: tabularFigures,
      ),
      // Label penting.
      titleMedium: TextStyle(
        fontSize: labelSize,
        fontWeight: semibold,
        color: ink,
        height: 1.3,
        letterSpacing: -0.15,
      ),
      titleSmall: TextStyle(
        fontSize: bodySize,
        fontWeight: semibold,
        color: ink,
        height: 1.3,
      ),
      labelLarge: TextStyle(
        fontSize: bodySize,
        fontWeight: semibold,
        color: ink,
        height: 1.2,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: regular,
        color: ink,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: bodySize,
        fontWeight: regular,
        color: ink,
        height: 1.5,
      ),
      labelMedium: TextStyle(
        fontSize: bodySize,
        fontWeight: medium,
        color: muted,
        height: 1.3,
      ),
      // Metadata.
      bodySmall: TextStyle(
        fontSize: captionSize,
        fontWeight: regular,
        color: muted,
        height: 1.45,
      ),
      labelSmall: TextStyle(
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
