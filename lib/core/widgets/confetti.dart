import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/cosmetics.dart';
import 'app_background.dart';

/// A single burst of confetti falling over whatever is underneath, in
/// the style the player has chosen unless [style] is given.
class Confetti extends StatefulWidget {
  const Confetti({super.key, this.style});

  final ConfettiStyle? style;

  @override
  State<Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<Confetti>
    with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..forward();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style =
        widget.style ??
        context
            .dependOnInheritedWidgetOfExactType<CosmeticsScope>()
            ?.notifier
            ?.confetti ??
        ConfettiStyle.classic;
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _ConfettiPainter(_ctrl, style),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.progress, this.style) : super(repaint: progress);

  final Animation<double> progress;
  final ConfettiStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    final random = Random(3);
    final paint = Paint();
    for (var i = 0; i < 110; i++) {
      final x0 = random.nextDouble() * size.width;
      final drift = (random.nextDouble() - 0.5) * size.width * 0.5;
      final delay = random.nextDouble() * 0.3;
      final speed = 0.8 + random.nextDouble() * 0.7;
      final spin = (random.nextDouble() - 0.5) * 18;
      final w = 6 + random.nextDouble() * 6;
      final color = AppColors.liquids[random.nextInt(8)];
      final local = ((t - delay) / (1 - delay)).clamp(0.0, 1.0);
      if (local <= 0) continue;
      final y = -20 + local * speed * (size.height + 40);
      final x = x0 + drift * local + sin(local * 9 + i) * 12;
      paint.color = color.withValues(alpha: 1 - Curves.easeIn.transform(local));
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(spin * local);
      canvas.drawPath(style.piece(w), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => false;
}
