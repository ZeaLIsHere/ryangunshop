import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/env.dart';
import '../../../core/format/rupiah.dart';
import '../../catalog/model/catalog_product.dart';
import '../model/chat_message.dart';

/// Layanan integrasi Groq Chat Completions API.
///
/// Endpoint Groq memakai format yang kompatibel dengan OpenAI Chat Completions.
/// Konteks warung (katalog, stok, harga, dan omzet) hanya berasal dari data
/// yang dioper pemanggil, tanpa fallback ke data contoh.
class GroqService {
  GroqService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String endpoint =
      'https://api.groq.com/openai/v1/chat/completions';

  /// Model yang dipakai bila `GROQ_MODEL` tidak diatur.
  static const String defaultModel = AppEnv.defaultGroqModel;

  /// Membangun system prompt dengan injeksi konteks data warung.
  String _buildSystemPrompt({
    List<CatalogProduct>? products,
    int? todayRevenue,
    int? todayTransactions,
  }) {
    final activeProducts = products ?? const <CatalogProduct>[];
    final productSummary = activeProducts.isEmpty
        ? 'Belum ada produk tersimpan di katalog.'
        : activeProducts
              .map(
                (p) =>
                    '- ${p.name} [Kategori: ${p.category}] | Harga: ${formatRupiah(p.price)} per ${p.unit} | '
                    'Stok: ${p.stock} (${p.stockStatus.name}) | Lokasi: ${p.locationLabel}',
              )
              .join('\n');

    final revenueText = todayRevenue == null
        ? 'belum tersedia'
        : formatRupiah(todayRevenue);
    final transactionText = todayTransactions == null
        ? 'belum tersedia'
        : '$todayTransactions transaksi';

    return '''
Nama kamu adalah IyanBoT, asisten toko resmi aplikasi kasir RyanGunshop.
Konteks warung:
- Omzet hari ini: $revenueText.
- Jumlah transaksi hari ini: $transactionText.

Daftar barang warung saat ini:
$productSummary

BATASAN RUANG LINGKUP (MUTLAK & KETAT):
1. Kamu HANYA boleh menjawab pertanyaan seputar toko RyanGunshop: stok barang, harga, lokasi rak, transaksi kasir, atau panduan aplikasi RyanGunshop.
2. DILARANG KERAS melayani permintaan di luar toko RyanGunshop. Jika pengguna meminta kode pemrograman (HTML, CSS, JavaScript, Python, dll), cerita fiksi, esai, tugas sekolah, atau topik umum lain, TOLAK DENGAN TEGAS DAN SINGKAT: "Maaf, saya IyanBoT hanya melayani seputar operasional toko RyanGunshop." Jangan pernah menulis kode program apa pun.
3. DILARANG menggunakan tanda bintang ganda (**) atau format markdown bold/italic apa pun. Selalu tulis dalam teks biasa.
4. DILARANG menggunakan tanda kutip kode (```) atau sintaks kode.
5. DILARANG menggunakan emoji atau emotikon sama sekali (tidak boleh ada simbol wajah, tangan, atau ikon apa pun).
6. Jawaban harus sangat ringkas, sederhana, langsung to the point tanpa basa-basi pembuka atau penutup yang panjang.
7. Gunakan HANYA data pada konteks di atas. Jika data tidak tersedia, katakan belum tersedia. JANGAN mengarang nama produk, harga, stok, omzet, atau angka apa pun.
''';
  }

  /// Mengirim pesan ke Groq API dan mengembalikan respons teks asisten.
  Future<String> ask({
    required String userMessage,
    required List<ChatMessage> history,
    List<CatalogProduct>? products,
    int? todayRevenue,
    int? todayTransactions,
  }) async {
    final apiKey = AppEnv.groqApiKey;
    if (apiKey.isEmpty) {
      throw StateError('Kunci API Groq belum diatur.');
    }

    final systemPrompt = _buildSystemPrompt(
      products: products,
      todayRevenue: todayRevenue,
      todayTransactions: todayTransactions,
    );

    // Ambil maksimal 6 riwayat percakapan terakhir agar konteks tetap terjaga
    final contextMessages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
    ];

    final recentHistory = history.length > 6
        ? history.sublist(history.length - 6)
        : history;

    for (final msg in recentHistory) {
      contextMessages.add({
        'role': msg.isUser ? 'user' : 'assistant',
        'content': msg.text,
      });
    }

    contextMessages.add({'role': 'user', 'content': userMessage});

    final model = AppEnv.groqModel;
    final requestBody = jsonEncode({
      'model': model,
      'messages': contextMessages,
      'temperature': 0.7,
      'max_tokens': 512,
      if (model.contains('gpt-oss')) 'reasoning_effort': 'low',
      'stream': false,
    });

    final response = await _client
        .post(
          Uri.parse(endpoint),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: requestBody,
        )
        .timeout(const Duration(seconds: 25));

    if (response.statusCode == 200) {
      final decoded =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final choices = decoded['choices'] as List<dynamic>?;
      if (choices != null && choices.isNotEmpty) {
        final firstChoice = choices[0] as Map<String, dynamic>;
        final message = firstChoice['message'] as Map<String, dynamic>?;
        final content = message?['content'] as String?;
        if (content != null && content.trim().isNotEmpty) {
          return _cleanOutput(content);
        }
      }
      throw const FormatException('Format respons Groq tidak sesuai.');
    } else {
      final errorBody = response.body;
      throw http.ClientException(
        'Gagal menghubungi Groq (HTTP ${response.statusCode}): $errorBody',
      );
    }
  }

  void dispose() {
    _client.close();
  }

  static final RegExp _emojiRegex = RegExp(
    r'[\u{1F300}-\u{1FAD6}\u{200D}\u{FE0E}\u{FE0F}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F600}-\u{1F64F}\u{1F680}-\u{1F6FF}\u{1F900}-\u{1F9FF}\u{1FA70}-\u{1FAFF}]',
    unicode: true,
  );

  /// Membersihkan sisa markdown, backtick, dan emoji dari respons.
  static String _cleanOutput(String text) {
    return text
        .replaceAll('```', '')
        .replaceAll('`', '')
        .replaceAll('**', '')
        .replaceAll('__', '')
        .replaceAll('*', '')
        .replaceAll(_emojiRegex, '')
        .replaceAll('—', '-')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .trim();
  }
}
