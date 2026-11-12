import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// How long one pour takes.
enum PourSpeed {
  slow('Slow', 950),
  normal('Normal', 700),
  fast('Fast', 450);

  const PourSpeed(this.label, this.millis);

  final String label;
  final int millis;
}

/// Saved player preferences. Notifies listeners on every change.
class SettingsRepository extends ChangeNotifier {
  SettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  /// Every key this class owns. Resetting progress leaves these alone.
  static const keys = {
    'sound_enabled',
    'vibration_enabled',
    'color_blind',
    'pour_speed',
  };

  bool get soundEnabled => _prefs.getBool('sound_enabled') ?? true;

  set soundEnabled(bool value) {
    _prefs.setBool('sound_enabled', value);
    notifyListeners();
  }

  bool get vibrationEnabled => _prefs.getBool('vibration_enabled') ?? true;

  set vibrationEnabled(bool value) {
    _prefs.setBool('vibration_enabled', value);
    notifyListeners();
  }

  /// Draws a letter on every colour so they can be told apart by shape.
  bool get colorBlind => _prefs.getBool('color_blind') ?? false;

  set colorBlind(bool value) {
    _prefs.setBool('color_blind', value);
    notifyListeners();
  }

  PourSpeed get pourSpeed =>
      PourSpeed.values.asNameMap()[_prefs.getString('pour_speed')] ??
      PourSpeed.normal;

  set pourSpeed(PourSpeed value) {
    _prefs.setString('pour_speed', value.name);
    notifyListeners();
  }
}
