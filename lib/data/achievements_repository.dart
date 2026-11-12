import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/achievements/domain/achievement.dart';
import '../features/game/domain/difficulty.dart';
import 'progress_repository.dart';

/// Tracks achievement progress and pays their coin rewards.
class AchievementsRepository extends ChangeNotifier {
  AchievementsRepository(this._prefs, this._progress);

  final SharedPreferences _prefs;
  final ProgressRepository _progress;

  List<String> get _unlocked => _prefs.getStringList('achievements') ?? [];

  bool isUnlocked(Achievement a) => _unlocked.contains(a.name);

  int _counter(String key) => _prefs.getInt('ach_$key') ?? 0;

  /// Current progress towards [a], capped at its goal.
  int progressOf(Achievement a) {
    if (isUnlocked(a)) return a.goal;
    final value = switch (a) {
      Achievement.firstPour => _progress.allStars > 0 ? 1 : 0,
      Achievement.sharpMind => Difficulty.values.fold(
        0,
        (sum, d) => sum + _progress.perfectLevels(d),
      ),
      Achievement.hotStreak => _counter('streak3'),
      Achievement.bigHeart => _counter('heart_clean'),
      Achievement.purist => _counter('purist'),
      Achievement.seer => _counter('hidden'),
      Achievement.starCollector => _progress.allStars,
      Achievement.regular => _counter('daily_streak'),
      Achievement.easyDone => _progress.isFinished(Difficulty.easy) ? 1 : 0,
      Achievement.mediumDone => _progress.isFinished(Difficulty.medium) ? 1 : 0,
      Achievement.hardDone => _progress.isFinished(Difficulty.hard) ? 1 : 0,
    };
    return min(value, a.goal);
  }

  /// Call after a level was solved and saved. Returns what it unlocked.
  ///
  /// [firstTime] is whether the level had never been solved before;
  /// [usedHelp] covers hints and the extra tube.
  List<Achievement> recordLevel({
    required bool firstTime,
    required int stars,
    required bool heart,
    required bool hidden,
    required bool usedUndo,
    required bool usedHelp,
  }) {
    _prefs.setInt('ach_streak3', stars == 3 ? _counter('streak3') + 1 : 0);
    if (heart && !usedUndo) _prefs.setInt('ach_heart_clean', 1);
    if (firstTime && !usedUndo && !usedHelp) {
      _prefs.setInt('ach_purist', _counter('purist') + 1);
    }
    if (firstTime && hidden) {
      _prefs.setInt('ach_hidden', _counter('hidden') + 1);
    }
    return _sweep();
  }

  /// Call after the daily gift was collected with the new [streak].
  List<Achievement> recordDailyStreak(int streak) {
    _prefs.setInt('ach_daily_streak', streak);
    return _sweep();
  }

  /// Unlocks and pays everything whose goal has been reached.
  List<Achievement> _sweep() {
    final unlocked = <Achievement>[
      for (final a in Achievement.values)
        if (!isUnlocked(a) && progressOf(a) >= a.goal) a,
    ];
    if (unlocked.isNotEmpty) {
      _prefs.setStringList('achievements', [
        ..._unlocked,
        for (final a in unlocked) a.name,
      ]);
      _progress.addCoins(unlocked.fold(0, (sum, a) => sum + a.reward));
    }
    notifyListeners();
    return unlocked;
  }

  /// Call after saved data was changed from outside.
  void refresh() => notifyListeners();
}
