import '../../../data/progress_repository.dart';
import '../../achievements/domain/achievement.dart';
import '../../game/domain/difficulty.dart';
import 'milestones.dart';

/// Everything the share poster shows.
class PosterData {
  const PosterData({
    required this.headline,
    required this.subline,
    required this.shareText,
    required this.stars,
    required this.totalStars,
    required this.coins,
    this.milestone,
    this.playerName,
    this.playerPhoto,
  });

  /// Poster for a milestone [level] of [d], using the player's saved totals.
  factory PosterData.forMilestone(
    ProgressRepository progress,
    Difficulty d,
    int level, {
    String? playerName,
    String? playerPhoto,
  }) {
    final finished = d.isLastLevel(level);
    return PosterData(
      headline: finished ? '${d.label} complete!' : 'Level $level cleared!',
      subline: finished
          ? 'All ${d.levelCount} levels solved'
          : '${d.label} · ${d.levelCount - level} levels to go',
      shareText: finished
          ? 'I finished all ${d.levelCount} ${d.label} levels '
                'in Tint Tubes: Color Sort Puzzle! Can you beat me?'
          : 'I cleared level $level on ${d.label} '
                'in Tint Tubes: Color Sort Puzzle! Can you beat me?',
      stars: progress.starsFor(d, level),
      totalStars: progress.allStars,
      coins: progress.coins,
      milestone: (d, level),
      playerName: playerName,
      playerPhoto: playerPhoto,
    );
  }

  /// Poster for an unlocked achievement.
  factory PosterData.forAchievement(
    ProgressRepository progress,
    Achievement a, {
    String? playerName,
    String? playerPhoto,
  }) => PosterData(
    headline: a.title,
    subline: 'Achievement · ${a.description}',
    shareText:
        'I unlocked "${a.title}" in Tint Tubes: Color Sort Puzzle! '
        'Can you beat me?',
    stars: 3,
    totalStars: progress.allStars,
    coins: progress.coins,
    playerName: playerName,
    playerPhoto: playerPhoto,
  );

  /// Poster for the best milestone reached so far (hardest tier first), or
  /// null if the player has not reached one.
  static PosterData? latest(
    ProgressRepository progress, {
    String? playerName,
    String? playerPhoto,
  }) {
    for (final d in Difficulty.values.reversed) {
      if (!progress.isUnlocked(d)) continue;
      final level = lastMilestone(d, progress.completedLevels(d));
      if (level != null) {
        return PosterData.forMilestone(
          progress,
          d,
          level,
          playerName: playerName,
          playerPhoto: playerPhoto,
        );
      }
    }
    return null;
  }

  final String headline, subline;

  /// Caption sent along with the image.
  final String shareText;

  /// Stars lit in the big row (1-3).
  final int stars;

  /// Stars collected across every tier.
  final int totalStars;
  final int coins;

  /// The tier and level this poster celebrates, when it is a level
  /// milestone. Sharing one pays a one-off coin reward.
  final (Difficulty, int)? milestone;

  /// The player's nickname, shown on the poster when they gave one.
  final String? playerName;

  /// File path of the player's picture, shown on the poster when set.
  final String? playerPhoto;
}
