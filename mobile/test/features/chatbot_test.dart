import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ryangunshop/core/config/env.dart';
import 'package:ryangunshop/core/theme/app_theme.dart';
import 'package:ryangunshop/features/chatbot/view/chatbot_screen.dart';
import 'package:ryangunshop/features/chatbot/view_model/chatbot_view_model.dart';

void main() {
  tearDown(() {
    AppEnv.clearRuntimeApiKey();
    AppEnv.hardcodedApiKey = '';
  });

  test('balasan memakai kata kunci hardcoded saat offline', () {
    final viewModel = ChatbotViewModel();

    expect(viewModel.replyFor('stok menipis'), contains('stok menipis'));
    expect(viewModel.replyFor('bagaimana cara pindai?'), contains('Scan'));
    expect(viewModel.replyFor('qris'), contains('QRIS'));
    expect(viewModel.replyFor('berita acak'), contains('IyanBoT'));

    viewModel.dispose();
  });

  test('konfigurasi API key mengaktifkan mode AI', () {
    final viewModel = ChatbotViewModel();
    expect(viewModel.isAiActive, isFalse);

    viewModel.setApiKey('sk-test-key-12345');
    expect(viewModel.isAiActive, isTrue);
    expect(AppEnv.deepseekApiKey, 'sk-test-key-12345');

    viewModel.setApiKey('');
    expect(viewModel.isAiActive, isFalse);

    viewModel.dispose();
  });

  testWidgets(
    'mengirim pesan menampilkan balasan contoh ketika belum ada key',
    (tester) async {
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
      expect(find.textContaining('Minyak goreng'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('layar IyanBoT dapat dibuka dengan API key terkonfigurasi', (
    tester,
  ) async {
    AppEnv.hardcodedApiKey = 'sk-3f719e4dccd24bb88e4cfbc441575df2';
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const ChatbotScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('IyanBoT'), findsOneWidget);
    expect(AppEnv.hasDeepseekKey, isTrue);
  });
}
