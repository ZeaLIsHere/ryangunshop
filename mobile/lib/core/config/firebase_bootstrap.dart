import 'package:firebase_core/firebase_core.dart';

import '../data/sync/firestore_schema.dart';

/// Penyalaan Firebase yang aman untuk aplikasi offline-first.
///
/// Firebase hanya dinyalakan bila `--dart-define=FIREBASE_ENABLED=true`.
/// Tanpa itu aplikasi tetap berjalan penuh dengan SQLite lokal, sehingga
/// pratinjau web, pengujian widget, dan perangkat tanpa internet tidak
/// terpengaruh.
///
/// Sumber konfigurasi, berurutan:
/// 1. `--dart-define` (atau `--dart-define-from-file=.env`) untuk
///    `FIREBASE_API_KEY`, `FIREBASE_PROJECT_ID`, `FIREBASE_APP_ID`, dan
///    `FIREBASE_MESSAGING_SENDER_ID`.
/// 2. `google-services.json` di Android atau `GoogleService-Info.plist` di iOS
///    bila berkas itu tersedia.
abstract final class FirebaseBootstrap {
  /// Sakelar utama integrasi cloud.
  static const bool enabled = bool.fromEnvironment('FIREBASE_ENABLED');

  /// Cabang data toko yang dipakai, misalnya `toko-utama`.
  static const String storeId = String.fromEnvironment(
    'FIREBASE_STORE_ID',
    defaultValue: FirestoreSchema.defaultStoreId,
  );

  static const String _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const String _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const String _appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const String _senderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const String _storageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
  );
  static const String _authDomain = String.fromEnvironment(
    'FIREBASE_AUTH_DOMAIN',
  );
  static const String _measurementId = String.fromEnvironment(
    'FIREBASE_MEASUREMENT_ID',
  );
  static const String _iosBundleId = String.fromEnvironment(
    'FIREBASE_IOS_BUNDLE_ID',
  );

  static FirebaseApp? _app;
  static Object? _lastError;

  /// Firebase siap dipakai pada sesi ini.
  static bool get isReady => _app != null;

  /// Galat terakhir saat penyalaan, untuk ditampilkan di layar Pengaturan.
  static Object? get lastError => _lastError;

  /// Opsi eksplisit dari `dart-define`. Bernilai `null` bila tidak lengkap,
  /// sehingga Firebase memakai berkas konfigurasi native.
  static FirebaseOptions? get options {
    if (_apiKey.isEmpty || _projectId.isEmpty || _appId.isEmpty) return null;
    return FirebaseOptions(
      apiKey: _apiKey,
      projectId: _projectId,
      appId: _appId,
      messagingSenderId: _senderId,
      storageBucket: _storageBucket,
      authDomain: _authDomain,
      measurementId: _measurementId,
      iosBundleId: _iosBundleId,
    );
  }

  /// Menyalakan Firebase sekali per proses. Tidak pernah melempar galat agar
  /// aplikasi kasir tetap dapat dipakai tanpa jaringan.
  static Future<bool> ensureInitialized() async {
    if (!enabled) return false;
    if (_app != null) return true;
    if (Firebase.apps.isNotEmpty) {
      _app = Firebase.apps.first;
      return true;
    }
    try {
      _app = await Firebase.initializeApp(options: options);
      _lastError = null;
      return true;
    } catch (error) {
      _lastError = error;
      return false;
    }
  }
}
