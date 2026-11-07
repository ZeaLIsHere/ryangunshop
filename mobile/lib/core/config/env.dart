/// Konfigurasi lingkungan aplikasi RyanGunshop.
///
/// Menyimpan kunci API DeepSeek dari:
/// 1. `--dart-define=DEEPSEEK_API_KEY=sk-...` atau `--dart-define-from-file=.env`
/// 2. Input manual di dialog layar Chatbot saat aplikasi berjalan
/// 3. Variabel [hardcodedApiKey] di bawah ini untuk pengujian lokal langsung
abstract final class AppEnv {
  /// Kunci API DeepSeek yang di-hardcode langsung untuk uji lokal.
  /// Anda dapat menempelkan kunci `sk-...` Anda di sini jika ingin cepat.
  static String hardcodedApiKey = '';

  /// Kunci yang dibaca saat kompilasi lewat `String.fromEnvironment`.
  static const String _compileTimeKey = String.fromEnvironment(
    'DEEPSEEK_API_KEY',
    defaultValue: '',
  );

  /// Kunci aktif sesi berjalan (dapat diubah saat runtime lewat dialog UI).
  static String? _runtimeApiKey;

  /// Mengambil kunci API aktif dengan prioritas:
  /// 1. Kunci runtime (yang diinput via dialog Chatbot)
  /// 2. Kunci hardcoded lokal
  /// 3. Kunci dari `--dart-define` / `.env`
  static String get deepseekApiKey {
    if (_runtimeApiKey != null && _runtimeApiKey!.trim().isNotEmpty) {
      return _runtimeApiKey!.trim();
    }
    if (hardcodedApiKey.trim().isNotEmpty) {
      return hardcodedApiKey.trim();
    }
    return _compileTimeKey.trim();
  }

  /// Menentukan apakah integrasi DeepSeek siap dipakai.
  static bool get hasDeepseekKey => deepseekApiKey.isNotEmpty;

  /// Memperbarui kunci API sesi berjalan dari dialog UI.
  static void setRuntimeApiKey(String key) {
    _runtimeApiKey = key.trim();
  }

  /// Menghapus kunci sesi berjalan.
  static void clearRuntimeApiKey() {
    _runtimeApiKey = null;
  }
}
