import 'package:shared_preferences/shared_preferences.dart';

import 'core/audio/sound_service.dart';
import 'core/feedback/haptics.dart';
import 'core/notifications/reminder_service.dart';
import 'data/achievements_repository.dart';
import 'data/cloud/cloud_service.dart';
import 'data/cosmetics_repository.dart';
import 'data/daily_repository.dart';
import 'data/missions_repository.dart';
import 'data/online_sync.dart';
import 'data/profile_repository.dart';
import 'data/progress_repository.dart';
import 'data/settings_repository.dart';
import 'data/spin_repository.dart';
import 'data/stats_repository.dart';
import 'data/weekly_repository.dart';

/// Everything the screens share: saved data, sound and vibration.
class AppServices {
  AppServices(
    this._prefs, {
    DateTime Function()? now,
    CloudService cloud = const NoCloudService(),
  }) : settings = SettingsRepository(_prefs),
       profile = ProfileRepository(_prefs),
       progress = ProgressRepository(_prefs),
       stats = StatsRepository(_prefs) {
    sound = SoundService(settings);
    haptics = Haptics(settings);
    reminder = ReminderService(settings);
    cosmetics = CosmeticsRepository(_prefs, progress);
    daily = DailyRepository(_prefs, progress, now: now);
    achievements = AchievementsRepository(_prefs, progress);
    missions = MissionsRepository(_prefs, progress, now: now);
    spins = SpinRepository(_prefs, progress, daily);
    online = OnlineSync(
      profile,
      progress,
      cloud,
      weekly: WeeklyRepository(_prefs, progress, now: now),
      stats: stats,
      daily: daily,
    );
  }

  final SharedPreferences _prefs;
  final SettingsRepository settings;
  final ProfileRepository profile;
  final ProgressRepository progress;
  final StatsRepository stats;
  late final SoundService sound;
  late final Haptics haptics;
  late final ReminderService reminder;
  late final CosmeticsRepository cosmetics;
  late final DailyRepository daily;
  late final AchievementsRepository achievements;
  late final MissionsRepository missions;
  late final SpinRepository spins;

  /// Leaderboard upload; does nothing unless the player opted in.
  late final OnlineSync online;

  /// Wipes coins, levels, purchases, achievements and daily streaks.
  /// Settings and the profile are kept.
  Future<void> resetProgress() async {
    for (final key in _prefs.getKeys().toList()) {
      if (SettingsRepository.keys.contains(key) ||
          ProfileRepository.keys.contains(key) ||
          DailyRepository.keptKeys.contains(key)) {
        continue;
      }
      await _prefs.remove(key);
    }
    progress.refresh();
    cosmetics.refresh();
    daily.refresh();
    achievements.refresh();
    missions.refresh();
    spins.refresh();
    stats.refresh();
  }
}
