import 'package:flutter/widgets.dart';

/// Satu halaman pada perkenalan.
class OnboardingPage {
  const OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;

  /// Ikon yang dipakai sebagai ilustrasi geometris sederhana.
  final IconData icon;
}
