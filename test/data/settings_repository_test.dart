import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tint_tubes/data/settings_repository.dart';

void main() {
  test('sound is on by default and the choice is saved', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final settings = SettingsRepository(prefs);
    expect(settings.soundEnabled, isTrue);

    var notified = 0;
    settings.addListener(() => notified++);
    settings.soundEnabled = false;
    expect(notified, 1);
    expect(SettingsRepository(prefs).soundEnabled, isFalse);
  });

  test('other settings have defaults and are saved', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final settings = SettingsRepository(prefs);
    expect(settings.vibrationEnabled, isTrue);
    expect(settings.colorBlind, isFalse);
    expect(settings.pourSpeed, PourSpeed.normal);

    settings
      ..vibrationEnabled = false
      ..colorBlind = true
      ..pourSpeed = PourSpeed.fast;
    final reloaded = SettingsRepository(prefs);
    expect(reloaded.vibrationEnabled, isFalse);
    expect(reloaded.colorBlind, isTrue);
    expect(reloaded.pourSpeed, PourSpeed.fast);
  });
}
