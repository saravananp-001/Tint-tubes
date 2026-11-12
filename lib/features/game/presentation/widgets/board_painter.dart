import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/cosmetics.dart';
import '../../domain/tube_rules.dart';
import 'board_layout.dart';

/// A pour in progress. The model is already updated when this exists; the
/// painter uses it to show the liquid still on its way.
class PourAnimation {
  const PourAnimation(this.from, this.to, this.color, this.count);
  final int from, to, color, count;
}

class BoardPainter extends CustomPainter {
  BoardPainter({
    required this.tubes,
    required this.selected,
    required this.previousSelected,
    required this.pour,
    required this.hint,
    required this.pourProgress,
    required this.selectProgress,
    this.tubeStyle = TubeStyle.classic,
    this.colorBlind = false,
    this.hidden,
  }) : super(repaint: Listenable.merge([pourProgress, selectProgress]));

  final Tubes tubes;
  final int? selected, previousSelected;
  final PourAnimation? pour;
  final List<int>? hint;
  final Animation<double> pourProgress, selectProgress;
  final TubeStyle tubeStyle;

  /// Draws a letter on each unit of liquid so colours differ by shape too.
  final bool colorBlind;

  /// On hidden-colour levels: how many units at the bottom of each tube are
  /// still unknown. Null on ordinary levels.
  final List<int>? hidden;

  /// Phases of a pour as fractions of the animation: the tube travels and
  /// tilts until [flowStart], liquid flows until [flowEnd], then it returns.
  static const flowStart = 0.3, flowEnd = 0.72;

  /// Colour id used for liquid that has not been revealed yet.
  static const _unknown = -1;

  static const _letters = 'ABCDEFGHIJKL';

  int _hiddenIn(int i) {
    final h = hidden;
    return h == null || i >= h.length ? 0 : h[i];
  }

  @override
  void paint(Canvas canvas, Size size) {
    final lay = BoardLayout.compute(size, tubes.length);
    final p = pour;
    final t = pourProgress.value;
    final flow = p == null
        ? 1.0
        : ((t - flowStart) / (flowEnd - flowStart)).clamp(0.0, 1.0);

    for (var i = 0; i < tubes.length; i++) {
      if (p != null && i == p.from) continue;
      var dy = 0.0;
      if (i == selected) dy = -lay.lift * selectProgress.value;
      if (i == previousSelected) dy = -lay.lift * (1 - selectProgress.value);
      final segs = _segments(tubes[i], _hiddenIn(i));
      final receiving = p != null && i == p.to;
      if (receiving) {
        segs.last = (segs.last.$1, segs.last.$2 - p.count * (1 - flow));
      }
      _drawTube(
        canvas,
        lay.rects[i].translate(0, dy),
        segs,
        capped: isComplete(tubes[i]) && !(receiving && flow < 1),
        glow: hint != null && hint!.contains(i),
      );
    }

    if (p != null) _drawPouringTube(canvas, lay, p, t, flow);
  }

  void _drawPouringTube(
    Canvas canvas,
    BoardLayout lay,
    PourAnimation p,
    double t,
    double flow,
  ) {
    final s = lay.rects[p.from], d = lay.rects[p.to];
    final w = lay.tubeWidth;
    final dir = d.center.dx >= s.center.dx ? 1.0 : -1.0;
    final travel = t < flowStart
        ? Curves.easeInOut.transform(t / flowStart)
        : (t > flowEnd
              ? 1 - Curves.easeInOut.transform((t - flowEnd) / (1 - flowEnd))
              : 1.0);
    final home = t > flowEnd ? s : s.translate(0, -lay.lift);
    final pivotHome = dir > 0 ? home.topRight : home.topLeft;
    final pivotDest = Offset(d.center.dx - dir * w * 0.2, d.top - w * 0.45);
    final pivot = Offset.lerp(pivotHome, pivotDest, travel)!;
    final angle = dir * travel * (0.95 + 0.5 * flow);

    if (flow > 0 && flow < 1) {
      final unit = d.height * _fillFraction / kTubeCapacity;
      final level = tubes[p.to].length - p.count * (1 - flow);
      final x = pivotDest.dx + dir * w * 0.05;
      canvas.drawLine(
        Offset(x, pivotDest.dy),
        Offset(x, d.bottom - level * unit),
        Paint()
          ..color = AppColors.liquids[p.color]
          ..strokeWidth = w * 0.13
          ..strokeCap = StrokeCap.round,
      );
    }

    final segs = _segments(tubes[p.from], _hiddenIn(p.from));
    final remaining = p.count * (1 - flow);
    if (remaining > 0) {
      if (segs.isNotEmpty && segs.last.$1 == p.color) {
        segs.last = (p.color, segs.last.$2 + remaining);
      } else {
        segs.add((p.color, remaining));
      }
    }
    canvas.save();
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(angle);
    canvas.translate(-pivotHome.dx, -pivotHome.dy);
    _drawTube(canvas, home, segs);
    canvas.restore();
  }

  /// Share of the tube height that a full load of liquid occupies.
  static const _fillFraction = 0.88;

  /// Merges neighbouring units of the same colour into (colour, units) runs.
  /// The lowest [hiddenCount] units count as [_unknown].
  List<(int, double)> _segments(List<int> tube, int hiddenCount) {
    final out = <(int, double)>[];
    for (var k = 0; k < tube.length; k++) {
      final c = k < hiddenCount ? _unknown : tube[k];
      if (out.isNotEmpty && out.last.$1 == c) {
        out.last = (c, out.last.$2 + 1);
      } else {
        out.add((c, 1.0));
      }
    }
    return out;
  }

  static final _labelCache = <String, TextPainter>{};

  void _drawLabel(Canvas canvas, String text, Offset center, double size) {
    final key = '$text-${size.round()}';
    final painter = _labelCache[key] ??= TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: size.roundToDouble(),
          fontWeight: FontWeight.w900,
          color: Colors.white,
          shadows: const [Shadow(color: Colors.black87, blurRadius: 3)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  void _drawTube(
    Canvas canvas,
    Rect r,
    List<(int, double)> segs, {
    bool capped = false,
    bool glow = false,
  }) {
    final body = tubeStyle.body(r);
    final closed = Path.from(body)..close();
    final neck = r.width * tubeStyle.neck;

    if (glow) {
      canvas.drawPath(
        closed,
        Paint()
          ..color = AppColors.hintGlow
          ..style = PaintingStyle.stroke
          ..strokeWidth = r.width * 0.28
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r.width * 0.18),
      );
    }

    canvas.drawPath(closed, Paint()..color = const Color(0x22FFFFFF));

    canvas.save();
    canvas.clipPath(closed);
    final unit = r.height * _fillFraction / kTubeCapacity;
    final labelSize = min(unit * 0.62, r.width * 0.6);
    var y = r.bottom;
    for (final (c, amount) in segs) {
      if (amount <= 0) continue;
      final h = amount * unit;
      final rect = Rect.fromLTRB(r.left, y - h, r.right, y + 0.5);
      final base = c == _unknown
          ? const Color(0xFF4B5070)
          : AppColors.liquids[c];
      canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            colors: [
              Color.lerp(base, Colors.white, 0.18)!,
              base,
              Color.lerp(base, Colors.black, 0.22)!,
            ],
            stops: const [0, 0.45, 1],
          ).createShader(rect),
      );
      if (c == _unknown || colorBlind) {
        final text = c == _unknown ? '?' : _letters[c % _letters.length];
        for (var k = 0; k < (amount + 0.001).floor(); k++) {
          _drawLabel(
            canvas,
            text,
            Offset(r.center.dx, y - (k + 0.5) * unit),
            labelSize,
          );
        }
      }
      y -= h;
    }
    if (y < r.bottom) {
      // Highlight on the liquid surface.
      canvas.drawRect(
        Rect.fromLTRB(r.left, y, r.right, y + r.width * 0.06),
        Paint()..color = const Color(0x55FFFFFF),
      );
    }
    // Glass reflection.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          r.left + r.width * 0.16 + neck,
          r.top + r.height * 0.08,
          r.width * 0.1,
          r.height * 0.7,
        ),
        Radius.circular(r.width * 0.05),
      ),
      Paint()..color = const Color(0x33FFFFFF),
    );
    canvas.restore();

    final stroke = Paint()
      ..color = const Color(0xE6FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(2.0, r.width * 0.055)
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(body, stroke);
    // Rim.
    canvas.drawLine(
      Offset(r.left + neck - r.width * 0.07, r.top),
      Offset(r.right - neck + r.width * 0.07, r.top),
      stroke..strokeWidth *= 1.5,
    );

    if (capped) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(
            r.left + neck + r.width * 0.06,
            r.top - r.width * 0.3,
            r.right - neck - r.width * 0.06,
            r.top + r.width * 0.16,
          ),
          Radius.circular(r.width * 0.1),
        ),
        Paint()..color = AppColors.cork,
      );
    }
  }

  @override
  bool shouldRepaint(BoardPainter oldDelegate) => true;
}
