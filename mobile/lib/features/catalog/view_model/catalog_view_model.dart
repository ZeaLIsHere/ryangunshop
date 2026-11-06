import 'package:flutter/foundation.dart';

import '../model/catalog_product.dart';
import '../model/catalog_scenario.dart';
import '../model/catalog_sort.dart';
import '../sample/catalog_sample.dart';

/// State UI dan interaksi untuk mengelola katalog produk warung.
class CatalogViewModel extends ChangeNotifier {
  CatalogViewModel() : _products = List.of(CatalogSample.products);

  final List<CatalogProduct> _products;
  CatalogScenario _scenario = CatalogScenario.withData;

  String _searchQuery = '';
  String _selectedCategory = CatalogSample.allCategoryLabel;
  bool _filterLowStockOnly = false;
  CatalogSort _sort = CatalogSort.nameAsc;

  CatalogScenario get scenario => _scenario;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  bool get filterLowStockOnly => _filterLowStockOnly;
  CatalogSort get sort => _sort;

  List<CatalogProduct> get products => switch (_scenario) {
    CatalogScenario.withData || CatalogScenario.offline => filteredProducts,
    _ => const <CatalogProduct>[],
  };

  List<CatalogProduct> get allProducts => List.unmodifiable(_products);

  List<CatalogProduct> get filteredProducts {
    final filtered = _products.where((p) {
      if (_selectedCategory != CatalogSample.allCategoryLabel &&
          p.category != _selectedCategory) {
        return false;
      }
      if (_filterLowStockOnly && p.stockStatus != ProductStockStatus.low) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final nameMatch = p.name.toLowerCase().contains(q);
        final barcodeMatch = p.barcode?.toLowerCase().contains(q) ?? false;
        final locMatch = p.locationLabel.toLowerCase().contains(q);
        if (!nameMatch && !barcodeMatch && !locMatch) return false;
      }
      return true;
    }).toList();

    // Urutan utama mengikuti pilihan pengguna; nama A-Z jadi tie-break agar
    // hasil selalu stabil dan tidak berubah antar rebuild.
    filtered.sort((a, b) {
      final primary = switch (_sort) {
        CatalogSort.nameAsc => a.name.toLowerCase().compareTo(
          b.name.toLowerCase(),
        ),
        CatalogSort.category => a.category.toLowerCase().compareTo(
          b.category.toLowerCase(),
        ),
        CatalogSort.stockAsc => a.stock.compareTo(b.stock),
        CatalogSort.priceAsc => a.price.compareTo(b.price),
        CatalogSort.priceDesc => b.price.compareTo(a.price),
        CatalogSort.location => a.locationLabel.toLowerCase().compareTo(
          b.locationLabel.toLowerCase(),
        ),
      };
      if (primary != 0) return primary;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return filtered;
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void toggleLowStockFilter() {
    _filterLowStockOnly = !_filterLowStockOnly;
    notifyListeners();
  }

  void setSort(CatalogSort sort) {
    if (_sort == sort) return;
    _sort = sort;
    notifyListeners();
  }

  void addProduct(CatalogProduct product) {
    _products.insert(0, product);
    notifyListeners();
  }

  void updateProduct(CatalogProduct product) {
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index >= 0) {
      _products[index] = product;
      notifyListeners();
    }
  }

  void selectScenario(CatalogScenario scenario) {
    if (_scenario == scenario) return;
    _scenario = scenario;
    notifyListeners();
  }

  void showSampleProducts() => selectScenario(CatalogScenario.withData);
}
