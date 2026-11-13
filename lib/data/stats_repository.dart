import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lifetime counters shown on the statistics screen.
enum Stat {
  solves('Levels solved'),
  pours('Pours made'),
  hints('Hints used'),
  dailies('Daily puzzles solved'),
  bestStreak('Best daily streak'),
  rushGames('Rush games played'),
  rushBest('Best rush score'),
  challengesWon('Challenges won'),
  seconds('Time played');

  const Stat(this.label);

  final String label;
}

/// Saved lifetime statistics.
class StatsRepository extends ChangeNotifier {
  StatsRepository(this._prefs);

  final SharedPreferences _prefs;

  int value(Stat s) => _prefs.getInt('stat_${s.name}') ?? 0;

  void add(Stat s, [int amount = 1]) {
    if (amount <= 0) return;
    _prefs.setInt('stat_${s.name}', value(s) + amount);
    notifyListeners();
  }

  /// Raises a best-so-far stat to [amount]. Returns whether it was a new
  /// best.
  bool raiseTo(Stat s, int amount) {
    if (amount <= value(s)) return false;
    _prefs.setInt('stat_${s.name}', max(amount, value(s)));
    notifyListeners();
    return true;
  }

  /// Returns true the first time it is called with [key], false after.
  bool markOnce(String key) {
    final seen = _prefs.getStringList('stat_once') ?? const [];
    if (seen.contains(key)) return false;
    _prefs.setStringList('stat_once', [...seen, key]);
    return true;
  }

  /// Time played as "3 h 12 min" or "12 min".
  String get timePlayed {
    final minutes = value(Stat.seconds) ~/ 60;
    return minutes >= 60
        ? '${minutes ~/ 60} h ${minutes % 60} min'
        : '$minutes min';
  }

  /// Call after saved data was changed from outside.
  void refresh() => notifyListeners();
}
