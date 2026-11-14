import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ryangunshop/core/config/env.dart';
import 'package:ryangunshop/core/data/product_record.dart';
import 'package:ryangunshop/core/data/product_repository.dart';
import 'package:ryangunshop/core/data/in_memory_product_repository.dart';
import 'package:ryangunshop/core/session/app_session.dart';
import 'package:ryangunshop/core/session/user_role.dart';
import 'package:ryangunshop/core/theme/app_theme.dart';

import 'package:ryangunshop/features/chatbot/service/groq_service.dart';
import 'package:ryangunshop/features/chatbot/view/chatbot_screen.dart';
import 'package:ryangunshop/features/chatbot/view_model/chatbot_view_model.dart';

Map<String, dynamic> productArgs() => {
  'name': 'Teh baru',
  'sale_price': 5000,
  'cost_price': 3000,
  'stock': 10,
  'category': 'Minuman',
  'unit': 'botol',
  'barcode': '123',
};

class FailingProducts extends InMemoryProductRepository {
  bool failRead = false;
  bool failSave = false;
  @override
  Future<List<ProductRecord>> listProducts() async {
    if (failRead) throw StateError('private secret');
    return super.listProducts();
  }

  @override
  Future<void> save(ProductRecord product) async {
    if (failSave) throw StateError('private secret');
    return super.save(product);
  }
}

class TestSession extends AppSession {
  final products = FailingProducts();
  @override
  ProductRepository get productRepository => products;
}

void main() {
  test(
    'error baca bukan kosong, simpan gagal dapat retry dengan ID tetap',
    () async {
      final session = TestSession();
      final vm = ChatbotViewModel()..session = session;
      addTearDown(vm.dispose);
      addTearDown(session.dispose);
      session.products.failRead = true;
      await expectLater(vm.storeSummary(), throwsStateError);
      await vm.send('ringkasan toko');
      expect(vm.lastError, isNotNull);
      expect(vm.messages.last.text, isNot(contains('private secret')));
      session.products.failRead = false;
      await vm.handleTool('prepare_product', productArgs());
      final action = vm.actions.single;
      final id = action.id;
      session.products.failSave = true;
      expect(await vm.confirmAction(action), false);
      expect(action.error, isNot(contains('private secret')));
      session.products.failSave = false;
      expect(await vm.confirmAction(action), true);
      expect((await session.products.listProducts()).single.id, id);
    },
  );
  tearDown(AppEnv.clearRuntimeApiKey);

  test('produk baru lewat chat memakai klarifikasi dan riwayat tool utuh', () async {
    AppEnv.setRuntimeApiKey('test');
    final session = AppSession();
    addTearDown(session.dispose);
    var requests = 0;
    http.Response response(Map<String, dynamic> message) => http.Response(
      jsonEncode({
        'choices': [
          {'message': message},
        ],
      }),
      200,
    );
    final vm = ChatbotViewModel(
      service: GroqService(
        client: MockClient((request) async {
          requests++;
          final messages =
              (jsonDecode(request.body) as Map)['messages'] as List;
          final prompt = messages.first['content'] as String;
          expect(
            prompt,
            contains(
              'Minta nama, harga jual, modal, stok awal, kategori, dan satuan',
            ),
          );
          if (requests == 1) {
            return response({
              'content': 'Berapa harga jual, modal, stok awal, kategori, dan satuannya?',
            });
          }
          if (requests == 2) {
            expect(
              messages.any((m) => m['content'] == 'Tambah produk Teh baru'),
              true,
            );
            expect(
              messages.any(
                (m) =>
                    m['role'] == 'assistant' &&
                    (m['content'] as String? ?? '').contains(
                      'Berapa harga jual',
                    ),
              ),
              true,
            );
            return response({
              'tool_calls': [
                {
                  'id': 'new_product',
                  'type': 'function',
                  'function': {
                    'name': 'prepare_product',
                    'arguments': jsonEncode(productArgs()),
                  },
                },
              ],
            });
          }
          expect(
            messages.any(
              (m) =>
                  m['role'] == 'tool' &&
                  m['tool_call_id'] == 'new_product' &&
                  jsonDecode(m['content'] as String)['saved'] == false,
            ),
            true,
          );
          if (requests == 3) {
            return response({'content': 'Periksa draft produk.'});
          }
          expect(
            messages.any(
              (m) => m['role'] == 'assistant' && m['tool_calls'] != null,
            ),
            true,
          );
          return response({
            'content': 'Barcode 123 ada pada draft, belum tersimpan.',
          });
        }),
      ),
    )..session = session;
    addTearDown(vm.dispose);
    await vm.send('Tambah produk Teh baru');
    expect(vm.actions, isEmpty);
    expect(vm.messages.last.text, contains('modal'));
    await vm.send(
      'Harga jual 5000, modal 3000, stok 10, kategori Minuman, satuan botol, barcode 123',
    );
    expect(vm.actions.single.arguments, productArgs());
    expect(await session.productRepository.listProducts(), isEmpty);
    await vm.send('Apa barcode pada draft tadi?');
    expect(requests, 4);
    expect(await session.productRepository.listProducts(), isEmpty);
    expect(await vm.confirmAction(vm.actions.single), true);
    final saved = (await session.productRepository.listProducts()).single;
    expect(saved.name, 'Teh baru');
    expect(saved.salePrice, 5000);
    expect(saved.costPrice, 3000);
    expect(saved.stock, 10);
    expect(await vm.confirmAction(vm.actions.single), false);
  });

  test(
    'barang terjual tidak dikenal menawarkan tambah tanpa mengarang produk',
    () async {
      AppEnv.setRuntimeApiKey('test');
      final session = AppSession();
      addTearDown(session.dispose);
      var requests = 0;
      final vm = ChatbotViewModel(
        service: GroqService(
          client: MockClient((request) async {
            final messages =
                (jsonDecode(request.body) as Map)['messages'] as List;
            expect(
              messages.first['content'],
              contains('jangan otomatis membuat produk dari laporan penjualan'),
            );
            requests++;
            final message = requests == 1
                ? {
                    'tool_calls': [
                      {
                        'id': 'unknown_sale',
                        'type': 'function',
                        'function': {
                          'name': 'search_products',
                          'arguments': '{"query":"Kopi Senja"}',
                        },
                      },
                    ],
                  }
                : {
                    'content': 'Kopi Senja belum terdaftar. Pemilik dapat memilih Tambah produk. Beri data produk baru dahulu.',
                  };
            if (requests == 2) {
              expect(
                jsonDecode(messages.last['content'] as String)['products'],
                isEmpty,
              );
            }
            return http.Response(
              jsonEncode({
                'choices': [
                  {'message': message},
                ],
              }),
              200,
            );
          }),
        ),
      )..session = session;
      addTearDown(vm.dispose);
      await vm.send('Terjual Kopi Senja 2');
      expect(vm.messages.last.text, contains('Tambah produk'));
      expect(vm.actions, isEmpty);
      expect(await session.productRepository.listProducts(), isEmpty);
      expect(
        await session.transactionRepository.listForDay(DateTime.now()),
        isEmpty,
      );
    },
  );

  testWidgets('shortcut Tambah produk membuka editor tanpa menyimpan', (
    tester,
  ) async {
    final session = AppSession();
    addTearDown(session.dispose);
    final vm = ChatbotViewModel();
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: AppSessionScope(
          session: session,
          child: MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 800),
              textScaler: TextScaler.linear(1.3),
            ),
            child: ChatbotScreen(viewModel: vm),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tambah produk'));
    await tester.pumpAndSettle();
    expect(find.text('Edit draft'), findsOneWidget);
    expect(find.text('Harga jual'), findsOneWidget);
    expect(find.text('Modal (wajib, 0 jika memang gratis)'), findsOneWidget);
    expect(await session.productRepository.listProducts(), isEmpty);
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(vm.actions, isEmpty);
    session.selectRole(UserRole.cashier);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextButton, 'Tambah produk'), findsNothing);
    tester.view.physicalSize = const Size(360, 1200);
    session.selectRole(UserRole.owner);
    await tester.pumpAndSettle();
    await vm.handleTool('prepare_product', productArgs());
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).last, const Offset(0, -600));
    await tester.pumpAndSettle();

    expect(find.text('Konfirmasi simpan lokal'), findsOneWidget);
    session.selectRole(UserRole.cashier);
    await tester.pumpAndSettle();
    expect(find.text('Konfirmasi simpan lokal'), findsNothing);
    expect(find.text('Edit draft'), findsNothing);
    expect(await vm.confirmAction(vm.actions.single), false);
    expect(await session.productRepository.listProducts(), isEmpty);
    expect(tester.takeException(), isNull);
  });

  test('model tidak boleh menyatakan QRIS lunas', () async {
    AppEnv.setRuntimeApiKey('test');
    final vm = ChatbotViewModel(
      service: GroqService(
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {'content': 'Pembayaran QRIS berhasil lunas'},
                },
              ],
            }),
            200,
          ),
        ),
      ),
    );
    addTearDown(vm.dispose);
    await vm.send('status qris');
    expect(vm.messages.last.text, contains('Chat tidak mengonfirmasi'));
  });

  testWidgets(
    'kartu sale mencatat setelah konfirmasi tanpa input tunai ulang',
    (tester) async {
      final session = AppSession();
      addTearDown(session.dispose);
      final vm = ChatbotViewModel()..session = session;
      await session.productRepository.save(
        const ProductRecord(id: 'a', name: 'Teh', salePrice: 5000, stock: 10),
      );
      await vm.handleTool('search_products', {'query': 'Teh'});
      await vm.handleTool('prepare_sale', {
        'items': [
          {'product_id': 'a', 'quantity': 2},
        ],
        'discount': 1000,
      });
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: AppSessionScope(
            session: session,
            child: MediaQuery(
              data: const MediaQueryData(
                size: Size(360, 800),
                textScaler: TextScaler.linear(1.3),
              ),
              child: ChatbotScreen(viewModel: vm),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Catat Transaksi'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text('Catat Transaksi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Catat Transaksi'));
      await tester.pumpAndSettle();
      expect(find.text('Kasir'), findsNothing);
      expect(session.cart.isEmpty, true);
      expect(
        (await session.transactionRepository.listForDay(DateTime.now()))
            .single
            .cashReceived,
        9000,
      );
      expect(tester.takeException(), isNull);
    },
  );
  test('roundtrip tool IDs dan riwayat utuh tanpa katalog', () async {
    AppEnv.setRuntimeApiKey('test');
    var requests = 0;
    final service = GroqService(
      client: MockClient((request) async {
        final body = jsonDecode(request.body) as Map;
        expect(body['parallel_tool_calls'], false);
        expect(request.body, isNot(contains('RAHASIA KATALOG')));
        final messages = body['messages'] as List;
        requests++;
        if (requests == 1) {
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {
                    'role': 'assistant',
                    'content': null,
                    'tool_calls': [
                      {
                        'id': 'call_1',
                        'type': 'function',
                        'function': {
                          'name': 'search_products',
                          'arguments': '{"query":"teh"}',
                        },
                      },
                    ],
                  },
                },
              ],
            }),
            200,
          );
        }
        expect(
          messages.any(
            (m) => m['role'] == 'tool' && m['tool_call_id'] == 'call_1',
          ),
          true,
        );
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {'content': 'Pilih produk.'},
              },
            ],
          }),
          200,
        );
      }),
    );
    addTearDown(service.dispose);
    await service.ask(
      userMessage: 'cari teh',
      history: [],
      onTool: (name, args) async {
        expect(name, 'search_products');
        expect(args['query'], 'teh');
        return {'products': []};
      },
    );
    await service.ask(userMessage: 'lanjut', history: []);
    expect(requests, 3);
  });

  for (final malformed in ['unknown', 'bad_json', 'parallel', 'loop']) {
    test('tool tidak dipercaya: $malformed dibatasi', () async {
      AppEnv.setRuntimeApiKey('test');
      var count = 0;
      var handlers = 0;
      final service = GroqService(
        client: MockClient((request) async {
          count++;
          final call = {
            'id': 'call_$count',
            'type': 'function',
            'function': {
              'name': malformed == 'unknown' ? 'save_sql' : 'search_products',
              'arguments': malformed == 'bad_json' ? '[' : '{"query":"x"}',
            },
          };
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {
                    'tool_calls': malformed == 'parallel'
                        ? [call, call]
                        : [call],
                  },
                },
              ],
            }),
            200,
          );
        }),
      );
      addTearDown(service.dispose);
      await expectLater(
        service.ask(
          userMessage: 'x',
          history: [],
          onTool: (_, _) async {
            handlers++;
            return {};
          },
        ),
        throwsFormatException,
      );
      expect(count, lessThanOrEqualTo(4));
      if (malformed != 'loop') expect(handlers, 0);
    });
  }

  test(
    'produk wajib lengkap, izin ulang, barcode/nama duplikat dan replay',
    () async {
      final session = AppSession();
      final vm = ChatbotViewModel()..session = session;
      addTearDown(vm.dispose);
      addTearDown(session.dispose);
      await expectLater(
        vm.handleTool('prepare_product', {'name': 'Teh'}),
        throwsFormatException,
      );
      await expectLater(
        vm.handleTool('prepare_product', {...productArgs(), 'stock': -1}),
        throwsFormatException,
      );
      await expectLater(
        vm.handleTool('prepare_product', {
          ...productArgs(),
          'unit': 'tidak valid',
        }),
        throwsFormatException,
      );
      session.selectRole(UserRole.cashier);
      await expectLater(
        vm.handleTool('prepare_product', productArgs()),
        throwsFormatException,
      );
      session.selectRole(UserRole.owner);
      await vm.handleTool('prepare_product', productArgs());
      final action = vm.actions.single;
      session.selectRole(UserRole.cashier);
      expect(await vm.confirmAction(action), false);
      expect((await session.productRepository.listProducts()), isEmpty);
      session.selectRole(UserRole.owner);
      final results = await Future.wait([
        vm.confirmAction(action),
        vm.confirmAction(action),
      ]);
      expect(results.where((ok) => ok).length, 1);
      expect(await vm.confirmAction(action), false);
      expect((await session.productRepository.listProducts()).length, 1);
      await expectLater(
        vm.handleTool('prepare_product', {
          ...productArgs(),
          'name': 'Produk lain',
        }),
        throwsFormatException,
      );
      await expectLater(
        vm.handleTool('prepare_product', {...productArgs(), 'barcode': '456'}),
        throwsFormatException,
      );
      expect(action.product!.locationLabel, 'Belum ditentukan');
      expect(action.product!.lowStockThreshold, 5);
    },
  );

  test(
    'penjualan ambigu dipilih, stok segar, total dan keranjang tidak ditimpa',
    () async {
      final session = AppSession();
      final vm = ChatbotViewModel()..session = session;
      addTearDown(vm.dispose);
      addTearDown(session.dispose);
      for (final id in ['a', 'b']) {
        await session.productRepository.save(
          ProductRecord(id: id, name: 'Teh $id', salePrice: 5000, stock: 5),
        );
      }
      await vm.handleTool('search_products', {'query': 'Teh'});
      final args = {
        'items': [
          {'product_id': 'a', 'quantity': 2},
        ],
        'discount': 1000,
        'cash_received': 10000,
      };
      await expectLater(
        vm.handleTool('prepare_sale', args),
        throwsFormatException,
      );
      vm.selectProduct('a');
      await vm.handleTool('prepare_sale', args);
      final action = vm.actions.single;
      expect(action.total, 9000);
      expect(action.change, 1000);
      final results = await Future.wait([
        vm.confirmAction(action),
        vm.confirmAction(action),
      ]);
      expect(results.where((ok) => ok).length, 1);
      expect(session.cart.isEmpty, true);
      expect(await vm.confirmAction(action), false);
      final row = (await session.transactionRepository.listForDay(
        DateTime.now(),
      )).single;
      expect(row.cashReceived, 10000);
      expect(row.changeAmount, 1000);
      expect(row.totalAmount, 9000);
      expect((await session.productRepository.listProducts()).first.stock, 3);
      expect(session.todayRevenue, 9000);
      await vm.handleTool('prepare_sale', args);
      expect(await vm.confirmAction(vm.actions.last), true);
      expect((await session.productRepository.listProducts()).first.stock, 1);
      await expectLater(
        vm.handleTool('prepare_sale', {
          'items': [
            {'product_id': 'a', 'quantity': 0},
          ],
        }),
        throwsFormatException,
      );
      await session.productRepository.save(
        const ProductRecord(id: 'a', name: 'Teh a', salePrice: 6000, stock: 0),
      );
      await expectLater(
        vm.handleTool('prepare_sale', args),
        throwsFormatException,
      );
    },
  );

  test('ringkasan offline baca repository segar bukan sesi', () async {
    final session = AppSession();
    final vm = ChatbotViewModel()..session = session;
    addTearDown(vm.dispose);
    addTearDown(session.dispose);
    expect((await vm.storeSummary())['jumlah_produk'], 0);
    await session.productRepository.save(
      const ProductRecord(id: 'a', name: 'Teh', salePrice: 5000, stock: 2),
    );
    expect(session.lowStockCount, 0);
    final summary = await vm.storeSummary();
    expect(summary['stok_menipis'], 1);
    expect(summary['stok_habis'], 0);
    expect(summary['profil_toko'], 'Belum diatur');
    await vm.send('ringkasan toko');
    expect(vm.lastError, isNull);
    expect(vm.messages.last.text, contains('Data lokal perangkat ini'));
    expect(vm.messages.last.text, isNot(contains('WIB')));
  });

  testWidgets('chat 360 dp skala 1.3 dan formulir lokal', (tester) async {
    final session = AppSession();
    addTearDown(session.dispose);
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: AppSessionScope(
          session: session,
          child: MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 800),
              textScaler: TextScaler.linear(1.3),
            ),
            child: const ChatbotScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ringkasan toko'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Data lokal perangkat ini'), findsOneWidget);
    await tester.tap(find.text('Tambah produk'));
    await tester.pumpAndSettle();
    expect(find.text('Edit draft'), findsOneWidget);
    expect(find.textContaining('Modal (wajib'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
