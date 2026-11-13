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

/// The player's profile. It is stored on this device and, while
/// [uploads] is true, also saved to the game's server.
class ProfileRepository extends ChangeNotifier {
  ProfileRepository(this._prefs);

  final SharedPreferences _prefs;

  /// Every key this class owns. Resetting progress leaves these alone.
  static const keys = {
    'profile_asked',
    'profile_name',
    'profile_age',
    'profile_photo',
    'profile_online',
    'profile_synced',
    'profile_no_upload',
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

  /// Nothing is uploaded for players under 13.
  static bool mayGoOnline(AgeRange? age) =>
      age != null && age != AgeRange.under13;

  /// Whether the player deleted their online data and so opted out of
  /// uploads. Joining the leaderboard again clears it.
  bool get uploadsOff => _prefs.getBool('profile_no_upload') ?? false;

  set uploadsOff(bool value) {
    if (value == uploadsOff) return;
    _prefs.setBool('profile_no_upload', value);
    if (value) _prefs.setBool('profile_online', false);
    notifyListeners();
  }

  /// Whether the profile and score are saved to the server: every player
  /// of 13 or over who has not opted out.
  bool get uploads => asked && mayGoOnline(ageRange) && !uploadsOff;

  /// Whether the player also appears on the public leaderboard.
  bool get online => (_prefs.getBool('profile_online') ?? false) && uploads;

  set online(bool value) {
    if (value == online) return;
    _prefs.setBool('profile_online', value);
    notifyListeners();
  }

  /// Whether a copy of the profile currently exists online.
  bool get synced => _prefs.getBool('profile_synced') ?? false;

  set synced(bool value) {
    if (value == synced) return;
    _prefs.setBool('profile_synced', value);
    notifyListeners();
  }

  /// Saves the profile. A blank [name], or a null [ageRange] or
  /// [photoPath], clears that field. [online] is left as it was when null.
  void save({
    String? name,
    AgeRange? ageRange,
    String? photoPath,
    bool? online,
  }) {
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
    if (online != null) _prefs.setBool('profile_online', online);
    if (online == true) _prefs.remove('profile_no_upload');
    _prefs.setBool('profile_asked', true);
    notifyListeners();
  }
}
