/// What is uploaded for a player.
class PlayerSnapshot {
  const PlayerSnapshot({
    required this.name,
    required this.ageRange,
    required this.photoPath,
    required this.stars,
    required this.levels,
    required this.onLeaderboard,
    this.playerLevel = 1,
    this.week = 0,
    this.weekStars = 0,
    this.lastWeek = 0,
    this.lastWeekStars = 0,
  });

  final String name;

  /// Whether the nickname and score are also shown to other players.
  final bool onLeaderboard;

  /// Name of the age band, for example `adult`.
  final String ageRange;

  /// Local file of the profile picture, or null if there is none.
  final String? photoPath;

  /// Stars collected across every tier.
  final int stars;

  /// Levels cleared across every tier.
  final int levels;

  /// The player's level (see `PlayerRank`), shown beside their name.
  final int playerLevel;

  /// The current week and the stars earned in it.
  final int week, weekStars;

  /// The week before, and the stars earned in it; 0 if none.
  final int lastWeek, lastWeekStars;

  List<Object?> get _fields => [
    name,
    ageRange,
    photoPath,
    stars,
    levels,
    onLeaderboard,
    playerLevel,
    week,
    weekStars,
    lastWeek,
    lastWeekStars,
  ];

  @override
  bool operator ==(Object other) =>
      other is PlayerSnapshot &&
      Iterable.generate(
        _fields.length,
      ).every((i) => _fields[i] == other._fields[i]);

  @override
  int get hashCode => Object.hashAll(_fields);
}

/// One row of a leaderboard. Only the nickname and score are public.
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.playerId,
    required this.name,
    required this.score,
    this.levels = 0,
    this.playerLevel = 1,
  });

  final String playerId;
  final String name;

  /// Stars on the all-time and weekly boards; moves on the daily board.
  final int score;
  final int levels;
  final int playerLevel;
}

/// The online side of the game: the player's uploaded profile and the
/// leaderboards. Every call may throw when the device is offline.
abstract class CloudService {
  /// False when no online project is configured; nothing else may be
  /// called then.
  bool get available;

  /// This install's player id, or null before the first upload.
  String? get playerId;

  /// Creates or updates the player's private profile, and adds or removes
  /// their public leaderboard row.
  Future<void> savePlayer(PlayerSnapshot player);

  /// The best players of all time, highest star count first.
  Future<List<LeaderboardEntry>> topPlayers({int limit = 50});

  /// Position on the all-time board of a player with [stars] stars
  /// (1 = best).
  Future<int> rankFor(int stars);

  /// The players who earned the most stars in [week].
  Future<List<LeaderboardEntry>> weeklyTop(int week, {int limit = 50});

  /// Position in [week] of a player who earned [stars] stars in it.
  Future<int> weeklyRank(int week, int stars);

  /// Records the player's best move count for the daily puzzle of [day].
  Future<void> saveDailyScore(int day, String name, int moves);

  /// The daily puzzle board of [day], fewest moves first.
  Future<List<LeaderboardEntry>> dailyTop(int day, {int limit = 50});

  /// Position on the board of [day] of a solve in [moves] moves.
  Future<int> dailyRank(int day, int moves);

  /// Removes the player's daily puzzle scores for [days].
  Future<void> deleteDailyScores(List<int> days);

  /// Removes everything else stored online for this player.
  Future<void> deleteMyData();
}

/// Used when the game has no online project: everything stays offline.
class NoCloudService implements CloudService {
  const NoCloudService();

  @override
  bool get available => false;

  @override
  String? get playerId => null;

  @override
  Future<void> savePlayer(PlayerSnapshot player) async {}

  @override
  Future<List<LeaderboardEntry>> topPlayers({int limit = 50}) async => const [];

  @override
  Future<int> rankFor(int stars) async => 1;

  @override
  Future<List<LeaderboardEntry>> weeklyTop(int week, {int limit = 50}) async =>
      const [];

  @override
  Future<int> weeklyRank(int week, int stars) async => 1;

  @override
  Future<void> saveDailyScore(int day, String name, int moves) async {}

  @override
  Future<List<LeaderboardEntry>> dailyTop(int day, {int limit = 50}) async =>
      const [];

  @override
  Future<int> dailyRank(int day, int moves) async => 1;

  @override
  Future<void> deleteDailyScores(List<int> days) async {}

  @override
  Future<void> deleteMyData() async {}
}
