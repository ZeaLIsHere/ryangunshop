import 'package:flutter/material.dart';

import '../../../core/session/app_session.dart';
import '../../../core/session/user_role.dart';
import '../model/dashboard_shortcut.dart';
import 'cashier_dashboard.dart';
import 'owner_dashboard.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    required this.onShortcutSelected,
    this.onStartScan,
    super.key,
  });

  final ValueChanged<DashboardShortcut> onShortcutSelected;
  final VoidCallback? onStartScan;

  @override
  Widget build(BuildContext context) =>
      AppSessionScope.of(context).role == UserRole.owner
      ? OwnerDashboard(onShortcutSelected: onShortcutSelected)
      : CashierDashboard(
          onShortcutSelected: onShortcutSelected,
          onStartScan: onStartScan,
        );
}
