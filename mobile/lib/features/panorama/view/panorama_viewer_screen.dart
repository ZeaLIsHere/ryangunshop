import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../floor_plan/sample/floor_plan_sample.dart';
import '../../floor_plan/view/fixture_product_sheet.dart';
import '../model/panorama_zone.dart';

/// Layar penampil panorama 360 derajat per zona warung.
class PanoramaViewerScreen extends StatefulWidget {
  const PanoramaViewerScreen({this.initialZoneId = 'zona-depan', super.key});

  final String initialZoneId;

  @override
  State<PanoramaViewerScreen> createState() => _PanoramaViewerScreenState();
}

class _PanoramaViewerScreenState extends State<PanoramaViewerScreen> {
  late PanoramaZone _selectedZone;
  double _yaw = 60.0; // horizontal angle 0-360
  double _pitch = 0.0; // vertical angle -45 to 45

  @override
  void initState() {
    super.initState();
    _selectedZone = PanoramaSample.zones.firstWhere(
      (z) => z.id == widget.initialZoneId,
      orElse: () => PanoramaSample.zones.first,
    );
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _yaw = (_yaw - details.delta.dx * 0.4) % 360;
      if (_yaw < 0) _yaw += 360;
      _pitch = (_pitch + details.delta.dy * 0.3).clamp(-40.0, 40.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: Stack(
          children: [
            // Interactive 360 Viewport Canvas
            GestureDetector(
              onPanUpdate: _onPanUpdate,
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: CustomPaint(
                  painter: _PanoramaSkyboxPainter(
                    yaw: _yaw,
                    pitch: _pitch,
                    zone: _selectedZone,
                  ),
                ),
              ),
            ),

            // Hotspots overlay
            ..._buildHotspots(size),

            // Top Bar: Back, Zone Title & Compass
            Positioned(
              top: AppSpacing.sm,
              left: AppSpacing.screen,
              right: AppSpacing.screen,
              child: Row(
                children: [
                  IconButton.filled(
                    icon: const Icon(Icons.arrow_back),
                    tooltip: 'Kembali ke Denah',
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.ink.withValues(alpha: 0.55),
                      foregroundColor: AppColors.surface,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs + 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.ink.withValues(alpha: 0.55),
                        borderRadius: AppRadius.controlBorder,
                        border: Border.all(
                          color: AppColors.surface.withValues(alpha: 0.24),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedZone.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: AppColors.surface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _selectedZone.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.surface.withValues(alpha: 0.7),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  // Compass indicator
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.ink.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.surface.withValues(alpha: 0.24),
                      ),
                    ),
                    child: Transform.rotate(
                      angle: -_yaw * (math.pi / 180),
                      child: const Icon(
                        Icons.navigation,
                        color: AppColors.accent,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Zone Selector Chips & Hint
            Positioned(
              bottom: AppSpacing.screen,
              left: AppSpacing.screen,
              right: AppSpacing.screen,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.ink.withValues(alpha: 0.6),
                      borderRadius: AppRadius.controlBorder,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.touch_app,
                          size: 14,
                          color: AppColors.surface,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Geser layar untuk melihat sekeliling 360° • Ketuk pin untuk lihat produk',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.surface,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (final zone in PanoramaSample.zones)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ChoiceChip(
                              label: Text(zone.name),
                              selected: _selectedZone.id == zone.id,
                              selectedColor: AppColors.primary,
                              backgroundColor: AppColors.ink.withValues(
                                alpha: 0.6,
                              ),
                              labelStyle: TextStyle(
                                color: _selectedZone.id == zone.id
                                    ? AppColors.surface
                                    : AppColors.surface.withValues(alpha: 0.7),
                                fontWeight: _selectedZone.id == zone.id
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedZone = zone;
                                  });
                                }
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildHotspots(Size screenSize) {
    final widgets = <Widget>[];
    const fov = 90.0; // Field of View in degrees

    for (final hotspot in _selectedZone.hotspots) {
      double diffYaw = (hotspot.yaw - _yaw) % 360;
      if (diffYaw > 180) diffYaw -= 360;
      if (diffYaw < -180) diffYaw += 360;

      // Check if within FOV
      if (diffYaw.abs() <= fov / 2) {
        final screenX =
            (screenSize.width / 2) +
            (diffYaw / (fov / 2)) * (screenSize.width / 2);
        final diffPitch = hotspot.pitch - _pitch;
        final screenY =
            (screenSize.height / 2) -
            (diffPitch / 40.0) * (screenSize.height / 3);

        widgets.add(
          Positioned(
            left: screenX - 60,
            top: screenY - 20,
            child: GestureDetector(
              onTap: () {
                final fixture = FloorPlanSample.defaultFixtures.firstWhere(
                  (f) => f.id == hotspot.fixtureId,
                  orElse: () => FloorPlanSample.defaultFixtures.first,
                );
                FixtureProductSheet.show(context, fixture);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.9),
                  borderRadius: AppRadius.controlBorder,
                  border: Border.all(color: AppColors.surface, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.ink.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(hotspot.icon, size: 16, color: AppColors.surface),
                    const SizedBox(width: 4),
                    Text(
                      hotspot.title,
                      style: const TextStyle(
                        color: AppColors.surface,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    }

    return widgets;
  }
}

/// Painter untuk efek visual 360 lingkungan warung modern.
class _PanoramaSkyboxPainter extends CustomPainter {
  _PanoramaSkyboxPainter({
    required this.yaw,
    required this.pitch,
    required this.zone,
  });

  final double yaw;
  final double pitch;
  final PanoramaZone zone;

  @override
  void paint(Canvas canvas, Size size) {
    // Background gradient interior warung
    final rect = Offset.zero & size;
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: const [Color(0xFF1E213D), Color(0xFF2C3058), Color(0xFF1E2235)],
      stops: [0.0, 0.5 + (pitch / 100), 1.0],
    );

    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);

    // Floor perspective line
    final floorPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1.2;

    final horizonY = (size.height / 2) + (pitch * 3);
    canvas.drawLine(
      Offset(0, horizonY),
      Offset(size.width, horizonY),
      floorPaint,
    );

    // Dynamic panorama columns according to yaw
    final columnPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1.0;

    const columnSpacing = 45.0; // degree spacing
    for (double deg = 0; deg < 360; deg += columnSpacing) {
      double diff = (deg - yaw) % 360;
      if (diff > 180) diff -= 360;
      if (diff < -180) diff += 360;

      final x = (size.width / 2) + (diff / 45) * (size.width / 2);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), columnPaint);

      // Floor grid perspective lines
      canvas.drawLine(
        Offset(x, horizonY),
        Offset((x - size.width / 2) * 2.5 + size.width / 2, size.height),
        floorPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PanoramaSkyboxPainter oldDelegate) {
    return oldDelegate.yaw != yaw ||
        oldDelegate.pitch != pitch ||
        oldDelegate.zone != zone;
  }
}
