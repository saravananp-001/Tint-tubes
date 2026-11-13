import 'dart:math';

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

/// What falls when a level is won.
enum ConfettiStyle implements Cosmetic {
  classic('Confetti', 0),
  stars('Stars', 50),
  bubbles('Bubbles', 50),
  hearts('Hearts', 70);

  const ConfettiStyle(this.label, this.price);

  @override
  final String label;
  @override
  final int price;

  @override
  String get id => 'confetti_$name';

  /// One piece of this style, centred on the origin and [size] across.
  Path piece(double size) {
    final r = size / 2;
    switch (this) {
      case ConfettiStyle.classic:
        return Path()..addRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: size,
            height: size * 0.55,
          ),
        );
      case ConfettiStyle.bubbles:
        return Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: r));
      case ConfettiStyle.stars:
        final path = Path();
        for (var i = 0; i < 10; i++) {
          final radius = i.isEven ? r * 1.3 : r * 0.55;
          final a = -pi / 2 + i * pi / 5;
          final p = Offset(cos(a) * radius, sin(a) * radius);
          i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
        }
        return path..close();
      case ConfettiStyle.hearts:
        final s = r * 1.3;
        return Path()
          ..moveTo(0, s * 0.9)
          ..cubicTo(-s * 1.6, -s * 0.2, -s * 0.6, -s * 1.2, 0, -s * 0.4)
          ..cubicTo(s * 0.6, -s * 1.2, s * 1.6, -s * 0.2, 0, s * 0.9)
          ..close();
    }
  }
}

/// The part of the year a seasonal item is on sale, as month and day.
class Season {
  const Season(this.fromMonth, this.fromDay, this.toMonth, this.toDay);

  final int fromMonth, fromDay, toMonth, toDay;

  /// Whether [date] falls inside the season, which may run over New Year.
  bool includes(DateTime date) {
    final d = date.month * 100 + date.day;
    final from = fromMonth * 100 + fromDay;
    final to = toMonth * 100 + toDay;
    return from <= to ? d >= from && d <= to : d >= from || d <= to;
  }

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// Last day on sale, e.g. "20 Nov".
  String get ends => '$toDay ${_months[toMonth - 1]}';
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
  ]),
  aurora('Aurora', 100, [
    Color(0xFF0B1E3F),
    Color(0xFF1B6B6F),
    Color(0xFF3B1E6B),
  ]),
  candy('Candy', 100, [
    Color(0xFF5B1E5E),
    Color(0xFFB03A7A),
    Color(0xFF3A1B5C),
  ]),
  // Seasonal: on sale only for part of the year, kept for good once bought.
  lights('Festival', 60, [
    Color(0xFF3B0F2E),
    Color(0xFF9C4A12),
    Color(0xFF2A0E3A),
  ], season: Season(10, 10, 11, 20)),
  winter('Winter', 60, [
    Color(0xFF0E2A4D),
    Color(0xFF4F7FA8),
    Color(0xFF0A1B33),
  ], season: Season(12, 10, 1, 10)),
  spring('Spring', 60, [
    Color(0xFF5A1E6B),
    Color(0xFF1E8A6B),
    Color(0xFF8A3A1E),
  ], season: Season(3, 1, 3, 31)),
  summer('Summer', 60, [
    Color(0xFF0E5A7A),
    Color(0xFFC77A1E),
    Color(0xFF0B3550),
  ], season: Season(5, 15, 6, 30));

  const BackgroundTheme(this.label, this.price, this.colors, {this.season});

  /// When this theme can be bought; null means always.
  final Season? season;

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
