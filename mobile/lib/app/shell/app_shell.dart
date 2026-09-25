import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/widgets/ryan_app_logo.dart';
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
            for (final item in ShellDestination.values)
              ShellPlaceholderView(destination: item),
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
