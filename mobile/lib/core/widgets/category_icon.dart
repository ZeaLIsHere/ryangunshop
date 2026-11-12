import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Ikon kategori produk yang digambar langsung dengan [CustomPainter].
///
/// Empat kategori bawaan: Sembako (karung beras), Makanan (mangkuk + uap),
/// Minuman (gelas + sedotan), Kebutuhan (tas belanja). Kategori lain
/// menampilkan ikon lingkaran dengan huruf pertama.
class CategoryIcon extends StatelessWidget {
  const CategoryIcon({required this.category, this.size = 40, super.key});

  final String category;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        size: Size.square(size),
        painter: _CategoryPainter(category: category),
      ),
    );
  }

  /// Warna latar kategori, berguna untuk badge atau chip di luar ikon.
  static Color backgroundColor(String category) =>
      _CategoryPainter._config(category).bg;
}

class _CategoryPainter extends CustomPainter {
  _CategoryPainter({required this.category});

  final String category;

  @override
  void paint(Canvas canvas, Size size) {
    final cfg = _config(category);
    final s = size.shortestSide;

    // Latar lingkaran pastel.
    canvas.drawCircle(size.center(Offset.zero), s / 2, Paint()..color = cfg.bg);

    cfg.draw(canvas, size, s);
  }

  @override
  bool shouldRepaint(_CategoryPainter old) => old.category != category;

  static _CategoryConfig _config(String category) {
    return switch (category.toLowerCase()) {
      'sembako' => _CategoryConfig(
        bg: const Color(0xFFFFF7ED),
        fg: const Color(0xFFEA580C),
        draw: _drawSembako,
      ),
      'makanan' => _CategoryConfig(
        bg: const Color(0xFFFEF2F2),
        fg: const Color(0xFFDC2626),
        draw: _drawMakanan,
      ),
      'minuman' => _CategoryConfig(
        bg: const Color(0xFFEFF6FF),
        fg: const Color(0xFF2563EB),
        draw: _drawMinuman,
      ),
      'kebutuhan' => _CategoryConfig(
        bg: const Color(0xFFF0FDF4),
        fg: const Color(0xFF16A34A),
        draw: _drawKebutuhan,
      ),
      _ => _CategoryConfig(
        bg: AppColors.primaryLight,
        fg: AppColors.primary,
        draw: _drawFallback(category),
      ),
    };
  }
}

class _CategoryConfig {
  const _CategoryConfig({
    required this.bg,
    required this.fg,
    required this.draw,
  });

  final Color bg;
  final Color fg;
  final void Function(Canvas canvas, Size size, double s) draw;
}

// ---------------------------------------------------------------------------
// Sembako — karung beras sederhana
// ---------------------------------------------------------------------------
void _drawSembako(Canvas canvas, Size size, double s) {
  final paint = Paint()
    ..color = const Color(0xFFEA580C)
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.065
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  final cx = size.width / 2;
  final cy = size.height / 2;

  // Badan karung — trapesium membulat.
  final body = Path()
    ..moveTo(cx - s * 0.22, cy - s * 0.10)
    ..lineTo(cx - s * 0.26, cy + s * 0.22)
    ..quadraticBezierTo(cx, cy + s * 0.30, cx + s * 0.26, cy + s * 0.22)
    ..lineTo(cx + s * 0.22, cy - s * 0.10)
    ..close();
  canvas.drawPath(body, paint);

  // Ikatan atas.
  canvas.drawLine(
    Offset(cx - s * 0.14, cy - s * 0.10),
    Offset(cx + s * 0.14, cy - s * 0.10),
    paint,
  );

  // Mulut karung — kurva ke atas.
  final mouth = Path()
    ..moveTo(cx - s * 0.14, cy - s * 0.10)
    ..quadraticBezierTo(cx, cy - s * 0.28, cx + s * 0.14, cy - s * 0.10);
  canvas.drawPath(mouth, paint);

  // Butiran beras — tiga titik kecil.
  final dot = Paint()
    ..color = const Color(0xFFEA580C)
    ..style = PaintingStyle.fill;
  final r = s * 0.025;
  canvas.drawCircle(Offset(cx, cy + s * 0.06), r, dot);
  canvas.drawCircle(Offset(cx - s * 0.08, cy + s * 0.12), r, dot);
  canvas.drawCircle(Offset(cx + s * 0.08, cy + s * 0.12), r, dot);
}

// ---------------------------------------------------------------------------
// Makanan — mangkuk dengan uap
// ---------------------------------------------------------------------------
void _drawMakanan(Canvas canvas, Size size, double s) {
  final paint = Paint()
    ..color = const Color(0xFFDC2626)
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.065
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  final cx = size.width / 2;
  final cy = size.height / 2;

  // Mangkuk — setengah lingkaran bawah.
  final bowl = Path()
    ..moveTo(cx - s * 0.26, cy + s * 0.02)
    ..quadraticBezierTo(cx, cy + s * 0.34, cx + s * 0.26, cy + s * 0.02);
  canvas.drawPath(bowl, paint);

  // Bibir mangkuk.
  canvas.drawLine(
    Offset(cx - s * 0.28, cy + s * 0.02),
    Offset(cx + s * 0.28, cy + s * 0.02),
    paint,
  );

  // Uap — tiga gelombang.
  final steamPaint = Paint()
    ..color = const Color(0xFFDC2626).withValues(alpha: 0.5)
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.045
    ..strokeCap = StrokeCap.round;

  for (final dx in [-s * 0.10, 0.0, s * 0.10]) {
    final steam = Path()
      ..moveTo(cx + dx, cy - s * 0.06)
      ..quadraticBezierTo(
        cx + dx + s * 0.04,
        cy - s * 0.14,
        cx + dx,
        cy - s * 0.22,
      );
    canvas.drawPath(steam, steamPaint);
  }
}

// ---------------------------------------------------------------------------
// Minuman — gelas dengan sedotan
// ---------------------------------------------------------------------------
void _drawMinuman(Canvas canvas, Size size, double s) {
  final paint = Paint()
    ..color = const Color(0xFF2563EB)
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.065
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  final cx = size.width / 2;
  final cy = size.height / 2;

  // Badan gelas — trapesium menyempit ke bawah.
  final glass = Path()
    ..moveTo(cx - s * 0.20, cy - s * 0.16)
    ..lineTo(cx - s * 0.14, cy + s * 0.24)
    ..lineTo(cx + s * 0.14, cy + s * 0.24)
    ..lineTo(cx + s * 0.20, cy - s * 0.16)
    ..close();
  canvas.drawPath(glass, paint);

  // Isi gelas — area berwarna muda.
  final fill = Path()
    ..moveTo(cx - s * 0.17, cy + s * 0.02)
    ..lineTo(cx - s * 0.14, cy + s * 0.24)
    ..lineTo(cx + s * 0.14, cy + s * 0.24)
    ..lineTo(cx + s * 0.17, cy + s * 0.02)
    ..close();
  canvas.drawPath(
    fill,
    Paint()..color = const Color(0xFF2563EB).withValues(alpha: 0.15),
  );

  // Sedotan — garis miring.
  canvas.drawLine(
    Offset(cx + s * 0.06, cy - s * 0.28),
    Offset(cx - s * 0.02, cy + s * 0.10),
    paint,
  );
}

// ---------------------------------------------------------------------------
// Kebutuhan — tas belanja
// ---------------------------------------------------------------------------
void _drawKebutuhan(Canvas canvas, Size size, double s) {
  final paint = Paint()
    ..color = const Color(0xFF16A34A)
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.065
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  final cx = size.width / 2;
  final cy = size.height / 2;

  // Badan tas — persegi panjang membulat.
  final bag = RRect.fromRectAndRadius(
    Rect.fromCenter(
      center: Offset(cx, cy + s * 0.06),
      width: s * 0.44,
      height: s * 0.38,
    ),
    Radius.circular(s * 0.06),
  );
  canvas.drawRRect(bag, paint);

  // Pegangan — setengah lingkaran atas.
  final handle = Path()
    ..moveTo(cx - s * 0.10, cy - s * 0.12)
    ..quadraticBezierTo(cx, cy - s * 0.32, cx + s * 0.10, cy - s * 0.12);
  canvas.drawPath(handle, paint);

  // Tanda plus kecil di tengah tas.
  final plus = Paint()
    ..color = const Color(0xFF16A34A)
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.05
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(Offset(cx, cy + s * 0.00), Offset(cx, cy + s * 0.14), plus);
  canvas.drawLine(
    Offset(cx - s * 0.07, cy + s * 0.07),
    Offset(cx + s * 0.07, cy + s * 0.07),
    plus,
  );
}

// ---------------------------------------------------------------------------
// Fallback — lingkaran dengan huruf pertama
// ---------------------------------------------------------------------------
void Function(Canvas, Size, double) _drawFallback(String category) {
  return (Canvas canvas, Size size, double s) {
    final letter = category.isNotEmpty ? category[0].toUpperCase() : '?';
    final tp = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(
          color: AppColors.primary,
          fontSize: s * 0.38,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2),
    );
  };
}
