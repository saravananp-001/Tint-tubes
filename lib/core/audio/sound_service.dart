import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../../data/settings_repository.dart';

/// Plays the game's sound effects, respecting the player's sound setting.
class SoundService {
  SoundService(this.settings);

  final SettingsRepository settings;

  // One player per sound, so a jingle never cuts off a pour.
  final _players = <String, AudioPlayer>{};

  /// Liquid flowing from one tube into another.
  Future<void> playPour() => _play('pour.wav');

  /// A tube was filled with a single colour.
  Future<void> playComplete() => _play('complete.wav');

  /// The level was solved.
  Future<void> playWin() => _play('win.wav');

  Future<void> _play(String file) async {
    if (!settings.soundEnabled) return;
    try {
      final player = _players[file] ??= AudioPlayer()
        ..setReleaseMode(ReleaseMode.stop);
      await player.stop();
      await player.play(
        AssetSource('audio/$file'),
        mode: PlayerMode.lowLatency,
      );
    } catch (e) {
      // A missing audio device must never interrupt the game.
      debugPrint('Sound failed: $e');
    }
  }

  void dispose() {
    for (final p in _players.values) {
      p.dispose();
    }
  }
}
