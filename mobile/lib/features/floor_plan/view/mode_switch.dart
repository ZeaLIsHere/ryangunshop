import 'package:flutter/material.dart';
import 'package:ryangunshop/core/theme/app_colors.dart';
import 'package:ryangunshop/core/theme/app_radius.dart';
import 'package:ryangunshop/core/theme/app_spacing.dart';

enum ViewMode { floorPlan, panorama360 }

/// Komponen pemilih mode tampilan antara Denah 2D dan Panorama 360°.
///
/// Jika [isPanoramaAvailable] bernilai false, opsi 360° akan dinonaktifkan.
class ModeSwitch extends StatelessWidget {
  final ViewMode currentMode;
  final bool isPanoramaAvailable;
  final ValueChanged<ViewMode> onModeChanged;

  const ModeSwitch({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
    this.isPanoramaAvailable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.controlBorder,
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withAlpha((0.05 * 255).round()),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildOption(
            context,
            mode: ViewMode.floorPlan,
            label: 'Denah',
            icon: Icons.map,
            isSelected: currentMode == ViewMode.floorPlan,
            isEnabled: true,
          ),
          const SizedBox(width: AppSpacing.xs),
          _buildOption(
            context,
            mode: ViewMode.panorama360,
            label: '360°',
            icon: Icons.threed_rotation,
            isSelected: currentMode == ViewMode.panorama360,
            isEnabled: isPanoramaAvailable,
          ),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required ViewMode mode,
    required String label,
    required IconData icon,
    required bool isSelected,
    required bool isEnabled,
  }) {
    final color = isSelected 
        ? AppColors.surface 
        : (isEnabled ? AppColors.ink : AppColors.muted.withAlpha((0.5 * 255).round()));
    
    final backgroundColor = isSelected 
        ? AppColors.primary 
        : Colors.transparent;

    return Semantics(
      label: 'Beralih ke mode $label',
      button: true,
      enabled: isEnabled,
      selected: isSelected,
      child: InkWell(
        onTap: isEnabled && !isSelected ? () => onModeChanged(mode) : null,
        borderRadius: AppRadius.controlBorder,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: AppRadius.controlBorder,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
