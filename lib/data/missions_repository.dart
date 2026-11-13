import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'progress_repository.dart';

/// Things the player does that missions count.
enum MissionEvent { solve, star, perfect, noUndo, daily, rush, pour }

/// A small goal for one day.
enum Mission {
  solve3('Solve 3 levels', MissionEvent.solve, 3, 10),
  solve6('Solve 6 levels', MissionEvent.solve, 6, 20),
  stars8('Earn 8 stars', MissionEvent.star, 8, 15),
  perfect2('Get 3 stars on 2 levels', MissionEvent.perfect, 2, 15),
  noUndo2('Solve 2 levels without Undo', MissionEvent.noUndo, 2, 15),
  daily('Solve the daily puzzle', MissionEvent.daily, 1, 10),
  rush('Play a game of Rush', MissionEvent.rush, 1, 10),
  pours40('Make 40 pours', MissionEvent.pour, 40, 10);

  const Mission(this.label, this.event, this.target, this.reward);

  final String label;
  final MissionEvent event;
  final int target;

  /// Coins paid when the finished mission is claimed.
  final int reward;
}

/// Three missions a day, the same for every player on that day. Progress
/// starts again each day.
class MissionsRepository extends ChangeNotifier {
  MissionsRepository(this._prefs, this._progress, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final SharedPreferences _prefs;
  final ProgressRepository _progress;
  final DateTime Function() _now;

  static const perDay = 3;

  int get _today {
    final n = _now();
    return DateTime.utc(n.year, n.month, n.day).millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay;
  }

  /// The missions of day number [day].
  static List<Mission> forDay(int day) =>
      (Mission.values.toList()..shuffle(Random(day))).take(perDay).toList();

  List<Mission> get today => forDay(_today);

  /// Forgets yesterday's progress the first time it is touched today.
  void _roll() {
    if (_prefs.getInt('mission_day') == _today) return;
    for (final e in MissionEvent.values) {
      _prefs.remove('mission_e_${e.name}');
    }
    _prefs.remove('mission_claimed');
    _prefs.setInt('mission_day', _today);
  }

  int _count(MissionEvent e) => _prefs.getInt('mission_day') == _today
      ? _prefs.getInt('mission_e_${e.name}') ?? 0
      : 0;

  /// Progress towards [m], never more than its target.
  int progressOf(Mission m) => min(_count(m.event), m.target);

  bool isDone(Mission m) => progressOf(m) >= m.target;

  bool isClaimed(Mission m) =>
      _prefs.getInt('mission_day') == _today &&
      (_prefs.getStringList('mission_claimed') ?? const []).contains(m.name);

  /// Missions that are finished but not yet claimed.
  int get claimable => today.where((m) => isDone(m) && !isClaimed(m)).length;

  /// Counts [amount] of [event] towards today's missions.
  void record(MissionEvent event, [int amount = 1]) {
    if (amount <= 0) return;
    _roll();
    _prefs.setInt('mission_e_${event.name}', _count(event) + amount);
    notifyListeners();
  }

  /// Pays the reward of a finished mission and returns the coins paid:
  /// 0 if it is not finished, not one of today's, or already claimed.
  int claim(Mission m) {
    if (!today.contains(m) || !isDone(m) || isClaimed(m)) return 0;
    _roll();
    _prefs.setStringList('mission_claimed', [
      ...?_prefs.getStringList('mission_claimed'),
      m.name,
    ]);
    _progress.addCoins(m.reward);
    notifyListeners();
    return m.reward;
  }

  /// Call after saved data was changed from outside.
  void refresh() => notifyListeners();
}
