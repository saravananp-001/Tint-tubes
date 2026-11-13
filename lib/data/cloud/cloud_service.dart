/// What is uploaded for a player.
class PlayerSnapshot {
  const PlayerSnapshot({
    required this.name,
    required this.ageRange,
    required this.photoPath,
    required this.stars,
    required this.levels,
    required this.onLeaderboard,
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

  @override
  bool operator ==(Object other) =>
      other is PlayerSnapshot &&
      other.name == name &&
      other.ageRange == ageRange &&
      other.photoPath == photoPath &&
      other.stars == stars &&
      other.levels == levels &&
      other.onLeaderboard == onLeaderboard;

  @override
  int get hashCode =>
      Object.hash(name, ageRange, photoPath, stars, levels, onLeaderboard);
}

/// One row of the leaderboard. Only the nickname and score are public.
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.playerId,
    required this.name,
    required this.stars,
    required this.levels,
  });

  final String playerId;
  final String name;
  final int stars;
  final int levels;
}

/// The online side of the game: the player's uploaded profile and the
/// leaderboard. Every call may throw when the device is offline.
abstract class CloudService {
  /// False when no online project is configured; nothing else may be
  /// called then.
  bool get available;

  /// This install's player id, or null before the first upload.
  String? get playerId;

  /// Creates or updates the player's private profile, and adds or removes
  /// their public leaderboard row.
  Future<void> savePlayer(PlayerSnapshot player);

  /// The best players, highest star count first.
  Future<List<LeaderboardEntry>> topPlayers({int limit = 50});

  /// Position on the leaderboard of a player with [stars] stars (1 = best).
  Future<int> rankFor(int stars);

  /// Removes everything stored online for this player.
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
  Future<void> deleteMyData() async {}
}
