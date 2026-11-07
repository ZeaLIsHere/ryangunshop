import 'package:flutter/material.dart';

/// Token warna RyanGunshop (Violet Commerce POS).
///
/// Nilai diambil dari `DESIGN.md` dan dijelaskan lebih lengkap pada
/// `docs/COLOR_PALETTE.md`. Widget tidak boleh menulis nilai heksadesimal
/// langsung; gunakan token di kelas ini atau `ColorScheme` dari tema.
abstract final class AppColors {
  /// Tindakan utama, konfirmasi checkout, dan navigasi aktif.
  static const Color primary = Color(0xFF7C3AED);

  /// Gradien hero card, app bar kontras, dan state tekan.
  static const Color primaryDark = Color(0xFF6D28D9);

  /// Pilihan sekunder, latar pill aktif, dan batas chip.
  static const Color primaryLight = Color(0xFFEDE9FE);

  /// Latar wadah ikon aksi cepat (action pods) dan kontainer data ringkas.
  static const Color primarySubtle = Color(0xFFF5F3FF);

  /// Fokus, garis laser scanner, progress bar, dan aksen visual.
  static const Color accent = Color(0xFFA855F7);

  /// Latar aplikasi (ultra-clean tonal violet-white).
  static const Color canvas = Color(0xFFFAF8FE);

  /// Lembar kerja kasir, kartu produk, dan modal sheet.
  static const Color surface = Color(0xFFFFFFFF);

  /// Teks utama, judul halaman, dan angka nominal (Deep Slate-900).
  static const Color ink = Color(0xFF0F172A);

  /// Teks pendukung, kode SKU, dan metadata rak (Slate-500).
  static const Color muted = Color(0xFF64748B);

  /// Garis tepi halus pemisah kartu dan input.
  static const Color borderSubtle = Color(0xFFEDE8F5);

  /// Tersimpan, tersinkron, pembayaran lunas, atau stok aman.
  static const Color success = Color(0xFF10B981);

  /// Stok menipis, peringatan, atau tindakan belum selesai.
  static const Color warning = Color(0xFFF59E0B);

  /// Gagal bayar, gagal sinkron, atau stok habis.
  static const Color error = Color(0xFFEF4444);
}
