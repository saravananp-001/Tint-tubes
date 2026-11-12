import 'package:flutter/material.dart';

import '../../../app_services.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/profile_avatar.dart';
import '../../../data/settings_repository.dart';
import '../../profile/presentation/profile_screen.dart';

/// Sound, vibration, pour speed, colour-blind symbols, help and reset.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.services});

  final AppServices services;

  static Future<void> showHowToPlay(BuildContext context) => showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('How to play'),
      content: const Text(
        '• Tap a tube to pick it up, then tap another tube to pour.\n\n'
        '• You can only pour onto the same colour, or into an empty tube.\n\n'
        '• The level is solved when every tube holds a single colour.\n\n'
        '• Fewer moves earn more stars, and stars earn coins.\n\n'
        '• Heart levels are bigger boards that pay double.\n\n'
        '• On hidden-colour levels the liquid below the top shows as "?" '
        'until you uncover it.',
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Got it'),
        ),
      ],
    ),
  );

  Future<void> _confirmReset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, size: 40),
        title: const Text('Reset all progress?'),
        content: const Text(
          'This deletes your coins, level progress, stars, purchases, '
          'achievements and daily streak. Your settings and profile are '
          'kept. It cannot be undone.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await services.resetProgress();
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Progress was reset.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = services.settings;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: AppBackground(
        child: SafeArea(
          child: ListenableBuilder(
            listenable: settings,
            builder: (context, _) => ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.volume_up_rounded),
                  title: const Text('Sound'),
                  value: settings.soundEnabled,
                  onChanged: (v) => settings.soundEnabled = v,
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.vibration_rounded),
                  title: const Text('Vibration'),
                  value: settings.vibrationEnabled,
                  onChanged: (v) => settings.vibrationEnabled = v,
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.text_fields_rounded),
                  title: const Text('Colour-blind letters'),
                  subtitle: const Text('Shows a letter on every colour'),
                  value: settings.colorBlind,
                  onChanged: (v) => settings.colorBlind = v,
                ),
                ListTile(
                  leading: const Icon(Icons.speed_rounded),
                  title: const Text('Pour speed'),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: SegmentedButton<PourSpeed>(
                      segments: [
                        for (final s in PourSpeed.values)
                          ButtonSegment(value: s, label: Text(s.label)),
                      ],
                      selected: {settings.pourSpeed},
                      showSelectedIcon: false,
                      onSelectionChanged: (s) => settings.pourSpeed = s.first,
                    ),
                  ),
                ),
                const Divider(),
                ListenableBuilder(
                  listenable: services.profile,
                  builder: (context, _) => ListTile(
                    leading: ProfileAvatar(
                      photoPath: services.profile.photoPath,
                      size: 28,
                    ),
                    title: const Text('Profile'),
                    subtitle: Text(
                      [
                        services.profile.name ?? 'No name',
                        services.profile.ageRange?.label ?? 'no age given',
                      ].join(' · '),
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (ctx) => ProfileScreen(
                          profile: services.profile,
                          onDone: () => Navigator.pop(ctx),
                        ),
                      ),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.help_outline_rounded),
                  title: const Text('How to play'),
                  onTap: () => showHowToPlay(context),
                ),
                ListTile(
                  leading: Icon(
                    Icons.delete_forever_rounded,
                    color: Colors.red.shade300,
                  ),
                  title: Text(
                    'Reset progress',
                    style: TextStyle(color: Colors.red.shade300),
                  ),
                  onTap: () => _confirmReset(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
