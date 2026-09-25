import 'package:flutter/foundation.dart';

import '../../../core/session/app_session.dart';
import '../../../core/session/user_role.dart';
import '../model/store_profile.dart';
import '../sample/settings_sample.dart';

/// Keadaan halaman pengaturan.
///
/// Peran dibaca dan diubah lewat [AppSession] supaya denah dan kasir memakai sumber
/// yang sama, bukan salinan sendiri.
class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel({required this.session}) {
    session.addListener(notifyListeners);
  }

  final AppSession session;

  UserRole get selectedRole => session.role;

  bool get canEditFloorPlan => session.canEditFloorPlan;

  List<UserRole> get roleOptions => UserRole.values;

  StoreProfile get storeProfile => SettingsSample.storeProfile;

  void selectRole(UserRole role) => session.selectRole(role);

  @override
  void dispose() {
    session.removeListener(notifyListeners);
    super.dispose();
  }
}
