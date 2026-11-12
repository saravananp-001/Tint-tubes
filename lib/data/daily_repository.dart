import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'progress_repository.dart';

/// Coins for the first solve of each day's puzzle.
const kDailyPuzzleReward = 30;

/// The daily gift (with its streak) and the daily puzzle.
class DailyRepository extends ChangeNotifier {
  DailyRepository(this._prefs, this._progress, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final SharedPreferences _prefs;
  final ProgressRepository _progress;
  final DateTime Function() _now;

  /// Today as a day number in the player's own time zone.
  int get today {
    final n = _now();
    return DateTime.utc(n.year, n.month, n.day).millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay;
  }

  int get _lastGiftDay => _prefs.getInt('daily_gift_day') ?? -1;

  bool get giftAvailable => today > _lastGiftDay;

  /// Days in a row the gift has been collected. Missing a day resets it.
  int get streak =>
      today - _lastGiftDay <= 1 ? _prefs.getInt('daily_streak') ?? 0 : 0;

  /// Coins for the gift on the [day]th day of a streak: 5, 8, 11 ... up to
  /// 23 from day 7 on.
  static int giftFor(int day) => 5 + 3 * (min(day, 7) - 1);

  /// What the next gift will pay.
  int get nextGift => giftFor(streak + 1);

  /// Collects today's gift and returns the coins paid: 0 if already taken.
  int claimGift() {
    if (!giftAvailable) return 0;
    final day = streak + 1;
    _prefs.setInt('daily_streak', day);
    _prefs.setInt('daily_gift_day', today);
    final coins = giftFor(day);
    _progress.addCoins(coins);
    notifyListeners();
    return coins;
  }

  bool get puzzleSolvedToday => _prefs.getInt('daily_puzzle_day') == today;

  /// Records today's puzzle as solved and returns the coins paid: 0 if it
  /// was already solved today.
  int completePuzzle() {
    if (puzzleSolvedToday) return 0;
    _prefs.setInt('daily_puzzle_day', today);
    _progress.addCoins(kDailyPuzzleReward);
    notifyListeners();
    return kDailyPuzzleReward;
  }

  /// Call after saved data was changed from outside.
  void refresh() => notifyListeners();
}
