import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
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
    super.key,
  });
  final MonitorLayout layout;
  final ValueChanged<String> onSelect;
  final void Function(String, int, int) onMove;
  final bool editing;
  final String? selectedId;
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
      Wrap(
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
      LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(
            constraints.maxWidth,
            constraints.maxWidth * .65 + AppSpacing.xl * 3,
          );
          final projection = MonitorProjection(widget.layout, size);
          return SizedBox(
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
                  ),
                ),
              ),
            ),
          );
        },
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
    this.scaler,
  );
  final MonitorProjection projection;
  final String? selected;
  final ({int low, int out}) Function(String) counts;
  final TextStyle style;
  final TextScaler scaler;
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
    final floor = Path()
      ..addPolygon([
        p.project(0, 0),
        p.project(l.gridWidth.toDouble(), 0),
        p.project(l.gridWidth.toDouble(), l.gridHeight.toDouble()),
        p.project(0, l.gridHeight.toDouble()),
      ], true);
    c.drawPath(floor, Paint()..color = AppColors.primarySubtle);
    final line = Paint()
      ..color = AppColors.borderSubtle
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
    for (final f in p.ordered) {
      final x = f.x.toDouble(),
          y = f.y.toDouble(),
          w = f.width.toDouble(),
          h = f.height.toDouble(),
          z = p.height(f);
      final active = f.id == selected;
      c.drawShadow(p.top(f, 0), AppColors.ink, AppSpacing.xxs, false);
      for (final side in [
        (
          points: [
            p.project(x + w, y, z),
            p.project(x + w, y + h, z),
            p.project(x + w, y + h),
            p.project(x + w, y),
          ],
          color: active ? AppColors.primaryDark : AppColors.muted,
        ),
        (
          points: [
            p.project(x, y + h, z),
            p.project(x + w, y + h, z),
            p.project(x + w, y + h),
            p.project(x, y + h),
          ],
          color: active ? AppColors.primary : AppColors.borderSubtle,
        ),
      ]) {
        c.drawPath(
          Path()..addPolygon(side.points, true),
          Paint()..color = side.color,
        );
      }
      c.drawPath(
        p.top(f),
        Paint()..color = active ? AppColors.primaryLight : AppColors.surface,
      );
      c.drawPath(
        p.top(f),
        Paint()
          ..color = active ? AppColors.primary : AppColors.muted
          ..style = PaintingStyle.stroke,
      );
    }
    // Nomor ringkas menjaga rak rapat tetap terbaca; nama/status lengkap pada daftar.
    final occupied = <Rect>[];
    for (final f in p.ordered) {
      final center = p.project(
        f.x + f.width / 2,
        f.y + f.height / 2,
        p.height(f),
      );
      final n = counts(f.id);
      final number = l.fixtures.indexOf(f) + 1;
      final text = '$number${n.out + n.low > 0 ? ' !' : ''}';
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: style.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      )..layout();
      final box = Rect.fromCenter(
        center: center,
        width: painter.width + AppSpacing.xs,
        height: painter.height + AppSpacing.xxs,
      );
      if (occupied.any((rect) => rect.overlaps(box)) && f.id != selected) {
        continue;
      }
      occupied.add(box);
      c.drawRRect(
        RRect.fromRectAndRadius(box, const Radius.circular(AppSpacing.xxs)),
        Paint()
          ..color = f.id == selected
              ? AppColors.primaryLight
              : AppColors.surface,
      );
      painter.paint(
        c,
        box.topLeft + const Offset(AppSpacing.xxs, AppSpacing.xxs / 2),
      );
    }
  }

  @override
  bool shouldRepaint(_MonitorPainter old) => true;
}
