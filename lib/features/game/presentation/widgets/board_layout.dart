import 'dart:math';
import 'dart:ui';

/// Where each tube sits on the board.
class BoardLayout {
  BoardLayout._(this.rects, this.tubeWidth, this.lift);

  factory BoardLayout.compute(Size size, int tubeCount) {
    final rows = switch (tubeCount) {
      <= 5 => 1,
      <= 12 => 2,
      <= 18 => 3,
      _ => 4,
    };
    final perRow = (tubeCount / rows).ceil();
    var w = min(size.width / perRow * 0.58, 58.0);
    double rowHeight(double w) => w * (_aspect + 0.6 + 0.7);
    final total = rows * rowHeight(w);
    if (total > size.height) w *= size.height / total;
    final lift = w * 0.6;
    final rh = rowHeight(w);
    final top = (size.height - rows * rh) / 2;
    final slot = size.width / (perRow + 0.6);
    final rects = <Rect>[];
    for (var r = 0; r < rows; r++) {
      final count = min(perRow, tubeCount - r * perRow);
      final startX = (size.width - slot * count) / 2;
      for (var k = 0; k < count; k++) {
        final cx = startX + slot * (k + 0.5);
        final y = top + r * rh + lift + w * 0.35;
        rects.add(Rect.fromLTWH(cx - w / 2, y, w, w * _aspect));
      }
    }
    return BoardLayout._(rects, w, lift);
  }

  static const _aspect = 3.7; // tube height / width

  final List<Rect> rects;
  final double tubeWidth;

  /// How far a selected tube rises.
  final double lift;

  /// Index of the tube at [p], or null.
  int? hit(Offset p) {
    for (var i = 0; i < rects.length; i++) {
      if (rects[i].inflate(tubeWidth * 0.3).contains(p)) return i;
    }
    return null;
  }
}
