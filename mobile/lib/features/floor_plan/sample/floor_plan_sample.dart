import '../model/fixture_item.dart';

abstract final class FloorPlanSample {
  static const storeName = 'RyanGunshop - Warung & Kelontong Modern';
  static const storeAddress = 'Jl. Sisingamangaraja No. 45, Medan';

  static const List<FixtureItem> defaultFixtures = [
    // Meja Kasir di dekat pintu masuk (kiri bawah)
    FixtureItem(
      id: 'meja-kasir',
      name: 'Meja Kasir Utama',
      type: FixtureType.cashierDesk,
      x: 0.08,
      y: 0.72,
      width: 0.32,
      height: 0.18,
      zoneId: 'zona-depan',
      productCount: 4,
    ),
    // Lemari Rokok & Obat di belakang meja kasir
    FixtureItem(
      id: 'lemari-rokok',
      name: 'Lemari Khusus',
      type: FixtureType.cabinet,
      x: 0.08,
      y: 0.48,
      width: 0.28,
      height: 0.18,
      zoneId: 'zona-depan',
      productCount: 18,
    ),
    // Rak Sembako (Tengah Kiri)
    FixtureItem(
      id: 'contoh-rak-sembako',
      name: 'Rak Sembako A',
      type: FixtureType.shelf,
      x: 0.44,
      y: 0.15,
      width: 0.24,
      height: 0.32,
      zoneId: 'zona-tengah',
      productCount: 12,
      hasLowStock: true,
    ),
    // Rak Mi & Makanan Ringan (Tengah Kanan)
    FixtureItem(
      id: 'contoh-rak-mi',
      name: 'Rak Makanan B',
      type: FixtureType.shelf,
      x: 0.72,
      y: 0.15,
      width: 0.24,
      height: 0.32,
      zoneId: 'zona-tengah',
      productCount: 24,
    ),
    // Rak Kebutuhan Rumah Tangga (Tengah Bawah)
    FixtureItem(
      id: 'contoh-rak-kebutuhan',
      name: 'Rak Kebutuhan C',
      type: FixtureType.shelf,
      x: 0.44,
      y: 0.56,
      width: 0.24,
      height: 0.26,
      zoneId: 'zona-tengah',
      productCount: 3,
    ),
    // Kulkas Minuman (Pojok Kanan Bawah)
    FixtureItem(
      id: 'contoh-kulkas',
      name: 'Kulkas Minuman',
      type: FixtureType.chiller,
      x: 0.68,
      y: 0.65,
      width: 0.26,
      height: 0.25,
      zoneId: 'zona-belakang',
      productCount: 16,
      hasLowStock: true,
    ),
  ];
}
