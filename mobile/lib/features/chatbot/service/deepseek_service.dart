import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/env.dart';
import '../../../core/format/rupiah.dart';
import '../../catalog/model/catalog_product.dart';
import '../../catalog/sample/catalog_sample.dart';
import '../../floor_plan/sample/floor_plan_sample.dart';
import '../../statistics/sample/statistics_sample.dart';
import '../model/chat_message.dart';

/// Layanan integrasi DeepSeek Chat API (`deepseek-chat`).
///
/// Menyediakan konteks data warung real-time (katalog produk, stok, harga,
/// lokasi rak denah, omzet hari ini) ke dalam system prompt agar asisten AI
/// dapat menjawab pertanyaan operasional warung secara tepat dan kontekstual.
class DeepSeekService {
  DeepSeekService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String endpoint = 'https://api.deepseek.com/chat/completions';
  static const String defaultModel = 'deepseek-chat';

  /// Membangun system prompt dengan injeksi konteks data warung.
  String _buildSystemPrompt({
    List<CatalogProduct>? products,
    int? todayRevenue,
    int? todayTransactions,
  }) {
    final activeProducts = products ?? CatalogSample.products;
    final productSummary = activeProducts
        .map(
          (p) =>
              '- ${p.name} [Kategori: ${p.category}] | Harga: ${formatRupiah(p.price)} per ${p.unit} | '
              'Stok: ${p.stock} (${p.stockStatus.name}) | Lokasi: ${p.locationLabel}',
        )
        .join('\n');

    final todayStats = StatisticsSample.forPeriod(StatisticsPeriod.today);
    final revenue = todayRevenue ?? todayStats.total;
    final transCount = todayTransactions ?? todayStats.transactions;

    return '''
Nama kamu adalah IyanBoT, asisten toko resmi aplikasi kasir RyanGunshop.
Konteks warung:
- Nama toko: ${FloorPlanSample.storeName}
- Alamat: ${FloorPlanSample.storeAddress}
- Ringkasan omzet hari ini: ${formatRupiah(revenue)} ($transCount transaksi, ${todayStats.itemsSold} item terjual).

Daftar barang warung saat ini:
$productSummary

BATASAN RUANG LINGKUP (MUTLAK & KETAT):
1. Kamu HANYA boleh menjawab pertanyaan seputar toko RyanGunshop: stok barang, harga, lokasi rak/denah, transaksi kasir, atau panduan aplikasi RyanGunshop.
2. DILARANG KERAS melayani permintaan di luar toko RyanGunshop. Jika pengguna meminta kode pemrograman (HTML, CSS, JavaScript, Python, dll), cerita fiksi, esai, tugas sekolah, atau topik umum lain, TOLAK DENGAN TEGAS DAN SINGKAT: "Maaf, saya IyanBoT hanya melayani seputar operasional toko RyanGunshop." Jangan pernah menulis kode program apa pun.
3. DILARANG menggunakan tanda bintang ganda (**) atau format markdown bold/italic apa pun. Selalu tulis dalam teks biasa.
4. DILARANG menggunakan tanda kutip kode (```) atau sintaks kode.
5. DILARANG menggunakan emoji atau emotikon sama sekali (tidak boleh ada simbol wajah, tangan, atau ikon apa pun).
6. Jawaban harus sangat ringkas, sederhana, langsung to the point tanpa basa-basi pembuka atau penutup yang panjang.
''';
  }

  /// Mengirim pesan ke DeepSeek API dan mengembalikan respons teks asisten.
  Future<String> ask({
    required String userMessage,
    required List<ChatMessage> history,
    List<CatalogProduct>? products,
    int? todayRevenue,
    int? todayTransactions,
  }) async {
    final apiKey = AppEnv.deepseekApiKey;
    if (apiKey.isEmpty) {
      throw StateError('Kunci API DeepSeek belum diatur.');
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

    final requestBody = jsonEncode({
      'model': defaultModel,
      'messages': contextMessages,
      'temperature': 0.7,
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
      throw const FormatException('Format respons DeepSeek tidak sesuai.');
    } else {
      final errorBody = response.body;
      throw http.ClientException(
        'Gagal menghubungi DeepSeek (HTTP ${response.statusCode}): $errorBody',
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
