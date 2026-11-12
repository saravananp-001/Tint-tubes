import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/cosmetics.dart';
import 'progress_repository.dart';

/// Which tube styles and backgrounds the player owns and has switched on.
class CosmeticsRepository extends ChangeNotifier {
  CosmeticsRepository(this._prefs, this._progress);

  final SharedPreferences _prefs;
  final ProgressRepository _progress;

  bool owns(Cosmetic item) =>
      item.price == 0 ||
      (_prefs.getStringList('owned_cosmetics') ?? const []).contains(item.id);

  TubeStyle get tubeStyle =>
      TubeStyle.values.asNameMap()[_prefs.getString('tube_style')] ??
      TubeStyle.classic;

  BackgroundTheme get background =>
      BackgroundTheme.values.asNameMap()[_prefs.getString('background')] ??
      BackgroundTheme.night;

  bool isSelected(Cosmetic item) => item == tubeStyle || item == background;

  /// Spends coins on [item]. Returns false if the player cannot afford it.
  bool buy(Cosmetic item) {
    if (owns(item)) return true;
    if (!_progress.spend(item.price)) return false;
    _prefs.setStringList('owned_cosmetics', [
      ...?_prefs.getStringList('owned_cosmetics'),
      item.id,
    ]);
    notifyListeners();
    return true;
  }

  /// Switches an owned item on.
  void select(Cosmetic item) {
    if (!owns(item)) return;
    switch (item) {
      case TubeStyle s:
        _prefs.setString('tube_style', s.name);
      case BackgroundTheme b:
        _prefs.setString('background', b.name);
    }
    notifyListeners();
  }

  /// Call after saved data was changed from outside.
  void refresh() => notifyListeners();
}
