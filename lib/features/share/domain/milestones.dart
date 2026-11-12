import 'dart:math';

import '../../game/domain/difficulty.dart';

/// Levels worth bragging about: 10, 25, 50, every 100th, and the last level
/// of a tier.
bool isMilestone(Difficulty d, int level) {
  if (level < 1 || level > d.levelCount) return false;
  return level == d.levelCount ||
      level == 10 ||
      level == 25 ||
      level == 50 ||
      level % 100 == 0;
}

/// The highest milestone among the first [completedLevels] levels of [d],
/// or null if none has been reached yet.
int? lastMilestone(Difficulty d, int completedLevels) {
  for (var l = min(completedLevels, d.levelCount); l >= 1; l--) {
    if (isMilestone(d, l)) return l;
  }
  return null;
}
