import 'package:flutter/foundation.dart';

import '../sample/onboarding_sample.dart';

/// Keadaan perkenalan tiga halaman.
class OnboardingViewModel extends ChangeNotifier {
  int _currentIndex = 0;

  /// Indeks halaman yang sedang terlihat.
  int get currentIndex => _currentIndex;

  int get pageCount => OnboardingSample.pages.length;

  /// Apakah halaman terakhir sudah terlihat.
  bool get isLastPage => _currentIndex >= pageCount - 1;

  /// Dipanggil saat halaman berganti, baik lewat tombol maupun geser.
  void onPageChanged(int index) {
    if (index == _currentIndex) {
      return;
    }
    _currentIndex = index;
    notifyListeners();
  }
}
