import '../model/fixture_model.dart';

/// Data contoh untuk pratinjau kanvas denah.
abstract final class FloorPlanSample {
  static const List<FixtureModel> fixtures = [
    FixtureModel(
      id: 'f1',
      name: 'Pintu Masuk',
      type: FixtureType.wall,
      x: 0.4,
      y: 0.95,
      width: 0.2,
      height: 0.05,
    ),
    FixtureModel(
      id: 'f2',
      name: 'Kasir Utama',
      type: FixtureType.checkout,
      x: 0.1,
      y: 0.8,
      width: 0.2,
      height: 0.1,
      productCount: 0,
    ),
    FixtureModel(
      id: 'f3',
      name: 'Rak Minuman',
      type: FixtureType.cooler,
      x: 0.1,
      y: 0.1,
      width: 0.15,
      height: 0.25,
      productCount: 12,
    ),
    FixtureModel(
      id: 'f4',
      name: 'Rak Makanan Ringan',
      type: FixtureType.shelf,
      x: 0.4,
      y: 0.1,
      width: 0.2,
      height: 0.1,
      productCount: 45,
    ),
    FixtureModel(
      id: 'f5',
      name: 'Lorong Utama',
      type: FixtureType.aisle,
      x: 0.35,
      y: 0.2,
      width: 0.3,
      height: 0.7,
    ),
  ];
}
