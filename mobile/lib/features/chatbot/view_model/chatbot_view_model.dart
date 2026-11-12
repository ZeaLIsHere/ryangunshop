import 'package:flutter/foundation.dart';

import '../../../core/config/env.dart';
import '../../catalog/model/catalog_product.dart';
import '../model/chat_message.dart';
import '../service/groq_service.dart';

/// State percakapan chatbot.
///
/// Jika kunci API Groq tersedia (lewat [AppEnv]), pesan dikirim ke model Groq
/// dengan injeksi data toko secara real-time. Jika kunci belum diatur atau
/// koneksi gagal, sistem secara anggun beralih ke simulasi lokal.
class ChatbotViewModel extends ChangeNotifier {
  ChatbotViewModel({GroqService? service})
    : _service = service ?? GroqService() {
    _messages.add(const ChatMessage(text: greeting, isUser: false));
  }

  final GroqService _service;

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

  /// Menandakan apakah kunci API Groq aktif dan siap digunakan.
  bool get isAiActive => AppEnv.hasGroqKey;

  /// Mengirim pesan ke AI Groq atau fallback ke simulasi lokal.
  Future<void> send(
    String rawText, {
    List<CatalogProduct>? products,
    int? todayRevenue,
    int? todayTransactions,
  }) async {
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
        products: products,
        todayRevenue: todayRevenue,
        todayTransactions: todayTransactions,
      );
      _messages.add(ChatMessage(text: reply, isUser: false));
    } catch (e) {
      _lastError = e.toString();
      final localReply = replyFor(text);
      _messages.add(
        ChatMessage(
          text:
              'Terjadi kendala menghubungi layanan asisten AI ($e).\n\n'
              'Balasan cepat asisten:\n$localReply',
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

  /// Panduan lokal berdasarkan kata kunci pada [input].
  ///
  /// Tidak memuat data bisnis apa pun; angka dan produk hanya boleh berasal
  /// dari repository atau respons AI.
  @visibleForTesting
  String replyFor(String input) {
    final q = input.toLowerCase();
    bool has(List<String> keys) => keys.any(q.contains);

    if (has(['halo', 'hai', 'assalam', 'pagi', 'siang', 'malam'])) {
      return 'Halo! Saya IyanBoT. Mau cek stok, harga, atau kasir toko?';
    }
    if (has(['stok', 'restok', 'habis', 'menipis'])) {
      return 'Buka tab Katalog lalu gunakan filter "Stok menipis" untuk melihat '
          'stok terkini.';
    }
    if (has(['penjualan', 'omzet', 'omset', 'total', 'laba', 'jual'])) {
      return 'Penjualan dan omzet hari ini dapat dipantau langsung di Beranda '
          'atau buka halaman Statistik untuk analisis transaksi.';
    }
    if (has(['pindai', 'scan', 'barcode', 'kamera'])) {
      return 'Tekan tombol Kasir di navigasi, lalu "Scan". Arahkan '
          'kamera ke barcode, lalu konfirmasi produk ke keranjang.';
    }
    if (has(['qris', 'qr'])) {
      return 'Saat membayar, buka sheet pembayaran lalu pilih '
          '"QRIS Dinamis". Minta pelanggan memindai kode QRIS dengan e-wallet/mobile banking.';
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
