import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/game/domain/difficulty.dart';

/// Coins paid the first time each milestone is shared.
const kShareReward = 10;

/// Saved player progress: coins, unlocked difficulties, and per-difficulty
/// level position and star ratings. Notifies listeners on every change.
class ProgressRepository extends ChangeNotifier {
  ProgressRepository(this._prefs);

  final SharedPreferences _prefs;

  int get coins => _prefs.getInt('coins') ?? 0;

  bool isUnlocked(Difficulty d) =>
      d.unlockCost == 0 || (_prefs.getBool('unlocked_${d.name}') ?? false);

  /// The level the player will resume on.
  int currentLevel(Difficulty d) =>
      min(_prefs.getInt('level_${d.name}') ?? 1, d.levelCount);

  /// Highest level the player may open.
  int maxLevel(Difficulty d) =>
      min(_prefs.getInt('max_${d.name}') ?? 1, d.levelCount);

  /// Whether every level of [d] has been finished at least once.
  bool isFinished(Difficulty d) => starsFor(d, d.levelCount) > 0;

  /// How many levels of [d] the player has got through. Levels open one
  /// after another, so this is everything below the highest open level.
  int completedLevels(Difficulty d) =>
      isFinished(d) ? d.levelCount : maxLevel(d) - 1;

  // One digit (0-3) per level, level 1 first.
  String _stars(Difficulty d) => _prefs.getString('stars_${d.name}') ?? '';

  /// Best star rating for a level; 0 if never completed.
  int starsFor(Difficulty d, int level) {
    final s = _stars(d);
    return level - 1 < s.length ? s.codeUnitAt(level - 1) - 48 : 0;
  }

  int totalStars(Difficulty d) =>
      _stars(d).codeUnits.fold(0, (sum, c) => sum + c - 48);

  /// Stars collected across every tier.
  int get allStars =>
      Difficulty.values.fold(0, (sum, d) => sum + totalStars(d));

  /// Levels of [d] solved with 3 stars.
  int perfectLevels(Difficulty d) =>
      _stars(d).codeUnits.where((c) => c == 51).length;

  /// Whether the first-level walkthrough has been completed.
  bool get tutorialDone => _prefs.getBool('tutorial_done') ?? false;

  set tutorialDone(bool value) => _prefs.setBool('tutorial_done', value);

  void addCoins(int amount) {
    if (amount <= 0) return;
    _prefs.setInt('coins', coins + amount);
    notifyListeners();
  }

  /// Call after saved data was changed from outside.
  void refresh() => notifyListeners();

  void setCurrentLevel(Difficulty d, int level) {
    _prefs.setInt('level_${d.name}', level);
    notifyListeners();
  }

  /// Takes [amount] coins. Returns false, changing nothing, if the player
  /// does not have enough.
  bool spend(int amount) {
    if (coins < amount) return false;
    _prefs.setInt('coins', coins - amount);
    notifyListeners();
    return true;
  }

  String _shareKey(Difficulty d, int level) => '${d.name}:$level';

  /// Whether the one-off coin reward for sharing this milestone was paid.
  bool shareRewardClaimed(Difficulty d, int level) =>
      (_prefs.getStringList('shared_milestones') ?? const []).contains(
        _shareKey(d, level),
      );

  /// Pays [kShareReward] coins the first time a milestone is shared and
  /// returns the coins paid: 0 if it was already claimed.
  int claimShareReward(Difficulty d, int level) {
    if (shareRewardClaimed(d, level)) return 0;
    _prefs.setStringList('shared_milestones', [
      ...?_prefs.getStringList('shared_milestones'),
      _shareKey(d, level),
    ]);
    _prefs.setInt('coins', coins + kShareReward);
    notifyListeners();
    return kShareReward;
  }

  /// Spends coins to open [d]. Returns false if the player cannot afford it.
  bool unlock(Difficulty d) {
    if (isUnlocked(d)) return true;
    if (coins < d.unlockCost) return false;
    _prefs.setInt('coins', coins - d.unlockCost);
    _prefs.setBool('unlocked_${d.name}', true);
    notifyListeners();
    return true;
  }

  /// Records a finished level and returns the coins earned. Coins are paid
  /// only for stars beyond the player's previous best on that level, so
  /// replaying a level cannot be used to farm coins.
  int completeLevel(Difficulty d, int level, int stars) {
    final previous = starsFor(d, level);
    final earned = max(0, stars - previous) * d.coinsPerStarAt(level);
    if (stars > previous) {
      final s = _stars(d).padRight(level, '0');
      _prefs.setString(
        'stars_${d.name}',
        s.replaceRange(level - 1, level, '$stars'),
      );
    }
    final next = min(level + 1, d.levelCount);
    if (next > maxLevel(d)) _prefs.setInt('max_${d.name}', next);
    if (earned > 0) _prefs.setInt('coins', coins + earned);
    notifyListeners();
    return earned;
  }
}
