import 'package:flutter/material.dart';

import '../../../app_services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/cosmetics.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/coin_badge.dart';

/// Spend coins on tube styles and backgrounds, and choose which to use.
class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key, required this.services});

  final AppServices services;

  void _onTap(BuildContext context, Cosmetic item) {
    final cosmetics = services.cosmetics;
    if (cosmetics.owns(item)) {
      cosmetics.select(item);
      return;
    }
    if (cosmetics.buy(item)) {
      cosmetics.select(item);
      return;
    }
    final missing = item.price - services.progress.coins;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('You need $missing more coins for ${item.label}.'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final cosmetics = services.cosmetics;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Shop'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: ListenableBuilder(
                listenable: services.progress,
                builder: (_, _) => CoinBadge(coins: services.progress.coins),
              ),
            ),
          ),
        ],
      ),
      body: AppBackground(
        child: SafeArea(
          child: ListenableBuilder(
            listenable: cosmetics,
            builder: (context, _) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const _SectionTitle('Tube styles'),
                _ItemGrid(
                  children: [
                    for (final s in TubeStyle.values)
                      _ItemCard(
                        item: s,
                        owned: cosmetics.owns(s),
                        selected: cosmetics.isSelected(s),
                        onTap: () => _onTap(context, s),
                        preview: CustomPaint(painter: _TubePreview(s)),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                const _SectionTitle('Backgrounds'),
                _ItemGrid(
                  children: [
                    for (final b in BackgroundTheme.values)
                      _ItemCard(
                        item: b,
                        owned: cosmetics.owns(b),
                        selected: cosmetics.isSelected(b),
                        onTap: () => _onTap(context, b),
                        preview: DecoratedBox(
                          decoration: b.decoration.copyWith(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white24),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
    ),
  );
}

class _ItemGrid extends StatelessWidget {
  const _ItemGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => GridView.count(
    crossAxisCount: 3,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    mainAxisSpacing: 10,
    crossAxisSpacing: 10,
    childAspectRatio: 0.68,
    children: children,
  );
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.item,
    required this.owned,
    required this.selected,
    required this.onTap,
    required this.preview,
  });

  final Cosmetic item;
  final bool owned, selected;
  final VoidCallback onTap;
  final Widget preview;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? AppColors.star : Colors.transparent,
          width: 2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Expanded(child: SizedBox.expand(child: preview)),
              const SizedBox(height: 8),
              Text(
                item.label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 28,
                child: Center(
                  child: owned
                      ? Text(
                          selected ? 'In use' : 'Tap to use',
                          style: TextStyle(
                            fontSize: 13,
                            color: selected ? AppColors.star : Colors.white70,
                          ),
                        )
                      : CoinBadge(coins: item.price, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single half-filled tube drawn in the given style.
class _TubePreview extends CustomPainter {
  _TubePreview(this.style);

  final TubeStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height * 0.92;
    final w = h / 3.2;
    final r = Rect.fromLTWH((size.width - w) / 2, (size.height - h) / 2, w, h);
    final body = style.body(r);
    canvas.save();
    canvas.clipPath(Path.from(body)..close());
    canvas.drawRect(r, Paint()..color = const Color(0x22FFFFFF));
    final unit = h * 0.22;
    for (var i = 0; i < 3; i++) {
      canvas.drawRect(
        Rect.fromLTWH(r.left, r.bottom - (i + 1) * unit, w, unit + 0.5),
        Paint()..color = AppColors.liquids[[1, 3, 0][i]],
      );
    }
    canvas.restore();
    canvas.drawPath(
      body,
      Paint()
        ..color = const Color(0xE6FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_TubePreview old) => old.style != style;
}
