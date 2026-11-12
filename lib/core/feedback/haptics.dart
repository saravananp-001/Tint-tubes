import 'package:flutter/services.dart';

import '../../data/settings_repository.dart';

/// Vibration feedback, respecting the player's vibration setting.
class Haptics {
  Haptics(this.settings);

  final SettingsRepository settings;

  /// Picking up a tube.
  void select() {
    if (settings.vibrationEnabled) HapticFeedback.selectionClick();
  }

  /// A tube was completed.
  void medium() {
    if (settings.vibrationEnabled) HapticFeedback.mediumImpact();
  }

  /// The level was solved.
  void heavy() {
    if (settings.vibrationEnabled) HapticFeedback.heavyImpact();
  }
}
