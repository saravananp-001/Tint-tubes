import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Heart-shaped bottle shown on heart levels. It fills as tubes are
/// completed, so it doubles as the level's progress meter.
class HeartBottle extends StatelessWidget {
  const HeartBottle({
    super.key,
    required this.completed,
    required this.total,
    this.height = 104,
  });

  /// Tubes finished so far, and tubes to finish in all.
  final int completed, total;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(end: total == 0 ? 0 : completed / total),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          builder: (_, fill, _) => CustomPaint(
            size: Size(height * 0.95, height),
            painter: _HeartBottlePainter(fill),
          ),
        ),
        const SizedBox(width: 14),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'HEART LEVEL',
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 2,
                color: AppColors.heart,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              '$completed / $total',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            ),
            const Text(
              'tubes filled · double coins',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeartBottlePainter extends CustomPainter {
  _HeartBottlePainter(this.fill);

  /// 0 (empty) to 1 (full).
  final double fill;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = max(2.0, size.width * 0.035);
    final neckH = size.height * 0.2;
    // The heart sits below the neck, inset so the outline is not clipped.
    final body = Rect.fromLTRB(
      stroke,
      neckH,
      size.width - stroke,
      size.height - stroke,
    );
    final heart = _heartPath(body);
    final cx = size.width / 2;
    final neckW = size.width * 0.2;
    final neck = Rect.fromLTRB(
      cx - neckW / 2,
      size.height * 0.07,
      cx + neckW / 2,
      body.top + body.height * 0.2,
    );

    final glass = Paint()..color = const Color(0x22FFFFFF);
    canvas.drawRect(neck, glass);
    canvas.drawPath(heart, glass);

    // Liquid.
    canvas.save();
    canvas.clipPath(heart);
    final level = body.bottom - body.height * fill.clamp(0.0, 1.0);
    final liquid = Rect.fromLTRB(body.left, level, body.right, body.bottom);
    if (fill > 0) {
      canvas.drawRect(
        liquid,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFF6FA5), AppColors.heart, Color(0xFFB0124F)],
          ).createShader(body),
      );
      canvas.drawRect(
        Rect.fromLTWH(body.left, level, body.width, stroke * 0.8),
        Paint()..color = const Color(0x66FFFFFF),
      );
    }
    // Glass reflection on the left lobe.
    canvas.drawArc(
      Rect.fromLTWH(
        body.left + body.width * 0.1,
        body.top + body.height * 0.1,
        body.width * 0.34,
        body.height * 0.4,
      ),
      pi * 1.05,
      pi * 0.42,
      false,
      Paint()
        ..color = const Color(0x77FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke * 1.3,
    );
    canvas.restore();

    final outline = Paint()
      ..color = const Color(0xE6FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(heart, outline);
    canvas.drawLine(neck.topLeft, neck.bottomLeft, outline);
    canvas.drawLine(neck.topRight, neck.bottomRight, outline);

    // Cork.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(
          neck.left - stroke,
          0,
          neck.right + stroke,
          size.height * 0.11,
        ),
        Radius.circular(stroke),
      ),
      Paint()..color = AppColors.cork,
    );
  }

  Path _heartPath(Rect r) {
    double x(double v) => r.left + r.width * v;
    double y(double v) => r.top + r.height * v;
    return Path()
      ..moveTo(x(0.5), y(0.25))
      ..cubicTo(x(0.5), y(0.1), x(0.35), y(0), x(0.22), y(0))
      ..cubicTo(x(0.08), y(0), x(0), y(0.14), x(0), y(0.3))
      ..cubicTo(x(0), y(0.55), x(0.3), y(0.75), x(0.5), y(1))
      ..cubicTo(x(0.7), y(0.75), x(1), y(0.55), x(1), y(0.3))
      ..cubicTo(x(1), y(0.14), x(0.92), y(0), x(0.78), y(0))
      ..cubicTo(x(0.65), y(0), x(0.5), y(0.1), x(0.5), y(0.25))
      ..close();
  }

  @override
  bool shouldRepaint(_HeartBottlePainter oldDelegate) =>
      oldDelegate.fill != fill;
}
