import 'package:flutter/widgets.dart';

/// Satu halaman pada perkenalan.
class OnboardingPage {
  const OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    this.assetPath,
  });

  final String title;
  final String description;

  /// Ikon yang dipakai sebagai fallback ilustrasi.
  final IconData icon;

  /// Jalur aset gambar 3D claymorphic.
  final String? assetPath;
}
