import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../format/rupiah.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'app_card.dart';

/// Diagram garis area halus interaktif (Smooth Area Line Chart) dengan panduan
/// sentuh, scrubbing tanggal, dan gradient violet khas RyanGunshop.
class SalesLineChart extends StatefulWidget {
  const SalesLineChart({
    required this.points,
    this.title = 'Penjualan bersih',
    this.wrapCard = true,
    this.height = 150.0,
    super.key,
  });

  final List<({DateTime date, int total})> points;
  final String title;
  final bool wrapCard;
  final double height;

  @override
  State<SalesLineChart> createState() => _SalesLineChartState();
}

class _SalesLineChartState extends State<SalesLineChart> {
  int? _selectedIndex;

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final points = widget.points;
    final maximum = points.fold<int>(
      0,
      (value, point) => point.total > value ? point.total : value,
    );

    final selectedIdx =
        (_selectedIndex != null && _selectedIndex! < points.length)
        ? _selectedIndex!
        : (points.isNotEmpty ? points.length - 1 : 0);
    final selectedPoint = points.isNotEmpty ? points[selectedIdx] : null;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    selectedPoint != null
                        ? formatRupiah(selectedPoint.total)
                        : formatRupiah(0),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
            if (selectedPoint != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primarySubtle,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  _formatDate(selectedPoint.date),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final chartWidth = constraints.maxWidth;
            final chartHeight = widget.height;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanDown: (details) =>
                  _handleTouch(details.localPosition.dx, chartWidth),
              onPanUpdate: (details) =>
                  _handleTouch(details.localPosition.dx, chartWidth),
              child: CustomPaint(
                size: Size(chartWidth, chartHeight),
                painter: _LineChartPainter(
                  points: points,
                  maximum: maximum,
                  selectedIndex: selectedIdx,
                  primaryColor: AppColors.primary,
                  gridColor: AppColors.borderSubtle,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildDateAxis(context, points, selectedIdx),
        const SizedBox(height: AppSpacing.xs),
        Text(
          points.length > 1
              ? 'Sentuh grafik untuk melihat nominal per tanggal · Maksimum ${formatRupiah(maximum)}'
              : 'Maksimum omzet hari ini ${formatRupiah(maximum)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.muted,
            fontSize: 11,
          ),
        ),
        for (final point in points)
          Semantics(
            container: true,
            label: '${_formatDate(point.date)}: ${formatRupiah(point.total)}',
            child: const SizedBox(width: 1, height: 1),
          ),
      ],
    );

    if (widget.wrapCard) {
      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: content,
      );
    }

    return content;
  }

  void _handleTouch(double dx, double width) {
    if (widget.points.length <= 1 || width <= 0) return;
    final count = widget.points.length;
    final index = ((dx / width) * (count - 1)).round().clamp(0, count - 1);
    if (_selectedIndex != index) {
      setState(() => _selectedIndex = index);
    }
  }

  Widget _buildDateAxis(
    BuildContext context,
    List<({DateTime date, int total})> points,
    int activeIdx,
  ) {
    final theme = Theme.of(context);
    if (points.isEmpty) return const SizedBox.shrink();
    if (points.length == 1) {
      return Center(
        child: Text(
          '${points.first.date.day}/${points.first.date.month}',
          style: theme.textTheme.labelSmall?.copyWith(color: AppColors.muted),
        ),
      );
    }

    final count = points.length;
    const maxLabels = 4;
    final displayedIndices = <int>[];
    if (count <= maxLabels) {
      for (var i = 0; i < count; i++) {
        displayedIndices.add(i);
      }
    } else {
      final step = (count - 1) / (maxLabels - 1);
      for (var i = 0; i < maxLabels; i++) {
        final idx = (i * step).round().clamp(0, count - 1);
        if (!displayedIndices.contains(idx)) {
          displayedIndices.add(idx);
        }
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final idx in displayedIndices)
          Flexible(
            child: Text(
              '${points[idx].date.day}/${points[idx].date.month}',
              textAlign: idx == displayedIndices.first
                  ? TextAlign.start
                  : (idx == displayedIndices.last
                        ? TextAlign.end
                        : TextAlign.center),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: idx == activeIdx ? AppColors.primary : AppColors.muted,
                fontWeight: idx == activeIdx
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
      ],
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.points,
    required this.maximum,
    required this.selectedIndex,
    required this.primaryColor,
    required this.gridColor,
  });

  final List<({DateTime date, int total})> points;
  final int maximum;
  final int selectedIndex;
  final Color primaryColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final width = size.width;
    final height = size.height;
    const topMargin = 16.0;
    const bottomMargin = 12.0;
    final chartHeight = height - topMargin - bottomMargin;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final gridSteps = [0.0, 0.5, 1.0];
    for (final step in gridSteps) {
      final y = topMargin + chartHeight * (1.0 - step);
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
    }

    final List<Offset> coords = [];
    if (points.length == 1) {
      final total = points.first.total;
      final yEnd = maximum > 0
          ? topMargin + chartHeight * (1.0 - (total / maximum))
          : topMargin + chartHeight;
      coords.add(Offset(0, topMargin + chartHeight));
      coords.add(Offset(width, yEnd));
    } else {
      for (var i = 0; i < points.length; i++) {
        final x = (i / (points.length - 1)) * width;
        final ratio = maximum > 0 ? (points[i].total / maximum) : 0.0;
        final y = topMargin + chartHeight * (1.0 - ratio);
        coords.add(Offset(x, y));
      }
    }

    if (coords.length >= 2) {
      final linePath = Path();
      linePath.moveTo(coords.first.dx, coords.first.dy);

      for (var i = 0; i < coords.length - 1; i++) {
        final p0 = i > 0 ? coords[i - 1] : coords[i];
        final p1 = coords[i];
        final p2 = coords[i + 1];
        final p3 = i < coords.length - 2 ? coords[i + 2] : p2;

        final cp1x = p1.dx + (p2.dx - p0.dx) / 5.0;
        final cp1y = p1.dy + (p2.dy - p0.dy) / 5.0;
        final cp2x = p2.dx - (p3.dx - p1.dx) / 5.0;
        final cp2y = p2.dy - (p3.dy - p1.dy) / 5.0;

        linePath.cubicTo(cp1x, cp1y, cp2x, cp2y, p2.dx, p2.dy);
      }

      final fillPath = Path.from(linePath);
      fillPath.lineTo(width, topMargin + chartHeight);
      fillPath.lineTo(0, topMargin + chartHeight);
      fillPath.close();

      final fillPaint = Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, topMargin),
          Offset(0, topMargin + chartHeight),
          [
            primaryColor.withValues(alpha: 0.28),
            primaryColor.withValues(alpha: 0.0),
          ],
        )
        ..style = PaintingStyle.fill;
      canvas.drawPath(fillPath, fillPaint);

      final strokePaint = Paint()
        ..color = primaryColor
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      canvas.drawPath(linePath, strokePaint);
    }

    final activeOffset = points.length == 1
        ? coords.last
        : coords[selectedIndex.clamp(0, coords.length - 1)];

    final guidePaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.35)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    _drawDashedLine(
      canvas,
      Offset(activeOffset.dx, topMargin),
      Offset(activeOffset.dx, topMargin + chartHeight),
      guidePaint,
    );

    final haloPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(activeOffset, 9, haloPaint);

    final dotBorderPaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    final dotFillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(activeOffset, 5, dotFillPaint);
    canvas.drawCircle(activeOffset, 5, dotBorderPaint);
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const dashHeight = 4.0;
    const dashSpace = 3.0;
    var startY = p1.dy;
    while (startY < p2.dy) {
      canvas.drawLine(
        Offset(p1.dx, startY),
        Offset(p1.dx, (startY + dashHeight).clamp(p1.dy, p2.dy)),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(_LineChartPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.maximum != maximum ||
      oldDelegate.selectedIndex != selectedIndex ||
      oldDelegate.primaryColor != primaryColor;
}
