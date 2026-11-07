import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../model/chat_message.dart';
import '../view_model/chatbot_view_model.dart';

/// Layar chatbot asisten toko RyanGunshop.
///
/// Mendukung mode AI nyata (DeepSeek `deepseek-chat`) dengan injeksi data toko,
/// serta mode simulasi lokal otomatis saat kunci API belum diisi atau offline.
class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final ChatbotViewModel _viewModel = ChatbotViewModel();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _send() {
    final text = _inputController.text;
    if (text.trim().isEmpty || _viewModel.isLoading) {
      return;
    }
    _viewModel.send(text);
    _inputController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
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
            // Daftar Pesan Obrolan
            Expanded(
              child: ListenableBuilder(
                listenable: _viewModel,
                builder: (context, _) => ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(AppSpacing.screen),
                  itemCount:
                      _viewModel.messages.length +
                      (_viewModel.isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _viewModel.messages.length &&
                        _viewModel.isLoading) {
                      return const _TypingBubble();
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
                    : 'Tanya stok, harga, atau tata letak…',
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
