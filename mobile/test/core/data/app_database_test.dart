import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ryangunshop/core/data/app_database.dart';

void main() {
  late AppDatabase database;

  setUp(() => database = AppDatabase(NativeDatabase.memory()));
  tearDown(() => database.close());

  test('menyimpan produk dan barcode unik', () async {
    await database.saveProduct(
      ProductsCompanion.insert(
        id: 'p-1',
        barcode: const Value('8990001'),
        name: 'Air Mineral',
        salePrice: 4000,
        stock: 3,
        updatedAt: DateTime(2026, 1, 1),
      ),
    );

    expect((await database.findProductByBarcode('8990001'))!.stock, 3);
  });

  test('checkout menyimpan nota dan mengurangi stok atomik', () async {
    await database.saveProduct(
      ProductsCompanion.insert(
        id: 'p-1',
        barcode: const Value('8990001'),
        name: 'Air Mineral',
        salePrice: 4000,
        stock: 3,
        updatedAt: DateTime(2026, 1, 1),
      ),
    );

    await database.completeCheckout(
      transactionId: 'TRX-0001',
      paymentMethod: 'cash',
      totalAmount: 8000,
      cashReceived: 10000,
      changeAmount: 2000,
      lines: const [
        CheckoutLine(
          productId: 'p-1',
          quantity: 2,
          unitPrice: 4000,
          subtotal: 8000,
        ),
      ],
    );

    expect((await database.select(database.transactions).get()).length, 1);
    expect((await database.select(database.transactionItems).get()).length, 1);
    expect((await database.findProductByBarcode('8990001'))!.stock, 1);
  });

  test('checkout menyimpan diskon yang sesuai jumlah item', () async {
    await database.saveProduct(
      ProductsCompanion.insert(
        id: 'p-1',
        barcode: const Value('8990001'),
        name: 'Air Mineral',
        salePrice: 4000,
        stock: 2,
        updatedAt: DateTime(2026, 1, 1),
      ),
    );
    await database.completeCheckout(
      transactionId: 'TRX-DISKON',
      paymentMethod: 'cash',
      totalAmount: 7000,
      discountAmount: 1000,
      cashReceived: 10000,
      changeAmount: 3000,
      lines: const [
        CheckoutLine(
          productId: 'p-1',
          quantity: 2,
          unitPrice: 4000,
          subtotal: 8000,
        ),
      ],
    );
    final nota = (await database.select(database.transactions).get()).single;
    expect(nota.discountAmount, 1000);
    expect(nota.totalAmount, 7000);
    expect((await database.findProductByBarcode('8990001'))!.stock, 0);
  });

  test('checkout gagal seluruhnya jika stok kurang', () async {
    await database.saveProduct(
      ProductsCompanion.insert(
        id: 'p-1',
        barcode: const Value('8990001'),
        name: 'Air Mineral',
        salePrice: 4000,
        stock: 1,
        updatedAt: DateTime(2026, 1, 1),
      ),
    );

    expect(
      () => database.completeCheckout(
        transactionId: 'TRX-0002',
        paymentMethod: 'cash',
        totalAmount: 8000,
        cashReceived: 8000,
        changeAmount: 0,
        lines: const [
          CheckoutLine(
            productId: 'p-1',
            quantity: 2,
            unitPrice: 4000,
            subtotal: 8000,
          ),
        ],
      ),
      throwsStateError,
    );
    expect((await database.select(database.transactions).get()), isEmpty);
    expect((await database.findProductByBarcode('8990001'))!.stock, 1);
  });

  test('menolak kuantitas negatif, harga palsu, dan nota duplikat', () async {
    await database.saveProduct(
      ProductsCompanion.insert(
        id: 'p-1',
        barcode: const Value('8990001'),
        name: 'Air Mineral',
        salePrice: 4000,
        stock: 3,
        updatedAt: DateTime(2026, 1, 1),
      ),
    );
    Future<void> checkout(List<CheckoutLine> lines, {String id = 'TRX-1'}) =>
        database.completeCheckout(
          transactionId: id,
          paymentMethod: 'cash',
          totalAmount: 4000,
          cashReceived: 5000,
          changeAmount: 1000,
          lines: lines,
        );
    expect(
      () => checkout(const [
        CheckoutLine(
          productId: 'p-1',
          quantity: -1,
          unitPrice: 4000,
          subtotal: -4000,
        ),
      ]),
      throwsArgumentError,
    );
    expect(
      () => database.completeCheckout(
        transactionId: 'TRX-HARGA',
        paymentMethod: 'cash',
        totalAmount: 5000,
        cashReceived: 5000,
        changeAmount: 0,
        lines: const [
          CheckoutLine(
            productId: 'p-1',
            quantity: 1,
            unitPrice: 5000,
            subtotal: 5000,
          ),
        ],
      ),
      throwsStateError,
    );
    expect(
      () => database.completeCheckout(
        transactionId: 'TRX-QRIS',
        paymentMethod: 'qris',
        totalAmount: 4000,
        lines: const [
          CheckoutLine(
            productId: 'p-1',
            quantity: 1,
            unitPrice: 4000,
            subtotal: 4000,
          ),
        ],
      ),
      throwsArgumentError,
    );
    expect(
      () => checkout(const [
        CheckoutLine(
          productId: 'p-1',
          quantity: 1,
          unitPrice: 4000,
          subtotal: 4000,
        ),
        CheckoutLine(
          productId: 'p-1',
          quantity: 1,
          unitPrice: 4000,
          subtotal: 4000,
        ),
      ]),
      throwsArgumentError,
    );
    expect((await database.select(database.transactions).get()), isEmpty);
    expect((await database.findProductByBarcode('8990001'))!.stock, 3);
    const valid = [
      CheckoutLine(
        productId: 'p-1',
        quantity: 1,
        unitPrice: 4000,
        subtotal: 4000,
      ),
    ];
    await checkout(valid);
    expect(() => checkout(valid), throwsA(isA<Exception>()));
    expect((await database.select(database.transactions).get()), hasLength(1));
    expect((await database.findProductByBarcode('8990001'))!.stock, 2);
  });

  test('migrasi dari skema v1 produk saja menjaga stok', () async {
    await database.close();
    final legacy = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw.execute('''
        CREATE TABLE products (
          id TEXT NOT NULL PRIMARY KEY,
          barcode TEXT NOT NULL UNIQUE,
          name TEXT NOT NULL,
          sale_price INTEGER NOT NULL,
          stock INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');
          raw.execute(
            "INSERT INTO products VALUES ('lama', '123', 'Produk lama', 5000, 7, 0)",
          );
          raw.execute('PRAGMA user_version = 1');
        },
      ),
    );
    addTearDown(legacy.close);

    expect((await legacy.findProductByBarcode('123'))?.stock, 7);
    final migrated = (await legacy.listProducts()).single;
    expect(migrated.barcode, '123');
    expect(migrated.category, 'Lainnya');
    expect(await legacy.select(legacy.transactions).get(), isEmpty);
    expect(await legacy.select(legacy.transactionItems).get(), isEmpty);
    await legacy.completeCheckout(
      transactionId: 'TRX-MIGRASI',
      paymentMethod: 'cash',
      totalAmount: 5000,
      cashReceived: 5000,
      changeAmount: 0,
      lines: const [
        CheckoutLine(
          productId: 'lama',
          quantity: 1,
          unitPrice: 5000,
          subtotal: 5000,
        ),
      ],
    );
    expect(
      (await legacy.select(legacy.transactions).get()).single.discountAmount,
      0,
    );
  });

  test('migrasi dari skema v2 menjaga nota lama dan menambah diskon', () async {
    await database.close();
    final legacy = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw.execute('''CREATE TABLE products (
        id TEXT NOT NULL PRIMARY KEY, barcode TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL, sale_price INTEGER NOT NULL,
        stock INTEGER NOT NULL, updated_at INTEGER NOT NULL)''');
          raw.execute('''CREATE TABLE transactions (
        id TEXT NOT NULL PRIMARY KEY, created_at INTEGER NOT NULL,
        total_amount INTEGER NOT NULL, payment_method TEXT NOT NULL,
        cash_received INTEGER NULL, change_amount INTEGER NULL)''');
          raw.execute('''CREATE TABLE transaction_items (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        transaction_id TEXT NOT NULL, product_id TEXT NOT NULL,
        product_name TEXT NOT NULL, quantity INTEGER NOT NULL,
        unit_price INTEGER NOT NULL, subtotal INTEGER NOT NULL)''');
          raw.execute(
            "INSERT INTO transactions VALUES ('TRX-LAMA', 0, 5000, 'cash', 5000, 0)",
          );
          raw.execute('PRAGMA user_version = 2');
        },
      ),
    );
    addTearDown(legacy.close);
    final notes = await legacy.select(legacy.transactions).get();
    expect(notes.single.id, 'TRX-LAMA');
    expect(notes.single.discountAmount, 0);
  });

  test('migrasi dari skema v3 menjaga produk dan nota tunai', () async {
    await database.close();
    final legacy = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw.execute('''CREATE TABLE products (
        id TEXT NOT NULL PRIMARY KEY, barcode TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL, sale_price INTEGER NOT NULL,
        stock INTEGER NOT NULL, updated_at INTEGER NOT NULL)''');
          raw.execute('''CREATE TABLE transactions (
        id TEXT NOT NULL PRIMARY KEY, created_at INTEGER NOT NULL,
        total_amount INTEGER NOT NULL, discount_amount INTEGER NOT NULL DEFAULT 0,
        payment_method TEXT NOT NULL, cash_received INTEGER NULL,
        change_amount INTEGER NULL)''');
          raw.execute('''CREATE TABLE transaction_items (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        transaction_id TEXT NOT NULL, product_id TEXT NOT NULL,
        product_name TEXT NOT NULL, quantity INTEGER NOT NULL,
        unit_price INTEGER NOT NULL, subtotal INTEGER NOT NULL)''');
          raw.execute(
            "INSERT INTO products VALUES ('lama', '123', 'Produk lama', 5000, 7, 0)",
          );
          raw.execute(
            "INSERT INTO transactions VALUES ('TRX-LAMA', 0, 4500, 500, 'cash', 5000, 500)",
          );
          raw.execute('PRAGMA user_version = 3');
        },
      ),
    );
    addTearDown(legacy.close);

    final product = (await legacy.listProducts()).single;
    expect(product.stock, 7);
    expect(product.barcode, '123');
    expect(product.category, 'Lainnya');
    expect(
      (await legacy.select(legacy.transactions).get()).single.discountAmount,
      500,
    );
    await legacy.saveProduct(
      ProductsCompanion.insert(
        id: 'tanpa-barcode',
        name: 'Produk baru',
        salePrice: 3000,
        stock: 1,
        updatedAt: DateTime.now(),
      ),
    );
    expect((await legacy.listProducts()).last.barcode, isNull);
  });

  test(
    'produk dan nota tetap ada setelah database file dibuka ulang',
    () async {
      await database.close();
      final folder = await Directory.systemTemp.createTemp('ryangunshop_db_');
      addTearDown(() => folder.delete(recursive: true));
      final file = File('${folder.path}${Platform.pathSeparator}kasir.sqlite');
      final first = AppDatabase(NativeDatabase(file));
      await first.saveProduct(
        ProductsCompanion.insert(
          id: 'produk-file',
          name: 'Susu kotak',
          salePrice: 6000,
          stock: 2,
          updatedAt: DateTime.now(),
        ),
      );
      await first.completeCheckout(
        transactionId: 'TRX-FILE',
        paymentMethod: 'cash',
        totalAmount: 6000,
        cashReceived: 6000,
        changeAmount: 0,
        lines: const [
          CheckoutLine(
            productId: 'produk-file',
            quantity: 1,
            unitPrice: 6000,
            subtotal: 6000,
          ),
        ],
      );
      await first.close();

      final reopened = AppDatabase(NativeDatabase(file));
      addTearDown(reopened.close);
      expect((await reopened.listProducts()).single.stock, 1);
      expect(
        (await reopened.select(reopened.transactions).get()).single.id,
        'TRX-FILE',
      );
    },
  );
}
