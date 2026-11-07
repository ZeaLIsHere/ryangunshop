import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/ryan_app_logo.dart';
import '../../features/catalog/view/product_catalog.dart';
import '../../features/checkout/view/cart_checkout_screen.dart';
import '../../features/dashboard/model/dashboard_shortcut.dart';
import '../../features/dashboard/view/dashboard_screen.dart';
import '../../features/scanner/view/product_scanner_screen.dart';
import '../../features/settings/view/settings_screen.dart';
import '../routing/app_router.dart';
import 'shell_destination.dart';

/// Kerangka utama aplikasi: app bar, isi tab, dan navigasi bawah.
///
/// Navigasi bawah menampilkan Denah (kiri), Kasir sebagai tombol waterdrop di
/// tengah, dan Katalog (kanan). Pengaturan dipindahkan ke app bar paling kanan.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  /// Kunci isi tab. Dipakai pengujian agar tidak tertukar dengan `IndexedStack`
  /// internal widget lain, misalnya `DropdownButton`.
  static const Key tabsKey = Key('app-shell-tabs');

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  void _selectDestination(int index) {
    if (index == _selectedIndex) {
      return;
    }
    setState(() => _selectedIndex = index);
  }

  void _selectShortcut(DashboardShortcut shortcut) {
    switch (shortcut) {
      case DashboardShortcut.reports:
        Navigator.of(context).pushNamed(AppRoutes.reports);
      case DashboardShortcut.catalog:
        _selectDestination(ShellDestination.catalog.index);
      case DashboardShortcut.cashier:
        _selectDestination(ShellDestination.cashier.index);
      case DashboardShortcut.settings:
        _selectDestination(ShellDestination.settings.index);
      case DashboardShortcut.statistics:
        Navigator.of(context).pushNamed(AppRoutes.statistics);
      case DashboardShortcut.chatbot:
        Navigator.of(context).pushNamed(AppRoutes.chatbot);
    }
  }

  void _openScanner() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ProductScannerScreen()),
    );
  }

  Widget _viewFor(ShellDestination destination) {
    switch (destination) {
      case ShellDestination.floorPlan:
        return DashboardScreen(
          onShortcutSelected: _selectShortcut,
          onStartScan: _openScanner,
        );
      case ShellDestination.cashier:
        return CartCheckoutScreen(
          onOpenScanner: _openScanner,
          onOpenCatalog: () =>
              _selectDestination(ShellDestination.catalog.index),
        );
      case ShellDestination.catalog:
        return const ProductCatalog();
      case ShellDestination.settings:
        return const SettingsScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final destination = ShellDestination.values[_selectedIndex];
    final isSettings = destination == ShellDestination.settings;

    return Scaffold(
      appBar: AppBar(
        title: Text(destination.label),
        leading: const Padding(
          padding: EdgeInsets.all(AppSpacing.xs),
          child: RyanAppLogo(
            size: 32,
            showWordmark: false,
            assetPath: RyanAppLogo.defaultAssetPath,
          ),
        ),
        actions: [
          IconButton(
            icon: SizedBox(
              width: 24,
              height: 24,
              child: Image.asset(
                ShellDestination.settings.assetPath,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Icon(
                  isSettings
                      ? ShellDestination.settings.selectedIcon
                      : ShellDestination.settings.icon,
                  color: isSettings ? AppColors.primary : null,
                ),
              ),
            ),
            tooltip: 'Pengaturan',
            onPressed: () =>
                _selectDestination(ShellDestination.settings.index),
          ),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          key: AppShell.tabsKey,
          index: _selectedIndex,
          children: [
            for (final item in ShellDestination.values) _viewFor(item),
          ],
        ),
      ),
      bottomNavigationBar: _AppBottomBar(
        selectedIndex: _selectedIndex,
        onSelect: _selectDestination,
      ),
    );
  }
}

/// Navigasi bawah dengan tombol Kasir berbentuk waterdrop di tengah.
class _AppBottomBar extends StatelessWidget {
  const _AppBottomBar({required this.selectedIndex, required this.onSelect});

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  static const double _barHeight = 64;
  static const double _cashierSize = 60;
  static const double _overlap = 32;
  static const double _protrusion = _cashierSize - _overlap;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final barHeight = _barHeight + bottomInset;
    final cashierSelected = selectedIndex == ShellDestination.cashier.index;

    return SizedBox(
      height: barHeight + _protrusion,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: barHeight,
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: const Border(
                  top: BorderSide(color: AppColors.primaryLight),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryDark.withValues(alpha: 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomInset),
                child: Row(
                  children: [
                    Expanded(
                      child: _BottomBarItem(
                        destination: ShellDestination.floorPlan,
                        selected:
                            selectedIndex == ShellDestination.floorPlan.index,
                        onTap: () => onSelect(ShellDestination.floorPlan.index),
                      ),
                    ),
                    const SizedBox(width: _cashierSize + AppSpacing.md),
                    Expanded(
                      child: _BottomBarItem(
                        destination: ShellDestination.catalog,
                        selected:
                            selectedIndex == ShellDestination.catalog.index,
                        onTap: () => onSelect(ShellDestination.catalog.index),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: barHeight - _overlap,
            child: Center(
              child: _CashierButton(
                isSelected: cashierSelected,
                onTap: () => onSelect(ShellDestination.cashier.index),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Satu tujuan navigasi berbentuk ikon dan label.
class _BottomBarItem extends StatelessWidget {
  const _BottomBarItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final ShellDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected ? AppColors.primary : AppColors.muted;
    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.controlBorder,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Image.asset(
                destination.assetPath,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Icon(
                  selected ? destination.selectedIcon : destination.icon,
                  size: 24,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              destination.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tombol Kasir bulat yang menjulang ke atas dari navigasi bawah.
class _CashierButton extends StatelessWidget {
  const _CashierButton({required this.isSelected, required this.onTap});

  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: ShellDestination.cashier.label,
      child: Tooltip(
        message: 'Kasir',
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: _AppBottomBar._cashierSize,
            height: _AppBottomBar._cashierSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isSelected
                    ? const [AppColors.accent, AppColors.primary]
                    : const [AppColors.primary, AppColors.primaryDark],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDark.withValues(alpha: 0.32),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xs),
              child: Image.asset(
                ShellDestination.cashier.assetPath,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.point_of_sale_rounded,
                  color: AppColors.surface,
                  size: 28,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
