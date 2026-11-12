import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/coin_badge.dart';
import '../../../achievements/domain/achievement.dart';

enum WinAction { replay, next }

/// Shown when a level is solved: star rating, coins earned, what to do next.
class WinDialog extends StatelessWidget {
  const WinDialog({
    super.key,
    required this.title,
    required this.moves,
    required this.stars,
    required this.coinsEarned,
    this.rewardLabel = 'Reward',
    this.nextLabel = 'Next level',
    this.achievements = const [],
    this.onShare,
  });

  final String title;
  final int moves, stars, coinsEarned;

  /// Caption in front of the coins, e.g. "Double reward" on heart levels.
  final String rewardLabel;

  /// Text of the main button.
  final String nextLabel;

  /// Achievements this solve unlocked.
  final List<Achievement> achievements;

  /// Set on milestone levels: opens the share poster. The dialog stays open.
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title, textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < 3; i++)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 350 + i * 250),
                  curve: Curves.elasticOut,
                  builder: (_, v, child) =>
                      Transform.scale(scale: v, child: child),
                  child: Icon(
                    Icons.star_rounded,
                    size: i == 1 ? 64 : 52,
                    color: i < stars ? AppColors.star : AppColors.starEmpty,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Solved in $moves moves'),
          const SizedBox(height: 14),
          if (coinsEarned > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('$rewardLabel  ', style: const TextStyle(fontSize: 16)),
                CoinBadge(coins: coinsEarned, fontSize: 18),
              ],
            )
          else
            Text(
              stars < 3
                  ? 'No new coins. Beat your best star rating to earn more.'
                  : 'You already collected every coin for this.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          for (final a in achievements)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(a.icon, color: AppColors.star, size: 22),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Achievement: ${a.title}  ',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  CoinBadge(coins: a.reward, fontSize: 14),
                ],
              ),
            ),
          if (onShare != null) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onShare,
              icon: const Icon(Icons.share_rounded),
              label: const Text('Share this milestone'),
            ),
          ],
        ],
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, WinAction.replay),
          child: const Text('Replay'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, WinAction.next),
          child: Text(nextLabel),
        ),
      ],
    );
  }
}
