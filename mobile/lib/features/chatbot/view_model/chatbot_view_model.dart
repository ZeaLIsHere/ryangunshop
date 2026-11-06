import 'package:flutter/foundation.dart';

import '../model/chat_message.dart';

/// State percakapan chatbot.
///
/// Balasan masih hardcoded berdasarkan kata kunci; belum ada model bahasa atau
/// layanan eksternal. Setiap balasan harus tetap jelas bahwa ini contoh.
class ChatbotViewModel extends ChangeNotifier {
  ChatbotViewModel() {
    _messages.add(const ChatMessage(text: greeting, isUser: false));
  }

  static const String greeting =
      'Hai! Saya asisten RyanGunshop. Tanya soal stok, penjualan, atau cara '
      'pakai aplikasi ya. Balasan masih contoh.';

  final List<ChatMessage> _messages = <ChatMessage>[];

  List<ChatMessage> get messages => List.unmodifiable(_messages);

  bool get isEmpty => _messages.isEmpty;

  /// Menambah pesan pengguna lalu satu balasan asisten.
  void send(String rawText) {
    final text = rawText.trim();
    if (text.isEmpty) {
      return;
    }
    _messages.add(ChatMessage(text: text, isUser: true));
    _messages.add(ChatMessage(text: replyFor(text), isUser: false));
    notifyListeners();
  }

  /// Balasan hardcoded berdasarkan kata kunci pada [input].
  @visibleForTesting
  String replyFor(String input) {
    final q = input.toLowerCase();
    bool has(List<String> keys) => keys.any(q.contains);

    if (has(['halo', 'hai', 'assalam', 'pagi', 'siang', 'malam'])) {
      return 'Halo! Ada yang bisa dibantu? Coba tanya "stok menipis" atau '
          '"cara pindai".';
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
    if (has(['denah', 'rak', 'layout', 'tata letak'])) {
      return 'Tab Denah menampilkan tata letak warung. Pemilik bisa mengedit: '
          'geser, putar, ubah ukuran, atau duplikat objek.';
    }
    if (has(['tambah produk', 'form', 'tambah', 'input produk'])) {
      return 'Buka tab Katalog lalu tekan "Tambah Produk". Isi nama, harga, '
          'stok, dan lokasi rak.';
    }
    if (has(['terima kasih', 'makasih', 'thanks'])) {
      return 'Sama-sama! Semoga harinya lancar.';
    }
    return 'Maaf, saya belum paham. Balasan masih contoh. Coba tanya soal '
        '"stok", "penjualan", "pindai", atau "qris".';
  }
}
