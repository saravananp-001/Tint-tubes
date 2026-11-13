import 'dart:async';

import 'package:flutter/foundation.dart';

import '../features/game/domain/difficulty.dart';
import 'cloud/cloud_service.dart';
import 'profile_repository.dart';
import 'progress_repository.dart';

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
    this.delay = const Duration(seconds: 2),
  }) {
    if (!cloud.available) return;
    _profile.addListener(_changed);
    _progress.addListener(_changed);
    _changed();
  }

  final ProfileRepository _profile;
  final ProgressRepository _progress;
  final CloudService cloud;

  /// How long to wait after a change, so a burst of changes is one upload.
  final Duration delay;

  Timer? _timer;
  PlayerSnapshot? _uploaded;

  /// Whether the leaderboard can be offered at all.
  bool get available => cloud.available;

  /// Whether this player is on the public leaderboard right now.
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
  );

  void _changed() {
    final needsUpload = _profile.uploads && _snapshot != _uploaded;
    final needsDelete = !_profile.uploads && _profile.synced;
    if (!needsUpload && !needsDelete) return;
    _timer?.cancel();
    _timer = Timer(delay, () => flush().ignore());
  }

  /// Uploads or deletes right away. Returns false if it failed, for
  /// example with no connection; it is tried again on the next change or
  /// app start.
  Future<bool> flush() async {
    _timer?.cancel();
    if (!cloud.available) return false;
    try {
      if (_profile.uploads) {
        final snapshot = _snapshot;
        if (snapshot == _uploaded) return true;
        await cloud.savePlayer(snapshot);
        _uploaded = snapshot;
        _profile.synced = true;
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
}
