import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/profile_avatar.dart';
import '../../domain/poster_data.dart';

/// Shape of the shared image.
enum PosterFormat {
  /// 9:16, for WhatsApp status and Instagram stories.
  story(Size(360, 640), 'Story'),

  /// 1:1, for Instagram posts and chats.
  post(Size(360, 360), 'Post');

  const PosterFormat(this.size, this.label);

  /// Logical size; captured at 3x this gives 1080 px wide images.
  final Size size;
  final String label;
}

/// The milestone poster. [intro] (0→1) drives the entrance: tubes fill,
/// stars pop, numbers count up. [twinkle] loops for the sparkles.
class SharePoster extends StatelessWidget {
  const SharePoster({
    super.key,
    required this.data,
    required this.format,
    required this.intro,
    required this.twinkle,
  });

  final PosterData data;
  final PosterFormat format;
  final Animation<double> intro, twinkle;

  static double _phase(double t, double from, double to) =>
      ((t - from) / (to - from)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final compact = format == PosterFormat.post;
    final s = compact ? 0.72 : 1.0;
    return SizedBox.fromSize(
      size: format.size,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6875D6), Color(0xFF3A2A78), Color(0xFF1B1238)],
          ),
        ),
        child: AnimatedBuilder(
          animation: Listenable.merge([intro, twinkle]),
          builder: (context, _) {
            final t = intro.value;
            final count = Curves.easeOut.transform(_phase(t, 0.45, 1));
            return Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _SparklePainter(twinkle.value, _phase(t, 0, 0.4)),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(22, 26 * s, 22, 20 * s),
                  child: Column(
                    children: [
                      Text(
                        'TINT TUBES',
                        style: TextStyle(
                          fontSize: 20 * s,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 5,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      SizedBox(height: (compact ? 6 : 28) * s),
                      Opacity(
                        opacity: _phase(t, 0, 0.25),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            data.headline,
                            style: TextStyle(
                              fontSize: 40 * s,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              shadows: const [
                                Shadow(color: Colors.black38, blurRadius: 12),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 6 * s),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14 * s,
                          vertical: 5 * s,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          data.subline,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14 * s,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: (compact ? 16 : 26) * s,
                          ),
                          child: CustomPaint(
                            size: Size.infinite,
                            painter: _TubesPainter(_phase(t, 0.05, 0.6)),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < 3; i++)
                            Transform.scale(
                              scale: Curves.elasticOut.transform(
                                _phase(t, 0.4 + i * 0.1, 0.8 + i * 0.1),
                              ),
                              child: Icon(
                                Icons.star_rounded,
                                size: (i == 1 ? 76 : 60) * s,
                                color: i < data.stars
                                    ? AppColors.star
                                    : AppColors.starEmpty,
                                shadows: const [
                                  Shadow(color: Colors.black38, blurRadius: 10),
                                ],
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 12 * s),
                      Row(
                        children: [
                          Expanded(
                            child: _Stat(
                              icon: Icons.star_rounded,
                              color: AppColors.star,
                              value: (data.totalStars * count).round(),
                              label: 'stars',
                              scale: s,
                            ),
                          ),
                          SizedBox(width: 12 * s),
                          Expanded(
                            child: _Stat(
                              icon: Icons.monetization_on_rounded,
                              color: AppColors.coin,
                              value: (data.coins * count).round(),
                              label: 'coins',
                              scale: s,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 14 * s),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (data.playerPhoto case final photo?)
                            Padding(
                              padding: EdgeInsets.only(right: 8 * s),
                              child: ProfileAvatar(
                                photoPath: photo,
                                size: 30 * s,
                              ),
                            ),
                          Text(
                            data.playerName == null
                                ? 'Can you beat me?'
                                : 'Can you beat ${data.playerName}?',
                            style: TextStyle(
                              fontSize: 16 * s,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Tint Tubes: Color Sort Puzzle',
                        style: TextStyle(
                          fontSize: 11 * s,
                          letterSpacing: 1.5,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    required this.scale,
  });

  final IconData icon;
  final Color color;
  final int value;
  final String label;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 9 * scale),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 26 * scale),
          SizedBox(width: 6 * scale),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 22 * scale,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 5 * scale),
          Text(
            label,
            style: TextStyle(fontSize: 13 * scale, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

/// A row of sorted tubes that fill up one after another.
class _TubesPainter extends CustomPainter {
  _TubesPainter(this.fill);

  final double fill;

  static const _count = 5;

  @override
  void paint(Canvas canvas, Size size) {
    final tubeH = min(size.height, size.width / _count * 2.6);
    final tubeW = tubeH / 3.4;
    final gap = (size.width - tubeW * _count) / (_count + 1);
    final top = (size.height - tubeH) / 2;
    final glass = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(2, tubeW * 0.07)
      ..color = Colors.white.withValues(alpha: 0.85);
    for (var i = 0; i < _count; i++) {
      final rect = Rect.fromLTWH(gap + i * (tubeW + gap), top, tubeW, tubeH);
      final shape = RRect.fromRectAndCorners(
        rect,
        bottomLeft: Radius.circular(tubeW / 2),
        bottomRight: Radius.circular(tubeW / 2),
      );
      // Each tube starts a little after the one before it.
      final local = ((fill * 1.6) - i * 0.15).clamp(0.0, 1.0);
      final level = Curves.easeOutCubic.transform(local) * 0.86;
      canvas.save();
      canvas.clipRRect(shape);
      canvas.drawRect(
        rect,
        Paint()..color = Colors.white.withValues(alpha: 0.08),
      );
      canvas.drawRect(
        Rect.fromLTRB(
          rect.left,
          rect.bottom - tubeH * level,
          rect.right,
          rect.bottom,
        ),
        Paint()..color = AppColors.liquids[i],
      );
      // Soft highlight down the left side of the glass.
      canvas.drawRect(
        Rect.fromLTWH(rect.left + tubeW * 0.16, rect.top, tubeW * 0.14, tubeH),
        Paint()..color = Colors.white.withValues(alpha: 0.18),
      );
      canvas.restore();
      canvas.drawRRect(shape, glass);
    }
  }

  @override
  bool shouldRepaint(_TubesPainter old) => old.fill != fill;
}

/// Twinkling four-point sparkles scattered over the background.
class _SparklePainter extends CustomPainter {
  _SparklePainter(this.twinkle, this.appear);

  final double twinkle, appear;

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(11);
    final paint = Paint();
    for (var i = 0; i < 26; i++) {
      final center = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );
      final radius = 2.5 + random.nextDouble() * 5;
      final offset = random.nextDouble();
      final glow = 0.5 + 0.5 * sin((twinkle + offset) * 2 * pi);
      final r = radius * (0.6 + 0.4 * glow);
      paint.color = (i % 4 == 0 ? AppColors.star : Colors.white).withValues(
        alpha: appear * (0.15 + 0.55 * glow),
      );
      final path = Path()
        ..moveTo(center.dx, center.dy - r)
        ..quadraticBezierTo(center.dx, center.dy, center.dx + r, center.dy)
        ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + r)
        ..quadraticBezierTo(center.dx, center.dy, center.dx - r, center.dy)
        ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - r);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_SparklePainter old) =>
      old.twinkle != twinkle || old.appear != appear;
}
