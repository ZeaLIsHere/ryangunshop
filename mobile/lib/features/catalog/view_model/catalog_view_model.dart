import 'package:flutter/foundation.dart';

import '../model/catalog_product.dart';
import '../model/catalog_scenario.dart';
import '../sample/catalog_sample.dart';

/// State UI deterministik untuk pratinjau, tanpa pemuatan layanan nyata.
class CatalogViewModel extends ChangeNotifier {
  CatalogScenario _scenario = CatalogScenario.withData;

  CatalogScenario get scenario => _scenario;

  List<CatalogProduct> get products => switch (_scenario) {
    CatalogScenario.withData ||
    CatalogScenario.offline => CatalogSample.products,
    _ => const <CatalogProduct>[],
  };

  void selectScenario(CatalogScenario scenario) {
    if (_scenario == scenario) return;
    _scenario = scenario;
    notifyListeners();
  }

  void showSampleProducts() => selectScenario(CatalogScenario.withData);
}
