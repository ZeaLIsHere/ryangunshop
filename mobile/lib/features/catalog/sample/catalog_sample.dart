import '../model/catalog_product.dart';

abstract final class CatalogSample {
  static const products = <CatalogProduct>[
    CatalogProduct(
      id: 'contoh-produk-1',
      name: 'Beras pandan wangi 1 kg',
      price: 16000,
      stock: 12,
      unit: 'bungkus',
      fixtureId: 'contoh-rak-sembako',
      locationLabel: 'Rak sembako',
      barcode: 'CONTOH-001',
    ),
    CatalogProduct(
      id: 'contoh-produk-2',
      name: 'Minyak goreng 1 liter',
      price: 18000,
      stock: 3,
      unit: 'botol',
      fixtureId: 'contoh-rak-sembako',
      locationLabel: 'Rak sembako',
      barcode: 'CONTOH-002',
    ),
    CatalogProduct(
      id: 'contoh-produk-3',
      name: 'Susu cokelat 250 ml',
      price: 6500,
      stock: 0,
      unit: 'kotak',
      fixtureId: 'contoh-kulkas',
      locationLabel: 'Kulkas minuman',
    ),
    CatalogProduct(
      id: 'contoh-produk-4',
      name: 'Mi instan goreng',
      price: 3500,
      stock: 24,
      unit: 'bungkus',
      fixtureId: 'contoh-rak-mi',
      locationLabel: 'Rak mi dan camilan',
    ),
    CatalogProduct(
      id: 'contoh-produk-5',
      name: 'Air mineral 600 ml',
      price: 4000,
      stock: 5,
      unit: 'botol',
      fixtureId: 'contoh-kulkas',
      locationLabel: 'Kulkas minuman',
    ),
  ];
}
