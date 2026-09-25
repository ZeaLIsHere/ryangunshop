import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/widgets/ryan_app_logo.dart';
import '../../features/dashboard/model/dashboard_shortcut.dart';
import '../../features/dashboard/view/dashboard_screen.dart';
import '../../features/settings/view/settings_screen.dart';
import 'shell_destination.dart';
import 'shell_placeholder_view.dart';

/// Kerangka utama aplikasi: app bar, isi tab, dan navigasi bawah.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

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
    _selectDestination(_destinationFor(shortcut).index);
  }

  ShellDestination _destinationFor(DashboardShortcut shortcut) {
    switch (shortcut) {
      case DashboardShortcut.catalog:
        return ShellDestination.catalog;
      case DashboardShortcut.cashier:
        return ShellDestination.cashier;
      case DashboardShortcut.settings:
        return ShellDestination.settings;
    }
  }

  Widget _viewFor(ShellDestination destination) {
    switch (destination) {
      case ShellDestination.floorPlan:
        return DashboardScreen(onShortcutSelected: _selectShortcut);
      case ShellDestination.settings:
        return const SettingsScreen();
      case ShellDestination.catalog:
      case ShellDestination.cashier:
        return ShellPlaceholderView(destination: destination);
    }
  }

  @override
  Widget build(BuildContext context) {
    final destination = ShellDestination.values[_selectedIndex];
    return Scaffold(
      appBar: AppBar(
        title: Text(destination.label),
        leading: const Padding(
          padding: EdgeInsets.all(AppSpacing.xs),
          child: RyanAppLogo(size: 32, showWordmark: false),
        ),
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            for (final item in ShellDestination.values) _viewFor(item),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectDestination,
        destinations: [
          for (final item in ShellDestination.values)
            NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.selectedIcon),
              label: item.label,
            ),
        ],
      ),
    );
  }
}
