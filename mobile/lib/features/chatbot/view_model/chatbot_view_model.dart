import 'package:flutter/foundation.dart';

import '../../../core/config/env.dart';
import '../../../core/data/product_record.dart';
import '../../../core/session/app_session.dart';

import '../../../core/data/app_database.dart' show CheckoutLine;
import '../model/chat_action.dart';
import '../../catalog/model/catalog_product.dart';
import '../model/chat_message.dart';
import '../service/groq_service.dart';

/// State percakapan chatbot.
///
/// Model hanya membaca tool lokal dan menyiapkan draft. Penulisan butuh pengguna.
class ChatbotViewModel extends ChangeNotifier {
  ChatbotViewModel({GroqService? service})
    : _service = service ?? GroqService() {
    _messages.add(const ChatMessage(text: greeting, isUser: false));
  }

  final GroqService _service;
  AppSession? session;
  bool _disposed = false;
  int _operation = 0;
  final List<ChatAction> actions = [];
  final Set<String> _searchedIds = {};
  final Set<String> _ambiguousIds = {};
  final Set<String> _selectedIds = {};
  List<ProductRecord> choices = [];

  void refreshDraft() => _notify();

  void selectProduct(String id) {
    if (!choices.any((p) => p.id == id)) return;
    _selectedIds.add(id);
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  static String _text(Map<String, dynamic> args, String key) {
    final value = args[key];
    if (value is! String || value.trim().isEmpty || value.length > 160) {
      throw FormatException('$key wajib diisi (maksimal 160 karakter).');
    }
    return value.trim();
  }

  static int _number(
    Map<String, dynamic> args,
    String key, {
    int min = 0,
    int max = 1000000000,
  }) {
    final value = args[key];
    if (value is! int || value < min || value > max) {
      throw FormatException('$key harus bilangan bulat $min–$max.');
    }
    return value;
  }

  static void _keys(Map<String, dynamic> args, Set<String> allowed) {
    if (args.keys.any((key) => !allowed.contains(key))) {
      throw const FormatException('Kolom tidak diizinkan.');
    }
  }

  String _summaryText(Map<String, Object?> data) {
    final top = data['terlaris'] as List;
    return 'Ringkasan toko — ${data['waktu_perangkat']} (${data['zona_waktu']})\n'
        '${data['cakupan']}\nProfil toko: ${data['profil_toko']}\n'
        'Penjualan bersih: Rp${data['penjualan_bersih']}\n'
        'Jumlah nota: ${data['jumlah_nota']}\nRata-rata per nota: Rp${data['rata_rata']}\n'
        'Jumlah produk: ${data['jumlah_produk']}\nStok menipis (tidak termasuk habis): ${data['stok_menipis']}\n'
        'Stok habis: ${data['stok_habis']}\n'
        'Terlaris: ${top.isEmpty ? 'Belum ada penjualan hari ini' : top.map((e) => '${(e as Map)['nama']} (${e['jumlah']})').join(', ')}\n'
        'Laba: ${data['laba']}';
  }

  Future<Map<String, Object?>> storeSummary() async {
    final local = session;
    if (local == null) throw StateError('Sesi lokal belum tersedia.');
    final now = DateTime.now().toLocal();
    final products = await local.productRepository.listProducts();
    final transactions = await local.transactionRepository.listForDay(now);
    final net = transactions.fold<int>(0, (sum, row) => sum + row.totalAmount);
    final sold = <String, int>{};
    for (final row in transactions) {
      for (final item in row.items) {
        sold.update(
          item.productName,
          (n) => n + item.quantity,
          ifAbsent: () => item.quantity,
        );
      }
    }
    final top = sold.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return {
      'profil_toko': 'Belum diatur',
      'cakupan': 'Data lokal perangkat ini',
      'waktu_perangkat': now.toIso8601String(),
      'zona_waktu': now.timeZoneName,
      'penjualan_bersih': net,
      'jumlah_nota': transactions.length,
      'rata_rata': transactions.isEmpty ? 0 : net / transactions.length,
      'jumlah_produk': products.length,
      'stok_menipis': products
          .where((p) => p.stock > 0 && p.stock <= p.lowStockThreshold)
          .length,
      'stok_habis': products.where((p) => p.stock == 0).length,
      'terlaris': [
        for (final entry in top.take(5))
          {'nama': entry.key, 'jumlah': entry.value},
      ],
      'laba': 'Belum tersedia; tidak dihitung dari modal yang belum tercatat.',
    };
  }

  Future<Map<String, Object?>> handleTool(
    String name,
    Map<String, dynamic> args,
  ) async {
    if (_disposed) throw StateError('Layar ditutup.');
    final local = session;
    if (local == null) throw StateError('Sesi lokal belum tersedia.');
    if (name == 'get_store_summary') {
      _keys(args, {});
      return storeSummary();
    }
    if (name == 'search_products') {
      _keys(args, {'query'});
      final query = _text(args, 'query').toLowerCase();
      final records = await local.productRepository.listProducts();
      final found = records
          .where(
            (p) => p.name.toLowerCase().contains(query) || p.barcode == query,
          )
          .toList();
      final shown = found.take(8).toList();
      _searchedIds.addAll(shown.map((p) => p.id));
      if (found.length > 1) {
        _ambiguousIds.addAll(shown.map((p) => p.id));
        choices = shown;
        _notify();
      }
      return {
        'products': [
          for (final p in shown)
            {
              'id': p.id,
              'name': p.name,
              'price': p.salePrice,
              'stock': p.stock,
              'unit': p.unit,
              'category': p.category,
            },
        ],
        'more': found.length > shown.length,
        'selection_required': found.length > 1,
      };
    }
    if (name != 'prepare_product' && name != 'prepare_sale') {
      throw const FormatException('Tool tidak diizinkan.');
    }
    // Satu draft per giliran. Respons model lanjutan tidak boleh mereplay aksi.
    final action = ChatAction(
      id: 'chat-${DateTime.now().microsecondsSinceEpoch}-${_operation++}',
      kind: name,
      arguments: Map.of(args),
    );
    await validateAction(action);
    if (_disposed) throw StateError('Layar ditutup.');
    if (actions.length >= 20) {
      throw const FormatException('Batas draft tercapai. Bersihkan obrolan.');
    }
    actions.add(action);
    _notify();
    return {
      'operation_id': action.id,
      'status': 'draft_requires_user_confirmation',
      'total': action.total,
      'saved': false,
      'paid': false,
    };
  }

  Future<void> validateAction(ChatAction action) async {
    final local = session;
    if (local == null) throw StateError('Sesi lokal belum tersedia.');
    final args = action.arguments;
    if (action.kind == 'prepare_product' && !local.role.canManageProducts) {
      throw const FormatException('Hanya pemilik boleh menambah produk.');
    }
    final records = await local.productRepository.listProducts();
    if (action.kind == 'prepare_product') {
      if (!local.role.canManageProducts) {
        throw const FormatException('Hanya pemilik boleh menambah produk.');
      }
      _keys(args, {
        'name',
        'sale_price',
        'cost_price',
        'stock',
        'category',
        'unit',
        'barcode',
      });
      final name = _text(args, 'name');
      final category = _text(args, 'category');
      final unit = _text(args, 'unit');
      if (!{
        'bungkus',
        'botol',
        'kotak',
        'pcs',
        'kg',
        'sachet',
        'kaleng',
      }.contains(unit)) {
        throw const FormatException(
          'Satuan: bungkus, botol, kotak, pcs, kg, sachet, kaleng.',
        );
      }
      final barcode = args['barcode'] == null || args['barcode'] == ''
          ? null
          : _text(args, 'barcode');
      if (records.any(
        (p) => p.id != action.id && barcode != null && p.barcode == barcode,
      )) {
        throw const FormatException(
          'Barcode sudah dipakai. Pilih produk di Katalog; tidak ditimpa.',
        );
      }
      final normalized = name.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
      final similar = records.where((p) {
        final existing = p.name.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
        return p.id != action.id &&
            (existing.contains(normalized) || normalized.contains(existing));
      }).toList();
      if (similar.isNotEmpty) {
        throw FormatException(
          'Nama serupa: ${similar.take(3).map((p) => p.name).join(', ')}. Pilih di Katalog atau ubah nama agar berbeda; tidak ditimpa.',
        );
      }
      action.product = ProductRecord(
        id: action.id,
        name: name,
        salePrice: _number(args, 'sale_price', min: 1),
        costPrice: _number(args, 'cost_price'),
        stock: _number(args, 'stock', max: 1000000),
        category: category,
        unit: unit,
        barcode: barcode,
      );
    } else {
      _keys(args, {'items', 'discount', 'cash_received'});
      final items = args['items'];
      if (items is! List || items.isEmpty || items.length > 20) {
        throw const FormatException('Pilih 1–20 produk.');
      }
      final chosen = <ProductRecord>[];
      final ids = <String>{};
      var subtotal = 0;
      for (final item in items) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException('Barang tidak valid.');
        }
        _keys(item, {'product_id', 'quantity'});
        final id = _text(item, 'product_id');
        if (!ids.add(id) || !_searchedIds.contains(id)) {
          throw const FormatException(
            'Cari dan pilih ID produk dahulu; jangan duplikasi barang.',
          );
        }
        if (_ambiguousIds.contains(id) && !_selectedIds.contains(id)) {
          throw const FormatException(
            'Produk ambigu. Pengguna harus memilih produk pada daftar pilihan.',
          );
        }
        final matches = records.where((p) => p.id == id).toList();
        if (matches.length != 1) {
          throw const FormatException('Produk tidak ditemukan. Cari ulang.');
        }
        final p = matches.single;
        final quantity = _number(item, 'quantity', min: 1, max: 1000000);
        if (p.stock < quantity || p.salePrice <= 0) {
          throw FormatException(
            'Stok atau harga ${p.name} tidak valid. Stok tersedia: ${p.stock}.',
          );
        }
        chosen.add(p);
        subtotal += p.salePrice * quantity;
      }
      final discount = args.containsKey('discount')
          ? _number(args, 'discount')
          : 0;
      if (discount >= subtotal) {
        throw const FormatException('Diskon melebihi subtotal.');
      }
      final cash = args.containsKey('cash_received')
          ? _number(args, 'cash_received')
          : null;
      if (cash != null && cash < subtotal - discount) {
        throw const FormatException('Uang diterima kurang.');
      }
      action.products = chosen;
      action.subtotal = subtotal;
      action.total = subtotal - discount;
      action.change = (cash ?? action.total) - action.total;
    }
  }

  void cancelAction(ChatAction action) {
    if (!action.editable) return;
    action.state = ChatActionState.cancelled;
    _notify();
  }

  Future<bool> confirmAction(ChatAction action) async {
    if (!action.editable || _disposed) return false;
    action.state = ChatActionState.saving;
    action.error = null;
    _notify();
    try {
      final local = session!;
      if (action.kind == 'prepare_sale' &&
          await local.transactionRepository.findById(action.id) != null) {
        action.state = ChatActionState.success;
        await _refreshAfterSale(local, action);
        return true;
      }
      final previousPrices = action.products.map((p) => p.salePrice).toList();
      await validateAction(action);
      if (action.kind == 'prepare_sale' &&
          !listEquals(
            previousPrices,
            action.products.map((p) => p.salePrice).toList(),
          )) {
        throw const FormatException(
          'Harga berubah. Periksa total baru lalu konfirmasi ulang.',
        );
      }
      if (_disposed) return false;
      if (action.kind == 'prepare_product') {
        // Peran dibaca lagi setelah await; perubahan sesi membatalkan izin.
        if (!local.role.canManageProducts) {
          throw const FormatException('Hanya pemilik boleh menyimpan.');
        }
        await local.productRepository.save(action.product!);
      } else {
        await local.flushCartDraft();
        if (_disposed) return false;
        if (!local.isLocalCartReady) {
          throw const FormatException(
            'Keranjang gagal dimuat. Coba lagi di Kasir.',
          );
        }
        if (!local.cart.isEmpty) {
          throw const FormatException(
            'Keranjang aktif. Selesaikan atau batalkan keranjang di Kasir dahulu. Keranjang tidak diubah.',
          );
        }
        // Baca ulang sesudah memuat cart. Tidak ada await antara pemeriksaan dan transfer.
        final pricesBeforeTransfer = action.products
            .map((p) => p.salePrice)
            .toList();
        await validateAction(action);
        if (!listEquals(
          pricesBeforeTransfer,
          action.products.map((p) => p.salePrice).toList(),
        )) {
          throw const FormatException(
            'Harga berubah. Periksa total baru lalu konfirmasi ulang.',
          );
        }
        if (_disposed) return false;
        final cart = local.cart;
        if (!cart.isEmpty) {
          throw const FormatException(
            'Keranjang aktif. Selesaikan atau batalkan keranjang di Kasir dahulu. Keranjang tidak diubah.',
          );
        }
        final lines = <CheckoutLine>[];
        final items = action.arguments['items'] as List;
        for (var i = 0; i < action.products.length; i++) {
          final p = action.products[i];
          final qty = (items[i] as Map)['quantity'] as int;
          lines.add(
            CheckoutLine(
              productId: p.id,
              unitPrice: p.salePrice,
              quantity: qty,
              subtotal: p.salePrice * qty,
            ),
          );
        }
        await local.transactionRepository.checkout(
          transactionId: action.id,
          paymentMethod: 'cash',
          totalAmount: action.total,
          discountAmount: action.arguments['discount'] as int? ?? 0,
          cashReceived:
              action.arguments['cash_received'] as int? ?? action.total,
          changeAmount: action.change,
          clearCartDraft: false,
          lines: lines,
        );
        action.state = ChatActionState.success;
        await _refreshAfterSale(local, action);
        return true;
      }
      action.state = ChatActionState.success;
      return true;
    } on FormatException catch (e) {
      action.error = e.message;
      action.state = ChatActionState.failure;
      return false;
    } catch (_) {
      // Hasil panggilan bisa gagal sesudah commit. Retry tetap memakai ID nota ini.
      if (action.kind == 'prepare_sale') {
        try {
          if (await session!.transactionRepository.findById(action.id) !=
              null) {
            action.state = ChatActionState.success;
            await _refreshAfterSale(session!, action);
            return true;
          }
        } catch (_) {
          // Status belum diketahui; jangan ganti ID saat retry.
        }
      }
      action.error = 'Operasi lokal belum terkonfirmasi. Coba lagi dengan draft ini; jangan buat draft baru.';
      action.state = ChatActionState.failure;
      return false;
    } finally {
      _notify();
    }
  }

  Future<void> _refreshAfterSale(AppSession local, ChatAction action) async {
    try {
      await local.loadLocalSummary();
      final summary = await storeSummary();
      if (!_disposed) {
        _messages.add(ChatMessage(text: _summaryText(summary), isUser: false));
      }
    } catch (_) {
      action.error = 'Nota sudah tercatat. Ringkasan gagal dimuat; buka Ringkasan toko untuk mencoba lagi.';
    }
  }

  static const String greeting =
      'Halo! Saya IyanBoT. Tambah produk baru lewat chat, catat penjualan, '
      'atau cek Ringkasan toko.\n\n'
      'Contoh: Tambah produk Kopi Senja, harga jual 5000, modal 3000, '
      'stok 10, kategori Minuman, satuan sachet. '
      'AI menanyakan data yang kurang. Tanpa AI, tekan Tambah produk. '
      'Simpan hanya setelah konfirmasi pemilik.';

  final List<ChatMessage> _messages = <ChatMessage>[];
  bool _isLoading = false;
  String? _lastError;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isEmpty => _messages.isEmpty;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;

  /// Menandakan apakah kunci API Groq aktif dan siap digunakan.
  bool get isAiActive => AppEnv.hasGroqKey;

  /// Mengirim pesan ke AI Groq atau menampilkan panduan lokal.
  Future<void> send(
    String rawText, {
    List<CatalogProduct>? products,
    int? todayRevenue,
    int? todayTransactions,
  }) async {
    final text = rawText.trim();
    if (_disposed || text.isEmpty || _isLoading) {
      return;
    }

    if (text.length > 2000) {
      _lastError = 'Pesan maksimal 2000 karakter.';
      _notify();
      return;
    }
    if (_messages.length >= 60) {
      _lastError =
          'Batas obrolan tercapai. Bersihkan obrolan untuk melanjutkan.';
      _notify();
      return;
    }
    _messages.add(ChatMessage(text: text, isUser: true));
    _lastError = null;

    if (text.toLowerCase() == 'ringkasan toko' && session != null) {
      _isLoading = true;
      _notify();
      try {
        final data = await storeSummary();
        _messages.add(ChatMessage(text: _summaryText(data), isUser: false));
      } catch (_) {
        _lastError = 'Ringkasan lokal gagal dimuat. Coba lagi.';
        _messages.add(ChatMessage(text: _lastError!, isUser: false));
      } finally {
        _isLoading = false;
        _notify();
      }
      return;
    }
    if (!isAiActive) {
      // Panduan lokal tidak menafsirkan atau menyimpan produk dari teks.
      _messages.add(ChatMessage(text: replyFor(text), isUser: false));
      _notify();
      return;
    }

    _isLoading = true;
    _notify();

    try {
      var prepared = false;
      final actionsBefore = actions.length;
      final reply = await _service.ask(
        userMessage: text,
        history: _messages.sublist(0, _messages.length - 1),
        products: products,
        todayRevenue: todayRevenue,
        todayTransactions: todayTransactions,
        onTool: (name, args) async {
          if (name.startsWith('prepare_')) {
            if (prepared) throw const FormatException('Satu draft per pesan.');
            prepared = true;
          }
          return handleTool(name, args);
        },
      );
      final unsafeClaim = RegExp(
        r'(berhasil|sudah|telah|sukses).{0,40}(bayar|dibayar|lunas|simpan|tersimpan|sinkron)|(pembayaran|qris|transaksi).{0,30}(berhasil|sukses|lunas|paid)',
        caseSensitive: false,
      );
      final safeReply = actions.length > actionsBefore
          ? 'Draft siap diperiksa pada kartu konfirmasi. Belum tersimpan, belum dibayar.'
          : unsafeClaim.hasMatch(reply)
          ? 'Chat tidak mengonfirmasi penyimpanan atau pembayaran. Periksa status lokal di Katalog atau Kasir.'
          : reply;
      _messages.add(ChatMessage(text: safeReply, isUser: false));
    } catch (e) {
      _lastError = 'Layanan AI tidak tersedia. Coba lagi atau gunakan Ringkasan toko, Tambah produk di obrolan ini, dan Kasir.';
      final localReply = replyFor(text);
      _messages.add(
        ChatMessage(
          text:
              '$_lastError\n\n'
              'Balasan cepat asisten:\n$localReply',
          isUser: false,
        ),
      );
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  /// Memperbarui API key sesi berjalan di memori.
  void setApiKey(String key) {
    AppEnv.setRuntimeApiKey(key);
    notifyListeners();
  }

  /// Menghapus riwayat obrolan dan kembali ke sapaan awal.
  void clearHistory() {
    if (_isLoading) return;
    _service.clearHistory();
    _searchedIds.clear();
    _ambiguousIds.clear();
    _selectedIds.clear();
    choices = [];
    for (final action in actions) {
      cancelAction(action);
    }
    actions.clear();
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

    if (has([
      'tambah produk',
      'produk baru',
      'belum terdaftar',
      'tidak terdaftar',
      'tidak ditemukan',
      'belum ada',
      'daftarkan',
      'input produk',
      'form',
      'tambah',
    ])) {
      return 'Panduan lokal tidak menafsirkan atau menyimpan produk dari pesan. '
          'Untuk produk yang belum terdaftar, pemilik dapat menekan "Tambah produk" '
          'di obrolan ini untuk membuka formulir. Isi nama, harga jual, modal '
          '(0 hanya jika memang gratis), stok awal, kategori, dan satuan; barcode opsional. '
          'Tekan "Terapkan draft", periksa kartu, lalu "Simpan produk" untuk konfirmasi. '
          'Barang terjual yang belum terdaftar tidak otomatis dibuat atau dicatat. '
          'Saat AI tersambung, contoh pesan: Tambah produk Kopi Senja, harga jual 5000, '
          'modal 3000, stok 10, kategori Minuman, satuan sachet. '
          'AI akan menanyakan nilai wajib yang belum disebut.';
    }
    if (has(['halo', 'hai', 'assalam', 'pagi', 'siang', 'malam'])) {
      return greeting;
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

    if (has(['terima kasih', 'makasih', 'thanks'])) {
      return 'Sama-sama! Semoga harinya lancar.';
    }
    return 'Maaf, saya IyanBoT hanya melayani seputar operasional toko '
        'RyanGunshop seperti stok, harga, dan kasir.';
  }

  @override
  void dispose() {
    _disposed = true;
    _service.dispose();
    super.dispose();
  }
}
