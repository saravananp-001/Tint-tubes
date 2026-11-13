import 'package:flutter/material.dart';

import '../../../app_services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_background.dart';
import '../../../data/stats_repository.dart';
import '../../game/domain/difficulty.dart';
import '../../profile/domain/player_rank.dart';

/// The player's level and lifetime numbers.
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final stats = services.stats;
    final progress = services.progress;
    final rank = PlayerRank.of(progress, stats);
    final perfect = Difficulty.values.fold(
      0,
      (sum, d) => sum + progress.perfectLevels(d),
    );
    final rows = <(IconData, String, String)>[
      (Icons.star_rounded, 'Stars collected', '${progress.allStars}'),
      (Icons.workspace_premium_rounded, '3-star levels', '$perfect'),
      (
        Icons.check_circle_rounded,
        Stat.solves.label,
        '${stats.value(Stat.solves)}',
      ),
      (Icons.today_rounded, Stat.dailies.label, '${stats.value(Stat.dailies)}'),
      (
        Icons.local_fire_department_rounded,
        Stat.bestStreak.label,
        '${stats.value(Stat.bestStreak)} days',
      ),
      (
        Icons.timer_rounded,
        Stat.rushBest.label,
        '${stats.value(Stat.rushBest)}',
      ),
      (
        Icons.replay_rounded,
        Stat.rushGames.label,
        '${stats.value(Stat.rushGames)}',
      ),
      (
        Icons.sports_kabaddi_rounded,
        Stat.challengesWon.label,
        '${stats.value(Stat.challengesWon)}',
      ),
      (
        Icons.water_drop_rounded,
        Stat.pours.label,
        '${stats.value(Stat.pours)}',
      ),
      (Icons.lightbulb_rounded, Stat.hints.label, '${stats.value(Stat.hints)}'),
      (Icons.hourglass_bottom_rounded, Stat.seconds.label, stats.timePlayed),
    ];
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Statistics'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: AppBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.panel,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text(
                      'Level ${rank.level}',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      rank.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.star,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: rank.progress,
                        minHeight: 10,
                        color: AppColors.star,
                        backgroundColor: AppColors.starEmpty,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${rank.xpToNext} XP to level ${rank.level + 1}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Stars, daily puzzles, Rush scores and challenge '
                      'wins all earn XP.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.white54),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              for (final (icon, label, value) in rows)
                ListTile(
                  leading: Icon(icon, color: AppColors.star),
                  title: Text(label),
                  trailing: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
