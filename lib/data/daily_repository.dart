import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'progress_repository.dart';

/// Coins for the first solve of each day's puzzle.
const kDailyPuzzleReward = 30;

/// Coins for one streak freeze in the shop.
const kFreezeCost = 25;

/// Most streak freezes a player can hold.
const kMaxFreezes = 2;

/// The daily gift (with its streak) and the daily puzzle.
class DailyRepository extends ChangeNotifier {
  DailyRepository(this._prefs, this._progress, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final SharedPreferences _prefs;
  final ProgressRepository _progress;
  final DateTime Function() _now;

  /// Keys that survive a progress reset: they track what is online.
  static const keptKeys = {'daily_uploaded'};

  /// Today as a day number in the player's own time zone.
  int get today {
    final n = _now();
    return DateTime.utc(n.year, n.month, n.day).millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay;
  }

  int get _lastGiftDay => _prefs.getInt('daily_gift_day') ?? -1;

  bool get giftAvailable => today > _lastGiftDay;

  /// Streak freezes in stock. Each one covers a single missed day.
  int get freezes => _prefs.getInt('streak_freezes') ?? 0;

  /// Days missed since the last gift.
  int get _missed => max(0, today - _lastGiftDay - 1);

  /// Freezes the next gift will use up to keep the streak alive.
  int get freezesNeeded =>
      _missed > 0 && _missed <= freezes && _lastGiftDay >= 0 ? _missed : 0;

  /// Days in a row the gift has been collected. Missing a day resets it,
  /// unless there are enough freezes to cover the missed days.
  int get streak => _missed == 0 || freezesNeeded > 0
      ? _prefs.getInt('daily_streak') ?? 0
      : 0;

  /// Adds a freeze to the stock. Returns false if it is already full.
  bool addFreeze() {
    if (freezes >= kMaxFreezes) return false;
    _prefs.setInt('streak_freezes', freezes + 1);
    notifyListeners();
    return true;
  }

  /// Buys a freeze with coins. Returns false if the stock is full or the
  /// player cannot afford it.
  bool buyFreeze() {
    if (freezes >= kMaxFreezes || !_progress.spend(kFreezeCost)) return false;
    return addFreeze();
  }

  /// Coins for the gift on the [day]th day of a streak: 5, 8, 11 ... up to
  /// 23 from day 7 on.
  static int giftFor(int day) => 5 + 3 * (min(day, 7) - 1);

  /// What the next gift will pay.
  int get nextGift => giftFor(streak + 1);

  /// Collects today's gift and returns the coins paid: 0 if already taken.
  int claimGift() {
    if (!giftAvailable) return 0;
    final day = streak + 1;
    final used = freezesNeeded;
    if (used > 0) _prefs.setInt('streak_freezes', freezes - used);
    _prefs.setInt('daily_streak', day);
    _prefs.setInt('daily_gift_day', today);
    final coins = giftFor(day);
    _progress.addCoins(coins);
    notifyListeners();
    return coins;
  }

  bool get puzzleSolvedToday => _prefs.getInt('daily_puzzle_day') == today;

  /// Fewest moves today's puzzle was solved in; null if not solved today.
  int? get puzzleBestMoves =>
      puzzleSolvedToday ? _prefs.getInt('daily_puzzle_moves') : null;

  /// Days whose puzzle score was sent to the online board.
  List<int> get uploadedDays => [
    for (final d in _prefs.getStringList('daily_uploaded') ?? const <String>[])
      int.parse(d),
  ];

  set uploadedDays(List<int> days) =>
      _prefs.setStringList('daily_uploaded', [for (final d in days) '$d']);

  /// Records today's puzzle as solved in [moves] and returns the coins
  /// paid: 0 if it was already solved today.
  int completePuzzle([int? moves]) {
    if (moves != null) {
      final best = puzzleBestMoves;
      if (best == null || moves < best) {
        _prefs.setInt('daily_puzzle_moves', moves);
      }
    }
    if (puzzleSolvedToday) {
      notifyListeners();
      return 0;
    }
    _prefs.setInt('daily_puzzle_day', today);
    _progress.addCoins(kDailyPuzzleReward);
    notifyListeners();
    return kDailyPuzzleReward;
  }

  /// Call after saved data was changed from outside.
  void refresh() => notifyListeners();
}
