import 'package:flutter/material.dart';

/// Something the player can buy with coins and then switch on.
abstract interface class Cosmetic {
  /// Stable key used in saved data.
  String get id;
  String get label;

  /// Coins to buy it; 0 means owned from the start.
  int get price;
}

/// Shape of the tubes on the board.
enum TubeStyle implements Cosmetic {
  classic('Classic', 0),
  jar('Jar', 60),
  flask('Flask', 120);

  const TubeStyle(this.label, this.price);

  @override
  final String label;
  @override
  final int price;

  @override
  String get id => 'tube_$name';

  /// How far the opening is narrower than the body on each side, as a
  /// fraction of the tube width.
  double get neck => this == flask ? 0.2 : 0;

  /// Open outline of the glass inside [r], from the top-left of the opening
  /// round the bottom to the top-right.
  Path body(Rect r) {
    final w = r.width;
    switch (this) {
      case TubeStyle.classic:
        final rad = w / 2;
        return Path()
          ..moveTo(r.left, r.top)
          ..lineTo(r.left, r.bottom - rad)
          ..arcToPoint(
            Offset(r.right, r.bottom - rad),
            radius: Radius.circular(rad),
            clockwise: false,
          )
          ..lineTo(r.right, r.top);
      case TubeStyle.jar:
        final c = w * 0.24;
        return Path()
          ..moveTo(r.left, r.top)
          ..lineTo(r.left, r.bottom - c)
          ..arcToPoint(
            Offset(r.left + c, r.bottom),
            radius: Radius.circular(c),
            clockwise: false,
          )
          ..lineTo(r.right - c, r.bottom)
          ..arcToPoint(
            Offset(r.right, r.bottom - c),
            radius: Radius.circular(c),
            clockwise: false,
          )
          ..lineTo(r.right, r.top);
      case TubeStyle.flask:
        final n = w * neck;
        final y1 = r.top + r.height * 0.14;
        final y2 = r.top + r.height * 0.28;
        final mid = (y1 + y2) / 2;
        final rad = w / 2;
        return Path()
          ..moveTo(r.left + n, r.top)
          ..lineTo(r.left + n, y1)
          ..cubicTo(r.left + n, mid, r.left, mid, r.left, y2)
          ..lineTo(r.left, r.bottom - rad)
          ..arcToPoint(
            Offset(r.right, r.bottom - rad),
            radius: Radius.circular(rad),
            clockwise: false,
          )
          ..lineTo(r.right, y2)
          ..cubicTo(r.right, mid, r.right - n, mid, r.right - n, y1)
          ..lineTo(r.right - n, r.top);
    }
  }
}

/// Backdrop behind every screen.
enum BackgroundTheme implements Cosmetic {
  night('Night', 0, [Color(0xFF1B1F3B), Color(0xFF2B1B4A), Color(0xFF14142B)]),
  ocean('Ocean', 40, [Color(0xFF0B2A4A), Color(0xFF0E4D64), Color(0xFF071A2E)]),
  sunset('Sunset', 80, [
    Color(0xFF4A1942),
    Color(0xFF8A2F4B),
    Color(0xFF2B1230),
  ]),
  forest('Forest', 80, [
    Color(0xFF0F2E24),
    Color(0xFF1E4D3A),
    Color(0xFF0A1C17),
  ]);

  const BackgroundTheme(this.label, this.price, this.colors);

  @override
  final String label;
  @override
  final int price;
  final List<Color> colors;

  @override
  String get id => 'bg_$name';

  BoxDecoration get decoration => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: colors,
    ),
  );
}
