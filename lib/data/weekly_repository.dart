import 'package:shared_preferences/shared_preferences.dart';

import 'progress_repository.dart';

/// Stars earned in the current week (Monday to Sunday), for the weekly
/// leaderboard, and what is needed to pay last week's prize.
class WeeklyRepository {
  WeeklyRepository(this._prefs, this._progress, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final SharedPreferences _prefs;
  final ProgressRepository _progress;
  final DateTime Function() _now;

  /// Coins for finishing a week in position [rank].
  static int prizeFor(int rank) => switch (rank) {
    1 => 100,
    2 => 60,
    3 => 40,
    <= 10 => 20,
    _ => 0,
  };

  /// The day number of this week's Monday; it names the week.
  int get currentWeek {
    final n = _now();
    final day =
        DateTime.utc(n.year, n.month, n.day).millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay;
    return day - (n.weekday - 1);
  }

  /// Starts a new week when the calendar has moved on, keeping the old
  /// week's result for the prize.
  void _roll() {
    final stored = _prefs.getInt('week_id');
    final total = _progress.allStars;
    if (stored == currentWeek) {
      // Progress was reset: start counting again from the new total.
      if (total < (_prefs.getInt('week_base') ?? 0)) {
        _prefs.setInt('week_base', total);
      }
      return;
    }
    if (stored != null) {
      final earned = total - (_prefs.getInt('week_base') ?? total);
      _prefs.setInt('week_prev_id', stored);
      _prefs.setInt('week_prev_stars', earned < 0 ? 0 : earned);
      _prefs.setBool('week_prize_pending', earned > 0);
    }
    _prefs.setInt('week_id', currentWeek);
    _prefs.setInt('week_base', total);
  }

  /// Stars earned so far this week.
  int get stars {
    _roll();
    return _progress.allStars - (_prefs.getInt('week_base') ?? 0);
  }

  /// The week before the current one this player took part in; 0 if none.
  int get previousWeek {
    _roll();
    return _prefs.getInt('week_prev_id') ?? 0;
  }

  int get previousStars {
    _roll();
    return _prefs.getInt('week_prev_stars') ?? 0;
  }

  /// Whether last week's prize has still to be worked out and paid.
  bool get prizePending {
    _roll();
    return _prefs.getBool('week_prize_pending') ?? false;
  }

  void clearPrize() => _prefs.setBool('week_prize_pending', false);
}
