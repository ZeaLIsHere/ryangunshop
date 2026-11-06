import '../../catalog/model/catalog_product.dart';
import '../../catalog/sample/catalog_sample.dart';

/// Data contoh yang dipakai untuk mencoba alur pemindai tanpa kamera.
abstract final class ScannerSample {
  static const List<CatalogProduct> products = CatalogSample.products;
  static const String detectedProductId = 'contoh-produk-4';
  static const double confidence = 0.92;
}
