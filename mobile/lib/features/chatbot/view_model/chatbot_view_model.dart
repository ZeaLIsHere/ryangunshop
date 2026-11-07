import 'package:flutter/foundation.dart';

import '../../../core/config/env.dart';
import '../model/chat_message.dart';
import '../service/deepseek_service.dart';

/// State percakapan chatbot.
///
/// Jika kunci API DeepSeek tersedia (lewat [AppEnv]), pesan dikirim ke model
/// `deepseek-chat` dengan injeksi data toko secara real-time. Jika kunci belum
/// diatur atau koneksi gagal, sistem secara anggun beralih ke simulasi lokal.
class ChatbotViewModel extends ChangeNotifier {
  ChatbotViewModel({DeepSeekService? service})
    : _service = service ?? DeepSeekService() {
    _messages.add(const ChatMessage(text: greeting, isUser: false));
  }

  final DeepSeekService _service;

  static const String greeting =
      'Halo! Saya IyanBoT, asisten toko RyanGunshop. Ada yang bisa dibantu '
      'soal produk, stok, harga, atau kasir?';

  final List<ChatMessage> _messages = <ChatMessage>[];
  bool _isLoading = false;
  String? _lastError;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isEmpty => _messages.isEmpty;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;

  /// Menandakan apakah kunci API DeepSeek aktif dan siap digunakan.
  bool get isAiActive => AppEnv.hasDeepseekKey;

  /// Mengirim pesan ke AI DeepSeek atau fallback ke simulasi lokal.
  Future<void> send(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty || _isLoading) {
      return;
    }

    _messages.add(ChatMessage(text: text, isUser: true));
    _lastError = null;

    if (!isAiActive) {
      // Mode simulasi lokal (cepat, tanpa internet/API key)
      _messages.add(ChatMessage(text: replyFor(text), isUser: false));
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final reply = await _service.ask(
        userMessage: text,
        history: _messages.sublist(0, _messages.length - 1),
      );
      _messages.add(ChatMessage(text: reply, isUser: false));
    } catch (e) {
      _lastError = e.toString();
      final localReply = replyFor(text);
      _messages.add(
        ChatMessage(
          text:
              'Terjadi kendala ke DeepSeek ($e).\n\n'
              'Balasan simulasi lokal:\n$localReply',
          isUser: false,
        ),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Memperbarui API key sesi berjalan di memori.
  void setApiKey(String key) {
    AppEnv.setRuntimeApiKey(key);
    notifyListeners();
  }

  /// Menghapus riwayat obrolan dan kembali ke sapaan awal.
  void clearHistory() {
    _messages.clear();
    _messages.add(const ChatMessage(text: greeting, isUser: false));
    _lastError = null;
    notifyListeners();
  }

  /// Balasan hardcoded berdasarkan kata kunci pada [input].
  @visibleForTesting
  String replyFor(String input) {
    final q = input.toLowerCase();
    bool has(List<String> keys) => keys.any(q.contains);

    if (has(['halo', 'hai', 'assalam', 'pagi', 'siang', 'malam'])) {
      return 'Halo! Saya IyanBoT. Mau cek stok, harga, atau kasir toko?';
    }
    if (has(['stok', 'restok', 'habis', 'menipis'])) {
      return 'Ada 2 produk stok menipis: Minyak goreng 1 liter (3 botol) dan '
          'Air mineral 600 ml (5 botol). Buka Katalog lalu urutkan '
          '"Stok menipis dulu".';
    }
    if (has(['penjualan', 'omzet', 'omset', 'total', 'laba', 'jual'])) {
      return 'Penjualan hari ini Rp 175.000 dari 3 transaksi (data contoh). '
          'Buka halaman Statistik untuk rincian.';
    }
    if (has(['pindai', 'scan', 'barcode', 'kamera'])) {
      return 'Tekan tombol Kasir di tengah navigasi, lalu "Scan". Arahkan '
          'kamera ke barcode, lalu konfirmasi produk.';
    }
    if (has(['qris', 'qr'])) {
      return 'Saat membayar, buka sheet pembayaran lalu pilih '
          '"QRIS Dinamis". QR contoh tampil di kartu QRIS.';
    }
    if (has(['tunai', 'kembalian', 'cash'])) {
      return 'Pilih "Tunai", isi uang diterima atau pakai tombol uang cepat, '
          'lalu kembalian dihitung otomatis.';
    }
    if (has(['beranda', 'home', 'dashboard'])) {
      return 'Tab Beranda menampilkan ringkasan omzet harian, transaksi terbaru, dan aksi cepat operasional warung.';
    }
    if (has(['tambah produk', 'form', 'tambah', 'input produk'])) {
      return 'Buka tab Katalog lalu tekan "Tambah Produk". Isi nama, harga, '
          'stok, dan lokasi rak.';
    }
    if (has(['terima kasih', 'makasih', 'thanks'])) {
      return 'Sama-sama! Semoga harinya lancar.';
    }
    return 'Maaf, saya IyanBoT hanya melayani seputar operasional toko '
        'RyanGunshop seperti stok, harga, dan kasir.';
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
