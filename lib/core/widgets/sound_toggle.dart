import 'package:flutter/material.dart';

import '../../data/settings_repository.dart';

/// Speaker button that switches sound effects on and off.
class SoundToggle extends StatelessWidget {
  const SoundToggle({super.key, required this.settings});

  final SettingsRepository settings;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (_, _) {
        final on = settings.soundEnabled;
        return IconButton(
          tooltip: on ? 'Turn sound off' : 'Turn sound on',
          iconSize: 26,
          onPressed: () => settings.soundEnabled = !on,
          icon: Icon(
            on ? Icons.volume_up_rounded : Icons.volume_off_rounded,
            color: on ? null : Colors.white54,
          ),
        );
      },
    );
  }
}
