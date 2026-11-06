import '../model/dashboard_shortcut.dart';

/// Teks dan pintasan untuk dashboard operasional RyanGunshop.
abstract final class DashboardSample {
  static const String mainActionTitle = 'Kasir & Transaksi';
  static const String mainActionDescription =
      'Pindai barcode atau pilih produk, lalu selesaikan pembayaran.';
  static const String mainActionLabel = 'Mulai pindai';

  static const String shortcutsSectionTitle = 'Pintasan Menu';

  static const String floorPlanTitle = 'Denah Warung 2D & 360°';
  static const String floorPlanUnavailable =
      'Kelola objek dan rak barang langsung dari denah interaktif.';

  static const List<DashboardShortcut> shortcuts = DashboardShortcut.values;
}
