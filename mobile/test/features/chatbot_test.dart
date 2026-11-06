import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ryangunshop/core/theme/app_theme.dart';
import 'package:ryangunshop/features/chatbot/view/chatbot_screen.dart';
import 'package:ryangunshop/features/chatbot/view_model/chatbot_view_model.dart';

void main() {
  test('balasan memakai kata kunci hardcoded', () {
    final viewModel = ChatbotViewModel();

    expect(viewModel.replyFor('stok menipis'), contains('stok menipis'));
    expect(viewModel.replyFor('bagaimana cara pindai?'), contains('Scan'));
    expect(viewModel.replyFor('qris'), contains('QRIS'));
    expect(viewModel.replyFor('berita acak'), contains('belum paham'));

    viewModel.dispose();
  });

  testWidgets('mengirim pesan menampilkan balasan contoh', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const ChatbotScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text(ChatbotViewModel.greeting), findsOneWidget);
    expect(find.textContaining('hardcoded'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'stok');
    await tester.tap(find.byTooltip('Kirim'));
    await tester.pumpAndSettle();

    expect(find.text('stok'), findsOneWidget);
    expect(find.textContaining('Minyak goreng'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
