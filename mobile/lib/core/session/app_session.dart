import 'package:flutter/widgets.dart';

import 'user_role.dart';

/// Keadaan sesi yang dipakai lintas fitur, misalnya peran pengguna.
///
/// Dipisahkan dari fitur agar denah, pengaturan, dan kasir membaca peran dari satu
/// sumber yang sama.
class AppSession extends ChangeNotifier {
  UserRole _role = UserRole.owner;

  UserRole get role => _role;

  /// Pintasan bagi fitur yang perlu tahu apakah mode edit denah boleh dibuka.
  bool get canEditFloorPlan => _role.canEditFloorPlan;

  void selectRole(UserRole role) {
    if (role == _role) {
      return;
    }
    _role = role;
    notifyListeners();
  }
}

/// Menyediakan [AppSession] untuk seluruh pohon widget.
///
/// Dipasang sekali di akar aplikasi, lalu dibaca dengan
/// `AppSessionScope.of(context)`.
class AppSessionScope extends InheritedNotifier<AppSession> {
  const AppSessionScope({
    required AppSession session,
    required super.child,
    super.key,
  }) : super(notifier: session);

  static AppSession of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppSessionScope>();
    assert(scope != null, 'AppSessionScope belum dipasang di atas widget ini.');
    return scope!.notifier!;
  }
}
