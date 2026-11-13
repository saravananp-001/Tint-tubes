import 'dart:async';

import 'package:flutter/foundation.dart';

import '../features/game/domain/difficulty.dart';
import '../features/profile/domain/player_rank.dart';
import 'cloud/cloud_service.dart';
import 'daily_repository.dart';
import 'profile_repository.dart';
import 'progress_repository.dart';
import 'stats_repository.dart';
import 'weekly_repository.dart';

/// Keeps the online copy of the player in step with the device.
///
/// Every player of 13 or over has their profile and score saved online;
/// the leaderboard switch only decides whether other players see them.
/// Nothing is uploaded for under-13s or after "Delete my online data".
class OnlineSync {
  OnlineSync(
    this._profile,
    this._progress,
    this.cloud, {
    required this.weekly,
    required StatsRepository stats,
    required DailyRepository daily,
    this.delay = const Duration(seconds: 2),
  }) : _stats = stats,
       _daily = daily {
    if (!cloud.available) return;
    _profile.addListener(_changed);
    _progress.addListener(_changed);
    _daily.addListener(_changed);
    _changed();
  }

  final ProfileRepository _profile;
  final ProgressRepository _progress;
  final StatsRepository _stats;
  final DailyRepository _daily;
  final WeeklyRepository weekly;
  final CloudService cloud;

  /// How long to wait after a change, so a burst of changes is one upload.
  final Duration delay;

  Timer? _timer;
  PlayerSnapshot? _uploaded;
  (int, int)? _dailySent;

  /// Whether the leaderboard can be offered at all.
  bool get available => cloud.available;

  /// Whether this player is on the public leaderboards right now.
  bool get active => cloud.available && _profile.online;

  PlayerSnapshot get _snapshot => PlayerSnapshot(
    name: _profile.name ?? 'Player',
    ageRange: _profile.ageRange?.name ?? '',
    photoPath: _profile.photoPath,
    stars: _progress.allStars,
    levels: Difficulty.values.fold(
      0,
      (sum, d) => sum + _progress.completedLevels(d),
    ),
    onLeaderboard: _profile.online,
    playerLevel: PlayerRank.of(_progress, _stats).level,
    week: weekly.currentWeek,
    weekStars: weekly.stars,
    lastWeek: weekly.previousWeek,
    lastWeekStars: weekly.previousStars,
  );

  void _changed() {
    if (!_profile.uploads && !_profile.synced) return;
    _timer?.cancel();
    _timer = Timer(delay, () => flush().ignore());
  }

  /// Brings the online copy up to date right away. Returns false if it
  /// failed, for example with no connection; it is tried again on the
  /// next change or app start.
  Future<bool> flush() async {
    _timer?.cancel();
    if (!cloud.available) return false;
    try {
      // Daily puzzle scores are public, so they follow the leaderboard
      // switch.
      if (!_profile.online && _daily.uploadedDays.isNotEmpty) {
        await cloud.deleteDailyScores(_daily.uploadedDays);
        _daily.uploadedDays = [];
        _dailySent = null;
      }
      if (_profile.uploads) {
        final snapshot = _snapshot;
        if (snapshot != _uploaded) {
          await cloud.savePlayer(snapshot);
          _uploaded = snapshot;
          _profile.synced = true;
        }
        final moves = _daily.puzzleBestMoves;
        final score = (_daily.today, moves ?? 0);
        if (_profile.online && moves != null && score != _dailySent) {
          await cloud.saveDailyScore(_daily.today, snapshot.name, moves);
          _dailySent = score;
          final days = _daily.uploadedDays;
          if (!days.contains(_daily.today)) {
            // Keep the list short; older boards are no longer shown.
            _daily.uploadedDays = [
              ...days,
              _daily.today,
            ].reversed.take(30).toList();
          }
        }
      } else if (_profile.synced) {
        await cloud.deleteMyData();
        _uploaded = null;
        _profile.synced = false;
      }
      return true;
    } catch (e) {
      debugPrint('Online sync failed: $e');
      return false;
    }
  }

  /// Removes the online copy and stops further uploads. Returns false
  /// if the deletion could not be done yet; it is retried later.
  Future<bool> leave() {
    _profile.uploadsOff = true;
    return flush();
  }

  /// Works out where the player finished last week and pays the prize.
  /// Returns the position and coins, or null if there is nothing to pay
  /// or it could not be checked yet.
  Future<({int rank, int coins})?> claimWeeklyPrize() async {
    if (!weekly.prizePending) return null;
    if (!active) {
      weekly.clearPrize();
      return null;
    }
    try {
      await flush();
      final rank = await cloud.weeklyRank(
        weekly.previousWeek,
        weekly.previousStars,
      );
      final coins = WeeklyRepository.prizeFor(rank);
      weekly.clearPrize();
      _progress.addCoins(coins);
      return (rank: rank, coins: coins);
    } catch (e) {
      debugPrint('Weekly prize not checked: $e');
      return null;
    }
  }
}
