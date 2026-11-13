import 'dart:math';

import 'package:flutter/material.dart';

import '../../../app_services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/coin_badge.dart';
import '../../../core/widgets/confetti.dart';
import '../../../data/daily_repository.dart';
import '../../../data/spin_repository.dart';

/// The lucky wheel. A free spin is earned for every few new levels.
class SpinScreen extends StatefulWidget {
  const SpinScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<SpinScreen> createState() => _SpinScreenState();
}

class _SpinScreenState extends State<SpinScreen>
    with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  );
  double _from = 0, _to = 0;
  SpinPrize? _won;
  int _bursts = 0;

  SpinRepository get _spins => widget.services.spins;

  static final _sweep = 2 * pi / SpinRepository.prizes.length;

  double get _angle =>
      _from + (_to - _from) * Curves.easeOutCubic.transform(_ctrl.value);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _spin() async {
    if (_ctrl.isAnimating) return;
    final index = _spins.spin();
    if (index == null) return;
    widget.services.haptics.medium();
    setState(() {
      _won = null;
      _from = _angle % (2 * pi);
      // Five full turns, ending with the winning slice under the pointer.
      _to = 10 * pi - (index + 0.5) * _sweep;
    });
    await _ctrl.forward(from: 0);
    if (!mounted) return;
    widget.services.sound.playComplete();
    widget.services.haptics.heavy();
    setState(() {
      _won = SpinRepository.prizes[index];
      _bursts++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final won = _won;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Lucky spin'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: ListenableBuilder(
                listenable: widget.services.progress,
                builder: (_, _) =>
                    CoinBadge(coins: widget.services.progress.coins),
              ),
            ),
          ),
        ],
      ),
      body: AppBackground(
        child: SafeArea(
          child: Stack(
            children: [
              ListenableBuilder(
                listenable: _spins,
                builder: (context, _) => Column(
                  children: [
                    const Spacer(),
                    const Icon(
                      Icons.arrow_drop_down_rounded,
                      size: 56,
                      color: AppColors.star,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 36),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: AnimatedBuilder(
                          animation: _ctrl,
                          builder: (_, _) => Transform.rotate(
                            angle: _angle,
                            child: CustomPaint(painter: _WheelPainter()),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 56,
                      child: Center(
                        child: won == null
                            ? Text(
                                _spins.spins > 0
                                    ? 'You have ${_spins.spins} '
                                          '${_spins.spins == 1 ? 'spin' : 'spins'}'
                                    : 'Solve ${kLevelsPerSpin - _spins.levelsTowardsNext} '
                                          'more new levels for a spin',
                                style: const TextStyle(fontSize: 16),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'You won  ',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  if (won.isFreeze)
                                    const Text(
                                      'a streak freeze!',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF81D4FA),
                                      ),
                                    )
                                  else
                                    CoinBadge(coins: won.coins, fontSize: 20),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: _spins.spins > 0 && !_ctrl.isAnimating
                          ? _spin
                          : null,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 36,
                          vertical: 12,
                        ),
                        child: Text('Spin', style: TextStyle(fontSize: 20)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'A freeze won with a full stock pays '
                      '$kFreezeCost coins instead.',
                      style: TextStyle(fontSize: 12, color: Colors.white54),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
              if (_bursts > 0)
                Positioned.fill(child: Confetti(key: ValueKey(_bursts))),
            ],
          ),
        ),
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const prizes = SpinRepository.prizes;
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final sweep = 2 * pi / prizes.length;
    final rect = Rect.fromCircle(center: c, radius: r);
    for (var i = 0; i < prizes.length; i++) {
      final start = -pi / 2 + i * sweep;
      canvas.drawArc(
        rect,
        start,
        sweep,
        true,
        Paint()
          ..color = prizes[i].isFreeze
              ? const Color(0xFF4FC3F7)
              : AppColors.liquids[i % 8].withValues(alpha: 0.9),
      );
      final text = TextPainter(
        text: TextSpan(
          text: prizes[i].label,
          style: TextStyle(
            fontSize: r * (prizes[i].isFreeze ? 0.12 : 0.17),
            fontWeight: FontWeight.w900,
            color: Colors.white,
            shadows: const [Shadow(blurRadius: 3)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final mid = start + sweep / 2;
      canvas.save();
      canvas.translate(c.dx + cos(mid) * r * 0.66, c.dy + sin(mid) * r * 0.66);
      canvas.rotate(mid + pi / 2);
      text.paint(canvas, Offset(-text.width / 2, -text.height / 2));
      canvas.restore();
    }
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = Colors.white,
    );
    canvas.drawCircle(c, r * 0.1, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_WheelPainter old) => false;
}
