import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'daily_repository.dart';
import 'progress_repository.dart';

/// New levels to solve for each free spin.
const kLevelsPerSpin = 5;

/// One slice of the lucky wheel: coins, or a streak freeze when [coins]
/// is 0.
class SpinPrize {
  const SpinPrize(this.coins, this.weight);

  final int coins;

  /// How likely this slice is, relative to the others.
  final int weight;

  bool get isFreeze => coins == 0;

  String get label => isFreeze ? 'Freeze' : '$coins';
}

/// Free spins of the lucky wheel, earned by solving new levels.
class SpinRepository extends ChangeNotifier {
  SpinRepository(this._prefs, this._progress, this._daily, {Random? random})
    : _random = random ?? Random();

  final SharedPreferences _prefs;
  final ProgressRepository _progress;
  final DailyRepository _daily;
  final Random _random;

  /// The slices, in the order they are drawn round the wheel.
  static const prizes = [
    SpinPrize(5, 30),
    SpinPrize(20, 12),
    SpinPrize(10, 25),
    SpinPrize(0, 8),
    SpinPrize(15, 15),
    SpinPrize(50, 3),
    SpinPrize(8, 25),
    SpinPrize(30, 7),
  ];

  /// Spins waiting to be used.
  int get spins => _prefs.getInt('spins') ?? 0;

  /// New levels solved since the last spin was earned.
  int get levelsTowardsNext => _prefs.getInt('spin_levels') ?? 0;

  /// Counts a level solved for the first time. Returns true when that
  /// earned a spin.
  bool recordNewLevel() {
    final n = levelsTowardsNext + 1;
    final earned = n >= kLevelsPerSpin;
    _prefs.setInt('spin_levels', earned ? 0 : n);
    if (earned) _prefs.setInt('spins', spins + 1);
    notifyListeners();
    return earned;
  }

  /// Uses one spin and pays its prize. Returns the index of the winning
  /// slice in [prizes], or null if there is no spin to use.
  int? spin() {
    if (spins <= 0) return null;
    final total = prizes.fold(0, (sum, p) => sum + p.weight);
    var roll = _random.nextInt(total);
    var index = 0;
    while (roll >= prizes[index].weight) {
      roll -= prizes[index].weight;
      index++;
    }
    _prefs.setInt('spins', spins - 1);
    final prize = prizes[index];
    if (prize.isFreeze) {
      // A full freeze stock turns the prize into coins instead.
      if (!_daily.addFreeze()) _progress.addCoins(kFreezeCost);
    } else {
      _progress.addCoins(prize.coins);
    }
    notifyListeners();
    return index;
  }

  /// Call after saved data was changed from outside.
  void refresh() => notifyListeners();
}
