/// Konfigurasi lingkungan aplikasi RyanGunshop.
///
/// Menyimpan kunci API Groq dari:
/// 1. `--dart-define=GROQ_API_KEY=gsk_...` atau `--dart-define-from-file=.env`
/// 2. Input manual saat runtime lewat [setRuntimeApiKey]
/// 3. Variabel [hardcodedApiKey] di bawah ini untuk pengujian lokal langsung
abstract final class AppEnv {
  /// Model Groq bawaan bila `GROQ_MODEL` tidak diatur.
  static const String defaultGroqModel = 'openai/gpt-oss-120b';

  /// Kunci API yang di-hardcode langsung untuk uji lokal.
  static String hardcodedApiKey = '';

  /// Kunci yang dibaca saat kompilasi lewat `String.fromEnvironment`.
  static const String _compileTimeKey = String.fromEnvironment(
    'GROQ_API_KEY',
    defaultValue: '',
  );

  /// Model yang dibaca saat kompilasi lewat `String.fromEnvironment`.
  static const String _compileTimeModel = String.fromEnvironment(
    'GROQ_MODEL',
    defaultValue: '',
  );

  /// Kunci aktif sesi berjalan (dapat diubah saat runtime lewat dialog UI).
  static String? _runtimeApiKey;

  /// Mengambil kunci API aktif dengan prioritas:
  /// 1. Kunci runtime (yang diinput via dialog Chatbot)
  /// 2. Kunci hardcoded lokal
  /// 3. Kunci dari `--dart-define` / `.env`
  static String get groqApiKey {
    if (_runtimeApiKey != null && _runtimeApiKey!.trim().isNotEmpty) {
      return _runtimeApiKey!.trim();
    }
    if (hardcodedApiKey.trim().isNotEmpty) {
      return hardcodedApiKey.trim();
    }
    return _compileTimeKey.trim();
  }

  /// Menentukan apakah integrasi Groq siap dipakai.
  static bool get hasGroqKey => groqApiKey.isNotEmpty;

  /// Model Groq aktif; dapat diganti lewat `--dart-define=GROQ_MODEL=...`.
  static String get groqModel {
    final model = _compileTimeModel.trim();
    return model.isEmpty ? defaultGroqModel : model;
  }

  /// Memperbarui kunci API sesi berjalan dari dialog UI.
  static void setRuntimeApiKey(String key) {
    _runtimeApiKey = key.trim();
  }

  /// Menghapus kunci sesi berjalan.
  static void clearRuntimeApiKey() {
    _runtimeApiKey = null;
  }
}
