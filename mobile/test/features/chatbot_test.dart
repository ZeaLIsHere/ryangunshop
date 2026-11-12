import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ryangunshop/core/config/env.dart';
import 'package:ryangunshop/core/theme/app_theme.dart';
import 'package:ryangunshop/features/chatbot/service/groq_service.dart';
import 'package:ryangunshop/features/chatbot/view/chatbot_screen.dart';
import 'package:ryangunshop/features/chatbot/view_model/chatbot_view_model.dart';

void main() {
  tearDown(() {
    AppEnv.clearRuntimeApiKey();
    AppEnv.hardcodedApiKey = '';
  });

  test('panduan lokal tidak memuat data katalog hardcode', () {
    final viewModel = ChatbotViewModel();

    final stockReply = viewModel.replyFor('stok menipis');
    expect(stockReply, contains('Katalog'));
    expect(stockReply, isNot(contains('Minyak goreng')));
    expect(stockReply, isNot(contains('Air mineral')));
    expect(viewModel.replyFor('bagaimana cara pindai?'), contains('Scan'));
    expect(viewModel.replyFor('qris'), contains('QRIS'));
    expect(viewModel.replyFor('berita acak'), contains('IyanBoT'));

    viewModel.dispose();
  });

  test('konfigurasi API key mengaktifkan mode AI', () {
    final viewModel = ChatbotViewModel();
    expect(viewModel.isAiActive, isFalse);

    viewModel.setApiKey('gsk-test-key-12345');
    expect(viewModel.isAiActive, isTrue);
    expect(AppEnv.groqApiKey, 'gsk-test-key-12345');

    viewModel.setApiKey('');
    expect(viewModel.isAiActive, isFalse);

    viewModel.dispose();
  });

  test('GroqService mengirim permintaan ke endpoint Groq', () async {
    AppEnv.setRuntimeApiKey('gsk-test-key-12345');
    late http.Request captured;
    final service = GroqService(
      client: MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {'role': 'assistant', 'content': 'Stok aman.'},
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    addTearDown(service.dispose);

    final reply = await service.ask(userMessage: 'stok', history: const []);

    expect(reply, 'Stok aman.');
    expect(captured.url.toString(), GroqService.endpoint);
    expect(captured.headers['Authorization'], 'Bearer gsk-test-key-12345');

    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(body['model'], AppEnv.groqModel);
    expect(body['stream'], false);
    expect(body['reasoning_effort'], 'low');

    final messages = body['messages'] as List<dynamic>;
    expect((messages.first as Map<String, dynamic>)['role'], 'system');
    expect((messages.last as Map<String, dynamic>)['content'], 'stok');

    final systemPrompt =
        (messages.first as Map<String, dynamic>)['content'] as String;
    expect(systemPrompt, contains('Belum ada produk tersimpan di katalog.'));
    expect(systemPrompt, contains('Omzet hari ini: belum tersedia.'));
    expect(systemPrompt, isNot(contains('Deterjen bubuk')));
    expect(systemPrompt, isNot(contains('Beras pandan')));
  });

  testWidgets('mengirim pesan menampilkan panduan tanpa data contoh', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const ChatbotScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text(ChatbotViewModel.greeting), findsOneWidget);
    expect(find.text('IyanBoT'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'stok');
    await tester.tap(find.byTooltip('Kirim'));
    await tester.pumpAndSettle();

    expect(find.text('stok'), findsOneWidget);
    expect(find.textContaining('Katalog'), findsOneWidget);
    expect(find.textContaining('Minyak goreng'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('layar IyanBoT dapat dibuka dengan API key terkonfigurasi', (
    tester,
  ) async {
    AppEnv.hardcodedApiKey = 'gsk-test-key-12345';
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const ChatbotScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('IyanBoT'), findsOneWidget);
    expect(AppEnv.hasGroqKey, isTrue);
  });
}
