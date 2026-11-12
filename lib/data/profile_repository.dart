import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Age bands offered on the profile screen. A band is asked for rather than
/// an exact age or birth date, which the game has no use for.
enum AgeRange {
  under13('Under 13'),
  teen('13 – 17'),
  youngAdult('18 – 24'),
  adult('25 – 34'),
  midAdult('35 – 44'),
  senior('45 or older');

  const AgeRange(this.label);

  final String label;
}

/// The player's profile. It is stored on this device only and is
/// never sent anywhere.
class ProfileRepository extends ChangeNotifier {
  ProfileRepository(this._prefs);

  final SharedPreferences _prefs;

  /// Every key this class owns. Resetting progress leaves these alone.
  static const keys = {
    'profile_asked',
    'profile_name',
    'profile_age',
    'profile_photo',
  };

  static const maxNameLength = 20;

  /// Whether the first-launch profile screen was already filled in, so it
  /// is not shown again.
  bool get asked => _prefs.getBool('profile_asked') ?? false;

  /// The player's nickname, or null if they gave none.
  String? get name => _prefs.getString('profile_name');

  AgeRange? get ageRange =>
      AgeRange.values.asNameMap()[_prefs.getString('profile_age')];

  /// File path of the profile picture inside the app's own storage, or
  /// null if the player has not set one.
  String? get photoPath => _prefs.getString('profile_photo');

  /// Saves the profile. A blank [name], or a null [ageRange] or
  /// [photoPath], clears that field.
  void save({String? name, AgeRange? ageRange, String? photoPath}) {
    var trimmed = name?.trim() ?? '';
    if (trimmed.length > maxNameLength) {
      trimmed = trimmed.substring(0, maxNameLength);
    }
    if (trimmed.isEmpty) {
      _prefs.remove('profile_name');
    } else {
      _prefs.setString('profile_name', trimmed);
    }
    if (ageRange == null) {
      _prefs.remove('profile_age');
    } else {
      _prefs.setString('profile_age', ageRange.name);
    }
    if (photoPath == null) {
      _prefs.remove('profile_photo');
    } else {
      _prefs.setString('profile_photo', photoPath);
    }
    _prefs.setBool('profile_asked', true);
    notifyListeners();
  }
}
