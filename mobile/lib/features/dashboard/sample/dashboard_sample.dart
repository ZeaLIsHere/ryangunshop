import '../model/dashboard_shortcut.dart';

/// Teks dan pintasan contoh untuk dashboard.
abstract final class DashboardSample {
  static const String mainActionTitle = 'Kasir';
  static const String mainActionDescription =
      'Pindai atau pilih produk, lalu selesaikan pembayaran.';
  static const String mainActionLabel = 'Mulai pindai';

  static const String shortcutsSectionTitle = 'Pintasan';

  static const String floorPlanTitle = 'Denah warung';
  static const String floorPlanUnavailable =
      'Denah belum tersedia pada versi ini.';

  static const List<DashboardShortcut> shortcuts = DashboardShortcut.values;
}
