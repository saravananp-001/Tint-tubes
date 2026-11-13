import 'dart:math';

import '../../../data/progress_repository.dart';
import '../../../data/stats_repository.dart';

/// The player's level and title, worked out from what they have done.
/// Nothing is stored: the same progress always gives the same rank.
class PlayerRank {
  const PlayerRank(this.xp);

  factory PlayerRank.of(ProgressRepository progress, StatsRepository stats) =>
      PlayerRank(
        progress.allStars * 10 +
            stats.value(Stat.dailies) * 20 +
            stats.value(Stat.rushBest) * 5 +
            stats.value(Stat.challengesWon) * 10,
      );

  final int xp;

  /// XP needed to reach [level]: 0, 50, 200, 450, 800 ...
  static int xpFor(int level) => 50 * (level - 1) * (level - 1);

  int get level => 1 + sqrt(xp / 50).floor();

  /// How far through the current level the player is, 0 to 1.
  double get progress =>
      (xp - xpFor(level)) / (xpFor(level + 1) - xpFor(level));

  int get xpToNext => xpFor(level + 1) - xp;

  String get title => titleFor(level);

  static const _titles = [
    (1, 'Novice'),
    (3, 'Mixer'),
    (6, 'Blender'),
    (10, 'Alchemist'),
    (15, 'Chemist'),
    (22, 'Master Chemist'),
    (30, 'Colour Wizard'),
    (40, 'Tint Legend'),
  ];

  static String titleFor(int level) =>
      _titles.lastWhere((t) => level >= t.$1, orElse: () => _titles.first).$2;
}
