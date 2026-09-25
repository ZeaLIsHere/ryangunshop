import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Logo resmi RyanGunshop untuk splash, app bar, dan identitas aplikasi.
///
/// Berkas logo produksi berada di [defaultAssetPath]. Aset itu belum terdaftar di
/// `pubspec.yaml`, jadi pemanggil mengoper [assetPath] secara eksplisit setelah aset
/// tersedia. Selama belum dioper, komponen memakai penanda sementara memakai token
/// tema agar tampilan tetap konsisten dan build tidak gagal.
class RyanAppLogo extends StatelessWidget {
  const RyanAppLogo({
    this.size = 96,
    this.showWordmark = true,
    this.wordmarkColor,
    this.assetPath,
    super.key,
  });

  /// Jalur aset logo produksi, ditentukan pada tahap aset brand.
  static const String defaultAssetPath = 'assets/branding/ryangunshop_logo.png';

  /// Tinggi logo dalam dp.
  final double size;

  /// Menampilkan wordmark "RyanGunshop" di bawah logo.
  final bool showWordmark;

  /// Warna wordmark; bawaan memakai warna teks utama.
  final Color? wordmarkColor;

  /// Jalur aset logo yang dipakai. Bila kosong, penanda sementara yang ditampilkan.
  final String? assetPath;

  @override
  Widget build(BuildContext context) {
    final logo = _buildLogo();

    if (!showWordmark) {
      return logo;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        logo,
        const SizedBox(height: AppSpacing.sm),
        Text(
          'RyanGunshop',
          style: AppTypography.total(
            color: wordmarkColor ?? AppColors.ink,
            fontSize: AppTypography.sectionTitleSize,
          ),
        ),
      ],
    );
  }

  Widget _buildLogo() {
    final path = assetPath;
    if (path == null) {
      return _TemporaryMark(size: size);
    }
    return Image.asset(
      path,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => _TemporaryMark(size: size),
    );
  }
}

/// Penanda sementara sampai aset logo produksi tersedia.
///
/// Dibentuk dari token tema, bukan tiruan logo resmi.
class _TemporaryMark extends StatelessWidget {
  const _TemporaryMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: AppRadius.controlBorder,
      ),
      child: Icon(
        Icons.storefront_outlined,
        size: size * 0.55,
        color: AppColors.primaryDark,
      ),
    );
  }
}
