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

  test(
    'fallback tambah produk mendahului kata stok, jual, barcode, dan sapaan',
    () async {
      final vm = ChatbotViewModel();
      addTearDown(vm.dispose);
      AppEnv.hardcodedApiKey = '';
      AppEnv.clearRuntimeApiKey();
      for (final message in [
        'Halo, tambah produk Kopi Senja harga jual 5000 modal 3000 stok 10 barcode 123',
        'Produk baru Kopi Senja stok 10',
        'Terjual Kopi Senja 2 tetapi belum terdaftar',
      ]) {
        await vm.send(message);
        final reply = vm.messages.last.text;
        expect(reply, contains('"Tambah produk" di obrolan ini'));
        expect(reply, contains('tidak menafsirkan atau menyimpan'));
        expect(reply, contains('modal'));
        expect(reply, contains('kategori'));
        expect(reply, contains('satuan'));
        expect(reply, contains('"Simpan produk"'));
        expect(reply, isNot(contains('Buka tab Katalog')));
        expect(vm.actions, isEmpty);
      }
    },
  );

  test(
    'API gagal tetap menawarkan tambah dalam chat tanpa klaim simpan',
    () async {
      AppEnv.setRuntimeApiKey('test');
      final vm = ChatbotViewModel(
        service: GroqService(
          client: MockClient((_) async => http.Response('private error', 503)),
        ),
      );
      addTearDown(vm.dispose);
      await vm.send('Tambah produk Kopi Senja harga jual 5000 stok 10');
      expect(vm.lastError, isNotNull);
      expect(vm.messages.last.text, contains('"Tambah produk" di obrolan ini'));
      expect(vm.messages.last.text, isNot(contains('private error')));
      expect(vm.actions, isEmpty);
    },
  );

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
    expect(systemPrompt, contains('bukan berarti kosong'));
    expect(body['parallel_tool_calls'], false);
    expect((body['tools'] as List).length, 4);
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

    await tester.scrollUntilVisible(
      find.text('stok'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
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
