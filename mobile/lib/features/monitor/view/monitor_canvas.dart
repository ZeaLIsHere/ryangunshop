import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../model/monitor_layout.dart';

class MonitorProjection {
  MonitorProjection(this.layout, this.size) {
    unit = size.width / (layout.gridWidth + layout.gridHeight + 4);
    origin = Offset((layout.gridHeight + 2) * unit, AppSpacing.xl * 2);
  }
  final MonitorLayout layout;
  final Size size;
  late final double unit;
  late final Offset origin;
  Offset project(double x, double y, [double z = 0]) =>
      origin + Offset((x - y) * unit, (x + y) * unit / 2 - z);
  Offset inverse(Offset point) {
    final p = point - origin;
    return Offset(
      p.dx / (2 * unit) + p.dy / unit,
      p.dy / unit - p.dx / (2 * unit),
    );
  }

  double height(MonitorFixture f) => f.type == MonitorFixtureType.fridge
      ? unit * 2
      : f.type == MonitorFixtureType.shelf
      ? unit * 1.5
      : f.type == MonitorFixtureType.showcase
      ? unit * 1.2
      : unit;
  Path top(MonitorFixture f, [double? z]) => Path()
    ..moveTo(
      project(f.x.toDouble(), f.y.toDouble(), z ?? height(f)).dx,
      project(f.x.toDouble(), f.y.toDouble(), z ?? height(f)).dy,
    )
    ..lineTo(
      project((f.x + f.width).toDouble(), f.y.toDouble(), z ?? height(f)).dx,
      project((f.x + f.width).toDouble(), f.y.toDouble(), z ?? height(f)).dy,
    )
    ..lineTo(
      project(
        (f.x + f.width).toDouble(),
        (f.y + f.height).toDouble(),
        z ?? height(f),
      ).dx,
      project(
        (f.x + f.width).toDouble(),
        (f.y + f.height).toDouble(),
        z ?? height(f),
      ).dy,
    )
    ..lineTo(
      project(f.x.toDouble(), (f.y + f.height).toDouble(), z ?? height(f)).dx,
      project(f.x.toDouble(), (f.y + f.height).toDouble(), z ?? height(f)).dy,
    )
    ..close();
  List<MonitorFixture> get ordered => [...layout.fixtures]
    ..sort(
      (a, b) => (a.x + a.y + a.width + a.height).compareTo(
        b.x + b.y + b.width + b.height,
      ),
    );
  MonitorFixture? hit(Offset point) {
    for (final f in ordered.reversed) {
      final polygon = top(f).getBounds().expandToInclude(top(f, 0).getBounds());
      if (top(f).contains(point) ||
          polygon.contains(point) && _side(f).contains(point)) {
        return f;
      }
    }
    return null;
  }

  Path _side(MonitorFixture f) {
    final z = height(f),
        x = f.x.toDouble(),
        y = f.y.toDouble(),
        w = f.width.toDouble(),
        h = f.height.toDouble();
    final points = [
      project(x + w, y, z),
      project(x + w, y + h, z),
      project(x, y + h, z),
      project(x, y + h),
      project(x + w, y + h),
      project(x + w, y),
    ];
    return Path()..addPolygon(points, true);
  }
}

class MonitorCanvas extends StatefulWidget {
  const MonitorCanvas({
    required this.layout,
    required this.onSelect,
    required this.onMove,
    required this.editing,
    required this.counts,
    this.selectedId,
    this.filterAlertsOnly = false,
    this.highlightedId,
    super.key,
  });
  final MonitorLayout layout;
  final ValueChanged<String> onSelect;
  final void Function(String, int, int) onMove;
  final bool editing;
  final String? selectedId;
  final bool filterAlertsOnly;
  final String? highlightedId;
  final ({int low, int out}) Function(String) counts;
  @override
  State<MonitorCanvas> createState() => _MonitorCanvasState();
}

class _MonitorCanvasState extends State<MonitorCanvas> {
  final transform = TransformationController();
  MonitorFixture? dragged;
  Offset? start;
  @override
  void dispose() {
    transform.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(MonitorCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.editing &&
        oldWidget.selectedId != widget.selectedId &&
        widget.selectedId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final width = context.size?.width;
        if (width == null) return;
        final f = widget.layout.fixtures
            .where((f) => f.id == widget.selectedId)
            .firstOrNull;
        if (f == null) return;
        final height = width * .65 + AppSpacing.xl * 3;
        final p = MonitorProjection(widget.layout, Size(width, height));
        final target = p.project(
          f.x + f.width / 2,
          f.y + f.height / 2,
          p.height(f),
        );
        transform.value = Matrix4.identity()
          ..translateByDouble(
            width / 2 - target.dx * 2,
            height / 2 - target.dy * 2,
            0,
            1,
          )
          ..scaleByDouble(2, 2, 1, 1);
      });
    }
  }

  Widget _viewport(Widget child) {
    if (!widget.editing) {
      return InteractiveViewer(
        transformationController: transform,
        minScale: 1,
        maxScale: 4,
        child: child,
      );
    }
    // InteractiveViewer tetap mendaftarkan scale recognizer ketika pan dimatikan;
    // pisahkan editor agar drag fixture tidak kalah di gesture arena.
    return ClipRect(
      child: ValueListenableBuilder<Matrix4>(
        valueListenable: transform,
        builder: (context, matrix, _) =>
            Transform(transform: matrix, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        child: Wrap(
          spacing: AppSpacing.xs,
          children: [
            IconButton(
              tooltip: 'Perbesar',
              onPressed: () {
                final scale = transform.value.getMaxScaleOnAxis();
                if (scale < 4) {
                  transform.value = transform.value.clone()
                    ..scaleByDouble(
                      (4 / scale).clamp(1, 1.25),
                      (4 / scale).clamp(1, 1.25),
                      1,
                      1,
                    );
                }
              },
              icon: const Icon(Icons.zoom_in),
            ),
            IconButton(
              tooltip: 'Perkecil',
              onPressed: () {
                final scale = transform.value.getMaxScaleOnAxis();
                if (scale > 1) {
                  transform.value = transform.value.clone()
                    ..scaleByDouble(
                      (1 / scale).clamp(.8, 1),
                      (1 / scale).clamp(.8, 1),
                      1,
                      1,
                    );
                }
              },
              icon: const Icon(Icons.zoom_out),
            ),
            TextButton.icon(
              onPressed: () => transform.value = Matrix4.identity(),
              icon: const Icon(Icons.center_focus_strong),
              label: const Text('Reset tampilan'),
            ),
          ],
        ),
      ),
      Expanded(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            final projection = MonitorProjection(widget.layout, size);
            return SizedBox(
              width: size.width,
              height: size.height,
              child: _viewport(
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (d) {
                    final f = projection.hit(d.localPosition);
                    if (f != null) widget.onSelect(f.id);
                  },
                  onPanDown: widget.editing
                      ? (d) {
                          dragged = projection.hit(d.localPosition);
                          start = projection.inverse(d.localPosition);
                        }
                      : null,
                  onPanStart: widget.editing
                      ? (d) {
                          if (dragged != null) widget.onSelect(dragged!.id);
                        }
                      : null,
                  onPanUpdate: widget.editing
                      ? (d) {
                          final f = dragged, s = start;
                          if (f == null || s == null) return;
                          final p = projection.inverse(d.localPosition);
                          widget.onMove(
                            f.id,
                            f.x + (p.dx - s.dx).round(),
                            f.y + (p.dy - s.dy).round(),
                          );
                        }
                      : null,
                  onPanEnd: widget.editing
                      ? (_) {
                          dragged = null;
                          start = null;
                        }
                      : null,
                  child: CustomPaint(
                    key: const ValueKey('monitor-isometric-paint'),
                    size: size,
                    painter: _MonitorPainter(
                      projection,
                      widget.selectedId,
                      widget.counts,
                      Theme.of(context).textTheme.bodySmall!,
                      MediaQuery.textScalerOf(context),
                      filterAlertsOnly: widget.filterAlertsOnly,
                      highlightedId: widget.highlightedId,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ],
  );
}

class _MonitorPainter extends CustomPainter {
  _MonitorPainter(
    this.projection,
    this.selected,
    this.counts,
    this.style,
    this.scaler, {
    this.filterAlertsOnly = false,
    this.highlightedId,
  });
  final MonitorProjection projection;
  final String? selected;
  final ({int low, int out}) Function(String) counts;
  final TextStyle style;
  final TextScaler scaler;
  final bool filterAlertsOnly;
  final String? highlightedId;

  void label(Canvas c, String text, Offset p, double width, Color color) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: style.copyWith(color: color),
      ),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: width);
    painter.paint(c, p - Offset(painter.width / 2, 0));
  }

  @override
  void paint(Canvas c, Size size) {
    final p = projection, l = p.layout;
    c.drawColor(AppColors.canvas, BlendMode.src);

    // 1. Dinding batas ruangan isometrik (Low back walls) untuk kedalaman 3D
    final wallH = p.unit * 0.9;
    final leftWall = Path()
      ..addPolygon([
        p.project(0, 0, 0),
        p.project(0, l.gridHeight.toDouble(), 0),
        p.project(0, l.gridHeight.toDouble(), wallH),
        p.project(0, 0, wallH),
      ], true);
    c.drawPath(
      leftWall,
      Paint()..color = AppColors.borderSubtle.withValues(alpha: 0.5),
    );

    final rightWall = Path()
      ..addPolygon([
        p.project(0, 0, 0),
        p.project(l.gridWidth.toDouble(), 0, 0),
        p.project(l.gridWidth.toDouble(), 0, wallH),
        p.project(0, 0, wallH),
      ], true);
    c.drawPath(
      rightWall,
      Paint()..color = AppColors.borderSubtle.withValues(alpha: 0.35),
    );

    // 2. Lantai ruangan toko (Floor grid)
    final floor = Path()
      ..addPolygon([
        p.project(0, 0),
        p.project(l.gridWidth.toDouble(), 0),
        p.project(l.gridWidth.toDouble(), l.gridHeight.toDouble()),
        p.project(0, l.gridHeight.toDouble()),
      ], true);
    c.drawPath(floor, Paint()..color = AppColors.primarySubtle.withValues(alpha: 0.6));

    final line = Paint()
      ..color = AppColors.borderSubtle.withValues(alpha: 0.6)
      ..strokeWidth = 1;
    for (var x = 0; x <= l.gridWidth; x++) {
      c.drawLine(
        p.project(x.toDouble(), 0),
        p.project(x.toDouble(), l.gridHeight.toDouble()),
        line,
      );
    }
    for (var y = 0; y <= l.gridHeight; y++) {
      c.drawLine(
        p.project(0, y.toDouble()),
        p.project(l.gridWidth.toDouble(), y.toDouble()),
        line,
      );
    }

    // 3. Bayangan kontak halus di lantai (Soft Contact Shadows)
    for (final f in p.ordered) {
      final x = f.x.toDouble(),
          y = f.y.toDouble(),
          w = f.width.toDouble(),
          h = f.height.toDouble();
      final shadow = Path()
        ..addPolygon([
          p.project(x + 0.08, y + 0.08),
          p.project(x + w + 0.12, y + 0.08),
          p.project(x + w + 0.12, y + h + 0.12),
          p.project(x + 0.08, y + h + 0.12),
        ], true);
      c.drawPath(
        shadow,
        Paint()
          ..color = AppColors.ink.withValues(alpha: 0.12)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }

    // 4. Render Objek Toko 3D Isometrik Berkarakter (Thematic Fixture Rendering)
    for (final f in p.ordered) {
      final x = f.x.toDouble(),
          y = f.y.toDouble(),
          w = f.width.toDouble(),
          h = f.height.toDouble(),
          z = p.height(f);
      final active = f.id == selected || f.id == highlightedId;
      final n = counts(f.id);
      final isOut = n.out > 0;
      final isLow = !isOut && n.low > 0;
      final isSafe = !isOut && !isLow;
      final isDimmed = filterAlertsOnly && isSafe && !active;
      final alpha = isDimmed ? 0.35 : 1.0;

      // Palet warna kontekstual per jenis objek
      Color rightColor;
      Color frontColor;
      Color topColor;

      switch (f.type) {
        case MonitorFixtureType.shelf:
          rightColor = active ? AppColors.primaryDark : const Color(0xFF8C7A65).withValues(alpha: alpha);
          frontColor = active ? AppColors.primary : const Color(0xFFA8947D).withValues(alpha: alpha);
          topColor = active ? AppColors.primaryLight : const Color(0xFFC4B39D).withValues(alpha: alpha);
        case MonitorFixtureType.fridge:
          rightColor = active ? AppColors.primaryDark : const Color(0xFF64748B).withValues(alpha: alpha);
          frontColor = active ? AppColors.primary : const Color(0xFFA5B4FC).withValues(alpha: 0.9 * alpha);
          topColor = active ? AppColors.primaryLight : const Color(0xFFE2E8F0).withValues(alpha: alpha);
        case MonitorFixtureType.showcase:
          rightColor = active ? AppColors.primaryDark : const Color(0xFF475569).withValues(alpha: alpha);
          frontColor = active ? AppColors.primary : const Color(0xFF7DD3FC).withValues(alpha: 0.88 * alpha);
          topColor = active ? AppColors.primaryLight : const Color(0xFFE0F2FE).withValues(alpha: alpha);
        case MonitorFixtureType.cashCounter:
          rightColor = active ? AppColors.primaryDark : const Color(0xFF475569).withValues(alpha: alpha);
          frontColor = active ? AppColors.primary : const Color(0xFF64748B).withValues(alpha: alpha);
          topColor = active ? AppColors.primaryLight : const Color(0xFFCBD5E1).withValues(alpha: alpha);
      }

      // Sisi kanan (Right side wall)
      final rightSidePath = Path()
        ..addPolygon([
          p.project(x + w, y, z),
          p.project(x + w, y + h, z),
          p.project(x + w, y + h),
          p.project(x + w, y),
        ], true);
      c.drawPath(rightSidePath, Paint()..color = rightColor);

      // Sisi depan hadap kamera (Front side wall)
      final frontSidePath = Path()
        ..addPolygon([
          p.project(x, y + h, z),
          p.project(x + w, y + h, z),
          p.project(x + w, y + h),
          p.project(x, y + h),
        ], true);
      c.drawPath(frontSidePath, Paint()..color = frontColor);

      // Detail ornamen jenis furnitur
      if (!isDimmed) {
        if (f.type == MonitorFixtureType.shelf) {
          // Garis ambalan rak horizontal
          final slat1Z = z * 0.35;
          final slat2Z = z * 0.70;
          final slatPaint = Paint()
            ..color = (active ? AppColors.primaryDark : const Color(0xFF6E5D4B)).withValues(alpha: alpha)
            ..strokeWidth = 1.2;
          c.drawLine(p.project(x, y + h, slat1Z), p.project(x + w, y + h, slat1Z), slatPaint);
          c.drawLine(p.project(x, y + h, slat2Z), p.project(x + w, y + h, slat2Z), slatPaint);
        } else if (f.type == MonitorFixtureType.fridge) {
          // Pegangan pintu kulkas vertikal & pantulan kaca
          final handlePaint = Paint()
            ..color = Colors.white.withValues(alpha: 0.8 * alpha)
            ..strokeWidth = 2.0;
          final handleTop = p.project(x + w * 0.85, y + h, z * 0.75);
          final handleBottom = p.project(x + w * 0.85, y + h, z * 0.25);
          c.drawLine(handleTop, handleBottom, handlePaint);
        } else if (f.type == MonitorFixtureType.showcase) {
          // Garis pembatas kaca dan bodi bawah etalase
          final glassDividerZ = z * 0.45;
          final dividerPaint = Paint()
            ..color = const Color(0xFF334155).withValues(alpha: alpha)
            ..strokeWidth = 1.5;
          c.drawLine(p.project(x, y + h, glassDividerZ), p.project(x + w, y + h, glassDividerZ), dividerPaint);
        } else if (f.type == MonitorFixtureType.cashCounter) {
          // Aksen register / monitor kasir mini di atas counter
          final regCenter = p.project(x + w * 0.7, y + h * 0.5, z);
          final regBox = Rect.fromCenter(center: regCenter, width: 8, height: 6);
          c.drawRect(regBox, Paint()..color = const Color(0xFF1E293B).withValues(alpha: alpha));
        }
      }

      // Permukaan atas (Top face)
      final topPath = p.top(f);
      c.drawPath(topPath, Paint()..color = topColor);

      // Garis tepi / highlight status
      if (isOut) {
        c.drawPath(
          topPath,
          Paint()
            ..color = AppColors.error.withValues(alpha: alpha)
            ..strokeWidth = 2.5
            ..style = PaintingStyle.stroke,
        );
      } else if (isLow) {
        c.drawPath(
          topPath,
          Paint()
            ..color = AppColors.warning.withValues(alpha: alpha)
            ..strokeWidth = 2.0
            ..style = PaintingStyle.stroke,
        );
      } else {
        c.drawPath(
          topPath,
          Paint()
            ..color = (active ? AppColors.primary : AppColors.muted).withValues(alpha: alpha)
            ..strokeWidth = active ? 2.0 : 1.0
            ..style = PaintingStyle.stroke,
        );
      }
    }

    // 5. Badge Status Stok & Nomor Objek di Atas Kanvas
    final occupied = <Rect>[];
    for (final f in p.ordered) {
      final center = p.project(
        f.x + f.width / 2,
        f.y + f.height / 2,
        p.height(f),
      );
      final n = counts(f.id);
      final number = l.fixtures.indexOf(f) + 1;
      final isOut = n.out > 0;
      final isLow = !isOut && n.low > 0;
      final active = f.id == selected || f.id == highlightedId;

      Color badgeBg;
      Color textColor;
      String text;

      if (isOut) {
        badgeBg = AppColors.error;
        textColor = Colors.white;
        text = '$number !';
      } else if (isLow) {
        badgeBg = AppColors.warning;
        textColor = Colors.white;
        text = '$number !';
      } else if (active) {
        badgeBg = AppColors.primary;
        textColor = Colors.white;
        text = '$number';
      } else {
        badgeBg = AppColors.surface;
        textColor = AppColors.ink;
        text = '$number';
      }

      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: style.copyWith(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      )..layout();

      final box = Rect.fromCenter(
        center: center,
        width: painter.width + AppSpacing.xs + 2,
        height: painter.height + AppSpacing.xxs + 2,
      );

      if (occupied.any((rect) => rect.overlaps(box)) && !active) {
        continue;
      }
      occupied.add(box);

      final rrect = RRect.fromRectAndRadius(box, const Radius.circular(AppRadius.pill));
      c.drawShadow(Path()..addRRect(rrect), Colors.black, 2, false);
      c.drawRRect(rrect, Paint()..color = badgeBg);
      painter.paint(
        c,
        box.topLeft + Offset((box.width - painter.width) / 2, (box.height - painter.height) / 2),
      );
    }
  }

  @override
  bool shouldRepaint(_MonitorPainter old) => true;
}
