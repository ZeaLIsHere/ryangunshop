import 'package:flutter/foundation.dart';

import '../../../core/data/auth_repository.dart';
import '../../../core/session/app_session.dart';
import '../../auth/model/cashier_invitation.dart';
import '../../auth/model/store_member.dart';

class CashierManagementViewModel extends ChangeNotifier {
  CashierManagementViewModel({required this.session});

  final AppSession session;

  List<StoreMember> _members = [];
  List<CashierInvitation> _pendingInvitations = [];
  bool _isLoading = true;
  String? _errorMessage;

  List<StoreMember> get members => _members;
  List<CashierInvitation> get pendingInvitations => _pendingInvitations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String? get storeId => session.currentStore?.id ?? session.currentUser?.activeStoreId;

  Future<void> load() async {
    final sId = storeId;
    if (sId == null) {
      _isLoading = false;
      _errorMessage = 'Toko aktif tidak ditemukan.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        session.authRepository.listStoreMembers(sId),
        session.authRepository.listStoreInvitations(sId),
      ]);
      _members = results[0] as List<StoreMember>;
      final allInv = results[1] as List<CashierInvitation>;
      _pendingInvitations = allInv.where((i) => i.isPending).toList();
    } catch (_) {
      _errorMessage = 'Gagal memuat data kasir. Silakan coba lagi.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> inviteCashier(String email) async {
    final sId = storeId;
    if (sId == null) return false;

    try {
      await session.authRepository.createInvitation(
        storeId: sId,
        cashierEmail: email.trim(),
      );
      await load();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Gagal mengirim undangan.';
      notifyListeners();
      return false;
    }
  }

  Future<void> cancelInvitation(String invitationId) async {
    try {
      await session.authRepository.cancelInvitation(invitationId);
      await load();
    } catch (_) {
      _errorMessage = 'Gagal membatalkan undangan.';
      notifyListeners();
    }
  }

  Future<void> removeMember(String userId) async {
    final sId = storeId;
    if (sId == null) return;

    try {
      await session.authRepository.removeStoreMember(
        storeId: sId,
        memberUserId: userId,
      );
      await load();
    } catch (_) {
      _errorMessage = 'Gagal melepas kasir dari toko.';
      notifyListeners();
    }
  }
}
