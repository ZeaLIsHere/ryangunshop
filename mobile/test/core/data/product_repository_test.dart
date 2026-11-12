import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ryangunshop/core/data/app_database.dart';
import 'package:ryangunshop/core/data/drift_product_repository.dart';
import 'package:ryangunshop/core/data/in_memory_product_repository.dart';
import 'package:ryangunshop/core/data/product_record.dart';

void main() {
  test('repository lokal dapat mencari dan menyimpan produk', () async {
    final repository = InMemoryProductRepository([
      const ProductRecord(
        id: 'p-1',
        barcode: '8990001',
        name: 'Air Mineral',
        salePrice: 4000,
        stock: 8,
      ),
    ]);

    expect((await repository.findByBarcode('8990001'))?.name, 'Air Mineral');
    await repository.save(
      const ProductRecord(
        id: 'p-1',
        barcode: '8990001',
        name: 'Air Mineral',
        salePrice: 4000,
        stock: 7,
      ),
    );
    expect((await repository.listProducts()).single.stock, 7);
  });

  test('repository Drift menyimpan produk dan menolak stok negatif', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = DriftProductRepository(database);
    const product = ProductRecord(
      id: 'p-2',
      barcode: '8990002',
      name: 'Teh',
      salePrice: 5000,
      stock: 4,
    );
    await repository.save(product);
    expect((await repository.findByBarcode('8990002'))?.stock, 4);
    expect((await repository.listProducts()).single.name, 'Teh');
    await repository.save(product.copyWith(stock: 2));
    expect((await repository.findByBarcode('8990002'))?.stock, 2);
    expect(
      () => repository.save(
        const ProductRecord(
          id: 'p-3',
          barcode: '8990002',
          name: 'Produk lain',
          salePrice: 6000,
          stock: 1,
        ),
      ),
      throwsA(isA<Exception>()),
    );
    expect((await repository.listProducts()), hasLength(1));
    expect(
      () => repository.save(product.copyWith(stock: -1)),
      throwsArgumentError,
    );
    expect((await repository.findByBarcode('8990002'))?.stock, 2);
  });

  test('produk tanpa barcode dan metadata katalog tetap tersimpan', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = DriftProductRepository(database);
    await repository.save(
      const ProductRecord(
        id: 'tanpa-1',
        name: 'Mi instan',
        salePrice: 3500,
        costPrice: 2800,
        stock: 4,
        category: 'Makanan',
        unit: 'bungkus',
        fixtureId: 'rak-mi',
        locationLabel: 'Rak mi',
        lowStockThreshold: 2,
      ),
    );
    await repository.save(
      const ProductRecord(
        id: 'tanpa-2',
        name: 'Air mineral',
        salePrice: 4000,
        stock: 3,
      ),
    );
    final records = await repository.listProducts();
    expect(records, hasLength(2));
    final product = records.singleWhere((item) => item.id == 'tanpa-1');
    expect(product.barcode, isNull);
    expect(product.category, 'Makanan');
    expect(product.locationLabel, 'Rak mi');
    expect(product.lowStockThreshold, 2);
  });

  test('repository dapat menghapus produk dan melakukan seed awal', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = DriftProductRepository(database);

    const p1 = ProductRecord(
      id: 'p-seed-1',
      name: 'Beras',
      salePrice: 15000,
      stock: 10,
    );
    const p2 = ProductRecord(
      id: 'p-seed-2',
      name: 'Minyak',
      salePrice: 18000,
      stock: 5,
    );

    await repository.seedIfEmpty([p1, p2]);
    expect((await repository.listProducts()), hasLength(2));

    // Seed ulang tidak menimpa data yang sudah ada
    await repository.seedIfEmpty([
      const ProductRecord(
        id: 'p-seed-3',
        name: 'Gula',
        salePrice: 12000,
        stock: 4,
      ),
    ]);
    expect((await repository.listProducts()), hasLength(2));

    // Hapus satu produk
    await repository.delete('p-seed-1');
    final afterDelete = await repository.listProducts();
    expect(afterDelete, hasLength(1));
    expect(afterDelete.single.name, 'Minyak');
  });
}
