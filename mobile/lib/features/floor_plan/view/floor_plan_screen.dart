import 'package:flutter/material.dart';

import '../../../app/routing/app_router.dart';
import '../../dashboard/model/dashboard_shortcut.dart';
import '../../dashboard/view/dashboard_screen.dart';
import '../view_model/floor_plan_view_model.dart';
import 'store_floor_plan.dart';

/// Layar utama tab Denah yang menggabungkan Kanvas Denah Spasial dan Dashboard Bento.
class FloorPlanScreen extends StatefulWidget {
  const FloorPlanScreen({
    this.onShortcutSelected,
    this.initialHighlightFixtureId,
    super.key,
  });

  final ValueChanged<DashboardShortcut>? onShortcutSelected;
  final String? initialHighlightFixtureId;

  @override
  State<FloorPlanScreen> createState() => _FloorPlanScreenState();
}

class _FloorPlanScreenState extends State<FloorPlanScreen> {
  final FloorPlanViewModel _floorPlanViewModel = FloorPlanViewModel();
  bool _showDashboard = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialHighlightFixtureId != null) {
      _floorPlanViewModel.highlightFixture(widget.initialHighlightFixtureId);
    }
  }

  @override
  void dispose() {
    _floorPlanViewModel.dispose();
    super.dispose();
  }

  void _openPanorama() {
    Navigator.of(context).pushNamed(AppRoutes.panorama);
  }

  @override
  Widget build(BuildContext context) {
    if (_showDashboard) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard Ringkasan'),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.map_outlined),
              label: const Text('Buka Denah'),
              onPressed: () => setState(() => _showDashboard = false),
            ),
          ],
        ),
        body: DashboardScreen(
          onShortcutSelected: (shortcut) {
            if (shortcut == DashboardShortcut.cashier) {
              widget.onShortcutSelected?.call(shortcut);
            } else {
              widget.onShortcutSelected?.call(shortcut);
            }
          },
        ),
      );
    }

    return Scaffold(
      body: StoreFloorPlan(
        viewModel: _floorPlanViewModel,
        initialHighlightFixtureId: widget.initialHighlightFixtureId,
        onOpenPanorama: _openPanorama,
      ),
    );
  }
}
