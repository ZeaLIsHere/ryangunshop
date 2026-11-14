import 'package:flutter/material.dart';

import '../../../core/session/app_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/format/rupiah.dart';

import '../../checkout/view/cart_checkout_screen.dart';
import '../model/chat_action.dart';
import '../model/chat_message.dart';
import '../view_model/chatbot_view_model.dart';

/// Layar chatbot asisten toko RyanGunshop.
///
/// Tool AI menyiapkan draft; ringkasan dan formulir lokal tetap tanpa internet.
class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({this.viewModel, super.key});
  final ChatbotViewModel? viewModel;

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  late final ChatbotViewModel _viewModel =
      widget.viewModel ?? ChatbotViewModel();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _send() async {
    final text = _inputController.text;
    if (text.trim().isEmpty || _viewModel.isLoading) {
      return;
    }
    _inputController.clear();

    final session = AppSessionScope.maybeOf(context);
    _viewModel.session = session;
    await _viewModel.send(text);
    if (!mounted) return;
    _scrollToBottom();
  }

  void _openCheckout() {
    final session = _viewModel.session;
    if (session == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AppSessionScope(
          session: session,
          child: Scaffold(
            appBar: AppBar(title: const Text('Kasir')),
            body: CartCheckoutScreen(
              transactionRepository: session.transactionRepository,
            ),
          ),
        ),
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    _viewModel.session = AppSessionScope.maybeOf(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/icon/06_chatbot.png',
              width: 26,
              height: 26,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
            const SizedBox(width: AppSpacing.xs),
            const Text('IyanBoT'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Bersihkan Obrolan',
            onPressed: _viewModel.clearHistory,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screen,
              ),
              child: Wrap(
                spacing: AppSpacing.xs,
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      await _viewModel.send('ringkasan toko');
                      if (mounted) _scrollToBottom();
                    },
                    icon: const Icon(Icons.summarize_outlined),
                    label: const Text('Ringkasan toko'),
                  ),
                  if (_viewModel.session?.role.canManageProducts ?? false)
                    TextButton(
                      onPressed: () async {
                        if (!(_viewModel.session?.role.canManageProducts ??
                            false)) {
                          return;
                        }
                        final action = ChatAction(
                          id: 'chat-${DateTime.now().microsecondsSinceEpoch}',
                          kind: 'prepare_product',
                          arguments: {},
                        );
                        final saved = await showDialog<bool>(
                          context: context,
                          builder: (_) => _DraftEditor(
                            action: action,
                            viewModel: _viewModel,
                          ),
                        );
                        if (saved == true && mounted) {
                          _viewModel.actions.add(action);
                          setState(() {});
                        }
                      },
                      child: const Text('Tambah produk'),
                    ),
                  TextButton(
                    onPressed: _viewModel.session == null
                        ? null
                        : _openCheckout,
                    child: const Text('Buka Kasir'),
                  ),
                ],
              ),
            ),
            if (_viewModel.session?.role.canManageProducts ?? false)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                child: Text(
                  'Tambah produk: ketik data saat AI tersambung, atau buka formulir lewat tombol di atas. Khusus pemilik; simpan setelah konfirmasi.',
                ),
              ),
            ListenableBuilder(
              listenable: _viewModel,
              builder: (context, _) => _viewModel.choices.isEmpty
                  ? const SizedBox.shrink()
                  : SizedBox(
                      height: 120,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          for (final p in _viewModel.choices)
                            Padding(
                              padding: const EdgeInsets.all(AppSpacing.xs),
                              child: OutlinedButton(
                                onPressed: () {
                                  _viewModel.selectProduct(p.id);
                                  _inputController.text =
                                      'Pilih produk ID ${p.id}. Jumlah: ';
                                },
                                child: Text(
                                  'Pilih ${p.name}\n${formatRupiah(p.salePrice)} • stok ${p.stock}',
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
            ListenableBuilder(
              listenable: _viewModel,
              builder: (context, _) => _viewModel.lastError == null
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screen,
                      ),
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppColors.error,
                          ),
                          Text(_viewModel.lastError!),
                          TextButton(
                            onPressed: _viewModel.isLoading
                                ? null
                                : () {
                                    final previous = _viewModel.messages
                                        .where((m) => m.isUser)
                                        .lastOrNull;
                                    if (previous != null) {
                                      _viewModel.send(previous.text);
                                    }
                                  },
                            child: const Text('Coba lagi'),
                          ),
                        ],
                      ),
                    ),
            ),
            // Daftar Pesan Obrolan
            Expanded(
              child: ListenableBuilder(
                listenable: _viewModel,
                builder: (context, _) => ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(AppSpacing.screen),
                  itemCount:
                      _viewModel.messages.length +
                      _viewModel.actions.length +
                      (_viewModel.isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index ==
                            _viewModel.messages.length +
                                _viewModel.actions.length &&
                        _viewModel.isLoading) {
                      return const _TypingBubble();
                    }
                    if (index >= _viewModel.messages.length) {
                      final action = _viewModel
                          .actions[index - _viewModel.messages.length];
                      return _ActionCard(action: action, viewModel: _viewModel);
                    }
                    return _ChatBubble(message: _viewModel.messages[index]);
                  },
                ),
              ),
            ),
            // Bar Input
            ListenableBuilder(
              listenable: _viewModel,
              builder: (context, _) => _InputBar(
                controller: _inputController,
                isLoading: _viewModel.isLoading,
                onSend: _send,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.action, required this.viewModel});
  final ChatAction action;
  final ChatbotViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final product = action.kind == 'prepare_product';
    final done = action.state == ChatActionState.success;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              product ? 'Konfirmasi produk baru' : 'Draft penjualan',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (product) ...[
              Text('${action.product?.name ?? action.arguments['name']}'),
              Text(
                'Harga jual: ${formatRupiah(action.product?.salePrice ?? 0)}',
              ),
              Text(
                'Modal: ${action.arguments.containsKey('cost_price') ? formatRupiah(action.arguments['cost_price'] as int) : 'Belum dicatat — wajib diisi'}',
              ),
              Text(
                'Stok: ${action.arguments['stock']} • ${action.arguments['unit']} • ${action.arguments['category']}',
              ),
              const Text('Lokasi: Belum ditentukan • Ambang stok menipis: 5'),
              Text('Barcode: ${action.arguments['barcode'] ?? 'Tidak diisi'}'),
            ] else ...[
              for (var i = 0; i < action.products.length; i++)
                Text(
                  '${action.products[i].name} × ${(action.arguments['items'] as List)[i]['quantity']} @ ${formatRupiah(action.products[i].salePrice)}',
                ),
              Text('Subtotal: ${formatRupiah(action.subtotal)}'),
              Text(
                'Diskon: ${formatRupiah(action.arguments['discount'] as int? ?? 0)}',
              ),
              Text('Total: ${formatRupiah(action.total)}'),
              Text(
                action.arguments['cash_received'] == null
                    ? 'Tunai uang pas'
                    : 'Tunai sesuai nominal yang diberikan',
              ),
              Text(
                'Uang diterima: ${formatRupiah(action.arguments['cash_received'] as int? ?? action.total)} • Kembalian: ${formatRupiah(action.change ?? 0)}',
              ),
              if (!done)
                const Text(
                  'Belum tercatat. Catat Transaksi menyimpan penjualan tunai yang Anda konfirmasi, bukan verifikasi pembayaran gateway atau QRIS.',
                ),
            ],
            if (action.error != null)
              Text(
                action.error!,
                style: const TextStyle(color: AppColors.error),
              ),
            if (done)
              Text(
                product
                    ? 'Tersimpan lokal. Status cloud terpisah, belum dikonfirmasi.'
                    : viewModel.session?.database != null
                    ? 'Transaksi tercatat di perangkat. Status cloud terpisah, belum dikonfirmasi.'
                    : 'Transaksi tercatat sementara di memori. Hilang saat aplikasi ditutup; belum tersimpan di perangkat.',
              ),
            if (action.state == ChatActionState.cancelled)
              const Text('Draft dibatalkan'),
            if (action.state == ChatActionState.saving)
              const LinearProgressIndicator(),
            if (action.editable &&
                (!product ||
                    (AppSessionScope.maybeOf(context)?.role.canManageProducts ??
                        false))) ...[
              TextButton(
                onPressed: () async {
                  await showDialog<bool>(
                    context: context,
                    builder: (_) =>
                        _DraftEditor(action: action, viewModel: viewModel),
                  );
                },
                child: const Text('Edit draft'),
              ),
              FilledButton(
                onPressed: () async {
                  await viewModel.confirmAction(action);
                },
                child: Text(
                  product ? 'Konfirmasi simpan lokal' : 'Catat Transaksi',
                ),
              ),
              TextButton(
                onPressed: () => viewModel.cancelAction(action),
                child: const Text('Batal'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DraftEditor extends StatefulWidget {
  const _DraftEditor({required this.action, required this.viewModel});
  final ChatAction action;
  final ChatbotViewModel viewModel;
  @override
  State<_DraftEditor> createState() => _DraftEditorState();
}

class _DraftEditorState extends State<_DraftEditor> {
  final fields = <String, TextEditingController>{};
  String? error;
  bool busy = false;
  bool get product => widget.action.kind == 'prepare_product';
  @override
  void initState() {
    super.initState();
    final args = widget.action.arguments;
    if (product) {
      for (final key in [
        'name',
        'sale_price',
        'cost_price',
        'stock',
        'category',
        'unit',
        'barcode',
      ]) {
        fields[key] = TextEditingController(text: args[key]?.toString() ?? '');
      }
    } else {
      final items = args['items'] as List;
      for (var i = 0; i < items.length; i++) {
        fields['qty_$i'] = TextEditingController(
          text: items[i]['quantity'].toString(),
        );
      }
      fields['discount'] = TextEditingController(
        text: (args['discount'] ?? 0).toString(),
      );
      fields['cash_received'] = TextEditingController(
        text: args['cash_received']?.toString() ?? '',
      );
    }
  }

  @override
  void dispose() {
    for (final field in fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const labels = {
      'name': 'Nama',
      'sale_price': 'Harga jual',
      'cost_price': 'Modal (wajib, 0 jika memang gratis)',
      'stock': 'Stok awal',
      'category': 'Kategori',
      'unit': 'Satuan',
      'barcode': 'Barcode (opsional)',
      'discount': 'Diskon rupiah',
      'cash_received': 'Uang diterima (kosong = uang pas)',
    };
    return AlertDialog(
      title: const Text('Edit draft'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final entry in fields.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: TextField(
                  controller: entry.value,
                  decoration: InputDecoration(
                    labelText:
                        labels[entry.key] ??
                        'Jumlah ${widget.action.products[int.parse(entry.key.substring(4))].name}',
                  ),
                ),
              ),
            if (product)
              const Text(
                'Lokasi: Belum ditentukan. Ambang stok menipis: 5. Satuan: bungkus, botol, kotak, pcs, kg, sachet, kaleng.',
              ),
            if (error != null)
              Text(error!, style: const TextStyle(color: AppColors.error)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: busy
              ? null
              : () async {
                  setState(() {
                    busy = true;
                    error = null;
                  });
                  final args = <String, dynamic>{};
                  if (product) {
                    for (final entry in fields.entries) {
                      final text = entry.value.text.trim();
                      if (entry.key == 'barcode' && text.isEmpty) continue;
                      args[entry.key] =
                          {
                            'sale_price',
                            'cost_price',
                            'stock',
                          }.contains(entry.key)
                          ? int.tryParse(text)
                          : text;
                    }
                  } else {
                    final items = widget.action.arguments['items'] as List;
                    args['items'] = [
                      for (var i = 0; i < items.length; i++)
                        {
                          'product_id': items[i]['product_id'],
                          'quantity': int.tryParse(
                            fields['qty_$i']!.text.trim(),
                          ),
                        },
                    ];
                    args['discount'] = int.tryParse(
                      fields['discount']!.text.trim(),
                    );
                    if (fields['cash_received']!.text.trim().isNotEmpty) {
                      args['cash_received'] = int.tryParse(
                        fields['cash_received']!.text.trim(),
                      );
                    }
                  }
                  final old = widget.action.arguments;
                  widget.action.arguments = args;
                  try {
                    await widget.viewModel.validateAction(widget.action);
                    widget.viewModel.refreshDraft();
                    if (context.mounted) Navigator.pop(context, true);
                  } catch (e) {
                    widget.action.arguments = old;
                    if (mounted) {
                      setState(() {
                        error = e is FormatException
                            ? e.message
                            : 'Data lokal gagal dimuat. Coba lagi.';
                        busy = false;
                      });
                    }
                  }
                },
          child: const Text('Terapkan draft'),
        ),
      ],
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isUser;
    final maxWidth = MediaQuery.sizeOf(context).width * 0.82;

    final bubble = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      constraints: BoxConstraints(maxWidth: maxWidth),
      decoration: BoxDecoration(
        color: isUser ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(AppRadius.panel),
          topRight: const Radius.circular(AppRadius.panel),
          bottomLeft: Radius.circular(isUser ? AppRadius.panel : 2),
          bottomRight: Radius.circular(isUser ? 2 : AppRadius.panel),
        ),
        border: isUser ? null : Border.all(color: AppColors.primaryLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SelectableText(
        message.text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: isUser ? AppColors.surface : AppColors.ink,
          height: 1.4,
        ),
      ),
    );

    if (isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: bubble,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: AppSpacing.xs, top: 2),
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Image.asset(
                'assets/icon/06_chatbot.png',
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.smart_toy_outlined,
                  size: 16,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
          ),
          Flexible(child: bubble),
        ],
      ),
    );
  }
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppRadius.panel),
            topRight: Radius.circular(AppRadius.panel),
            bottomLeft: Radius.circular(2),
            bottomRight: Radius.circular(AppRadius.panel),
          ),
          border: Border.all(color: AppColors.primaryLight),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: 2,
          ),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final stage = (_controller.value * 3).floor() % 3;
              final dots = switch (stage) {
                0 => '.    ',
                1 => '. .  ',
                _ => '. . .',
              };
              return Text(
                dots,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  fontFamily: 'monospace',
                  color: AppColors.muted,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.isLoading,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.primaryLight)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !isLoading,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: isLoading
                    ? 'Menunggu balasan…'
                    : 'Tambah produk atau catat penjualan…',
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          IconButton.filled(
            icon: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.surface,
                    ),
                  )
                : const Icon(Icons.send_rounded),
            tooltip: 'Kirim',
            onPressed: isLoading ? null : onSend,
          ),
        ],
      ),
    );
  }
}
