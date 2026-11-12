import 'package:flutter/material.dart';

import '../../../app_services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/coin_badge.dart';
import '../../../core/widgets/profile_avatar.dart';
import '../../../data/daily_repository.dart';
import '../../../data/progress_repository.dart';
import '../../achievements/domain/achievement.dart';
import '../../achievements/presentation/achievements_screen.dart';
import '../../game/domain/difficulty.dart';
import '../../game/presentation/game_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../share/domain/poster_data.dart';
import '../../share/presentation/share_poster_screen.dart';
import '../../shop/presentation/shop_screen.dart';

/// Start screen: coins, daily gift and puzzle, and the three tiers.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.services});

  final AppServices services;

  ProgressRepository get progress => services.progress;

  void _open(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void _play(BuildContext context, Difficulty d) =>
      _open(context, GameScreen(services: services, difficulty: d));

  Future<void> _claimGift(BuildContext context) async {
    final daily = services.daily;
    if (!daily.giftAvailable) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Already collected today. Tomorrow pays ${daily.nextGift} coins.',
            ),
          ),
        );
      return;
    }
    final coins = daily.claimGift();
    final unlocked = services.achievements.recordDailyStreak(daily.streak);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(
          Icons.card_giftcard_rounded,
          size: 44,
          color: AppColors.coin,
        ),
        title: Text('Day ${daily.streak} gift'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CoinBadge(coins: coins, fontSize: 22),
            const SizedBox(height: 12),
            Text(
              'Come back tomorrow for ${daily.nextGift} coins. '
              'Missing a day starts the streak again.',
              textAlign: TextAlign.center,
            ),
            for (final Achievement a in unlocked)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  'Achievement: ${a.title}  +${a.reward}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Nice'),
          ),
        ],
      ),
    );
  }

  Future<void> _tryUnlock(BuildContext context, Difficulty d) async {
    final missing = d.unlockCost - progress.coins;
    if (missing > 0) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.lock_rounded, size: 40),
          title: Text('${d.label} is locked'),
          content: Text(
            'You need $missing more coins. Earn coins by collecting stars '
            'in the levels you have already opened.',
            textAlign: TextAlign.center,
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.lock_open_rounded, size: 40),
        title: Text('Unlock ${d.label}?'),
        content: Text(
          'This will spend ${d.unlockCost} of your coins.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Unlock'),
          ),
        ],
      ),
    );
    if (confirmed == true && progress.unlock(d) && context.mounted) {
      _play(context, d);
    }
  }

  @override
  Widget build(BuildContext context) {
    final daily = services.daily;
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: ListenableBuilder(
            listenable: Listenable.merge([progress, daily, services.profile]),
            builder: (context, _) => Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Settings',
                        onPressed: () =>
                            _open(context, SettingsScreen(services: services)),
                        icon: const Icon(Icons.settings_rounded),
                      ),
                      IconButton(
                        tooltip: 'Achievements',
                        onPressed: () => _open(
                          context,
                          AchievementsScreen(services: services),
                        ),
                        icon: const Icon(Icons.emoji_events_rounded),
                      ),
                      IconButton(
                        tooltip: 'Shop',
                        onPressed: () =>
                            _open(context, ShopScreen(services: services)),
                        icon: const Icon(Icons.palette_rounded),
                      ),
                      if (PosterData.latest(
                            progress,
                            playerName: services.profile.name,
                            playerPhoto: services.profile.photoPath,
                          )
                          case final poster?)
                        IconButton(
                          tooltip: 'Share your milestone',
                          onPressed: () => _open(
                            context,
                            SharePosterScreen(progress: progress, data: poster),
                          ),
                          icon: const Icon(Icons.share_rounded),
                        ),
                      const Spacer(),
                      CoinBadge(coins: progress.coins, fontSize: 18),
                    ],
                  ),
                  const Spacer(),
                  if (services.profile.name case final name?)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (services.profile.photoPath case final photo?)
                            Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: ProfileAvatar(photoPath: photo, size: 44),
                            ),
                          Text(
                            'Hi, $name!',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.star,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Text(
                    'Tint Tubes',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  const Text(
                    'Color Sort Puzzle',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      letterSpacing: 3,
                      color: Colors.white70,
                    ),
                  ),
                  const Spacer(),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _DailyCard(
                            icon: Icons.card_giftcard_rounded,
                            title: 'Daily gift',
                            subtitle: daily.giftAvailable
                                ? 'Day ${daily.streak + 1} · tap to collect'
                                : 'Collected · ${daily.streak}-day streak',
                            active: daily.giftAvailable,
                            trailing: daily.giftAvailable
                                ? CoinBadge(coins: daily.nextGift, fontSize: 13)
                                : null,
                            onTap: () => _claimGift(context),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DailyCard(
                            icon: Icons.today_rounded,
                            title: 'Daily puzzle',
                            subtitle: daily.puzzleSolvedToday
                                ? 'Solved · new one tomorrow'
                                : 'One new puzzle every day',
                            active: !daily.puzzleSolvedToday,
                            trailing: daily.puzzleSolvedToday
                                ? null
                                : const CoinBadge(
                                    coins: kDailyPuzzleReward,
                                    fontSize: 13,
                                  ),
                            onTap: () => _open(
                              context,
                              GameScreen(
                                services: services,
                                dailyDay: daily.today,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  for (final d in Difficulty.values)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _DifficultyCard(
                        difficulty: d,
                        unlocked: progress.isUnlocked(d),
                        level: progress.currentLevel(d),
                        stars: progress.totalStars(d),
                        onTap: () => progress.isUnlocked(d)
                            ? _play(context, d)
                            : _tryUnlock(context, d),
                      ),
                    ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DailyCard extends StatelessWidget {
  const _DailyCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.active,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title, subtitle;

  /// Whether there is still something to collect today.
  final bool active;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.panel : AppColors.panelDim,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    active ? icon : Icons.check_circle_rounded,
                    color: active ? AppColors.coin : Colors.white54,
                  ),
                  const Spacer(),
                  ?trailing,
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DifficultyCard extends StatelessWidget {
  const _DifficultyCard({
    required this.difficulty,
    required this.unlocked,
    required this.level,
    required this.stars,
    required this.onTap,
  });

  final Difficulty difficulty;
  final bool unlocked;
  final int level, stars;
  final VoidCallback onTap;

  static const _accents = {
    Difficulty.easy: Color(0xFF43A047),
    Difficulty.medium: Color(0xFFFB8C00),
    Difficulty.hard: Color(0xFFE53935),
  };

  @override
  Widget build(BuildContext context) {
    final accent = _accents[difficulty]!;
    return Material(
      color: unlocked ? AppColors.panel : AppColors.panelDim,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: unlocked ? 1 : 0.35),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  unlocked ? Icons.play_arrow_rounded : Icons.lock_rounded,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      difficulty.label,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      difficulty.blurb,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (unlocked)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Level $level / ${difficulty.levelCount}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: AppColors.star,
                        ),
                        Text(' $stars'),
                      ],
                    ),
                  ],
                )
              else
                CoinBadge(coins: difficulty.unlockCost),
            ],
          ),
        ),
      ),
    );
  }
}
