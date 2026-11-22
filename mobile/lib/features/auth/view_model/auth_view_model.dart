import 'package:flutter/foundation.dart';

import '../../../core/data/auth_repository.dart';
import '../../../core/session/app_session.dart';
import '../../../core/session/user_role.dart';
import '../model/user_account.dart';

class AuthViewModel extends ChangeNotifier {
  AuthViewModel({required this.session});

  final AppSession session;

  bool _isLoading = false;
  String? _errorMessage;
  UserRole _registerRole = UserRole.owner;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserRole get registerRole => _registerRole;

  void setRegisterRole(UserRole role) {
    if (_registerRole == role) return;
    _registerRole = role;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  Future<UserAccount?> login({
    required String email,
    required String password,
  }) async {
    if (email.trim().isEmpty || password.isEmpty) {
      _errorMessage = 'Email dan password tidak boleh kosong.';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await session.login(email.trim(), password);
      return user;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return null;
    } catch (_) {
      _errorMessage = 'Terjadi kesalahan saat masuk. Silakan coba lagi.';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<UserAccount?> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    String? storeName,
    String? storeAddress,
  }) async {
    final cleanName = name.trim();
    final cleanEmail = email.trim();

    if (cleanName.isEmpty) {
      _errorMessage = 'Nama lengkap wajib diisi.';
      notifyListeners();
      return null;
    }

    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      _errorMessage = 'Format email tidak valid.';
      notifyListeners();
      return null;
    }

    if (password.length < 6) {
      _errorMessage = 'Password minimal 6 karakter.';
      notifyListeners();
      return null;
    }

    if (password != confirmPassword) {
      _errorMessage = 'Konfirmasi password tidak cocok.';
      notifyListeners();
      return null;
    }

    if (_registerRole == UserRole.owner && (storeName == null || storeName.trim().isEmpty)) {
      _errorMessage = 'Nama toko wajib diisi untuk akun Pemilik.';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_registerRole == UserRole.owner) {
        final user = await session.registerOwner(
          name: cleanName,
          email: cleanEmail,
          password: password,
          storeName: storeName!.trim(),
          storeAddress: storeAddress?.trim(),
        );
        return user;
      } else {
        final user = await session.registerCashier(
          name: cleanName,
          email: cleanEmail,
          password: password,
        );
        return user;
      }
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return null;
    } catch (_) {
      _errorMessage = 'Terjadi kesalahan saat pendaftaran. Silakan coba lagi.';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
