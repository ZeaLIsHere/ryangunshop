import 'package:flutter/material.dart';

/// Token warna RyanGunshop.
///
/// Nilai diambil dari `DESIGN.md` dan dijelaskan lebih lengkap pada
/// `docs/COLOR_PALETTE.md`. Widget tidak boleh menulis nilai heksadesimal
/// langsung; gunakan token di kelas ini atau `ColorScheme` dari tema.
abstract final class AppColors {
  /// Tindakan utama dan pilihan aktif.
  static const Color primary = Color(0xFF565C9D);

  /// Splash, app bar kontras, dan state tekan.
  static const Color primaryDark = Color(0xFF34385F);

  /// Pilihan sekunder dan latar ikon.
  static const Color primaryLight = Color(0xFFE9EAF6);

  /// Fokus, progress, dan aksen motion.
  static const Color accent = Color(0xFF8B91D4);

  /// Latar aplikasi.
  static const Color canvas = Color(0xFFF7F7FB);

  /// Lembar kerja dan sheet.
  static const Color surface = Color(0xFFFFFFFF);

  /// Teks utama.
  static const Color ink = Color(0xFF191A2E);

  /// Teks pendukung.
  static const Color muted = Color(0xFF62657A);

  /// Tersimpan atau tersinkron.
  static const Color success = Color(0xFF287A66);

  /// Stok menipis atau tindakan belum selesai.
  static const Color warning = Color(0xFFA86616);

  /// Gagal bayar, gagal sinkron, atau stok tidak cukup.
  static const Color error = Color(0xFFB44252);
}
