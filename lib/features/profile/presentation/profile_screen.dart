import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/profile_avatar.dart';
import '../../../data/profile_repository.dart';

/// Nickname and age range, both required, plus an optional picture. Shown once on first launch
/// ([onboarding]) and reachable later from Settings. Calls [onDone] when
/// the player saves.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.profile,
    required this.onDone,
    this.onboarding = false,
    this.onlineAvailable = false,
  });

  final ProfileRepository profile;
  final VoidCallback onDone;
  final bool onboarding;

  /// Whether to offer joining the online leaderboard.
  final bool onlineAvailable;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final _name = TextEditingController(text: widget.profile.name ?? '');
  late AgeRange? _age = widget.profile.ageRange;
  late String? _photoPath = widget.profile.photoPath;
  late bool _online = widget.profile.online;

  bool get _mayGoOnline => ProfileRepository.mayGoOnline(_age);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    final previous = widget.profile.photoPath;
    widget.profile.save(
      name: _name.text,
      ageRange: _age,
      photoPath: _photoPath,
      online: _online && _mayGoOnline,
    );
    // The picture that was replaced or removed is no longer needed.
    if (previous != null && previous != _photoPath) {
      File(previous).delete().ignore();
    }
    widget.onDone();
  }

  /// Lets the player pick or take a picture, and copies it into the app's
  /// own storage so it survives the original being deleted.
  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (picked == null) return;
      final dir = await getApplicationDocumentsDirectory();
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final copy = await File(
        picked.path,
      ).copy('${dir.path}/profile_$stamp.jpg');
      if (mounted) setState(() => _photoPath = copy.path);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load that picture.')),
        );
      }
    }
  }

  void _choosePhoto() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(sheet);
                _pickPhoto(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(sheet);
                _pickPhoto(ImageSource.camera);
              },
            ),
            if (_photoPath != null)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded),
                title: const Text('Remove picture'),
                onTap: () {
                  Navigator.pop(sheet);
                  setState(() => _photoPath = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  /// Both a nickname and an age range are needed before continuing.
  bool get _complete => _name.text.trim().isNotEmpty && _age != null;

  @override
  Widget build(BuildContext context) {
    final onboarding = widget.onboarding;
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            children: [
              if (!onboarding)
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                )
              else
                const SizedBox(height: 40),
              Center(
                child: GestureDetector(
                  onTap: _choosePhoto,
                  child: Stack(
                    children: [
                      ProfileAvatar(photoPath: _photoPath, size: 96),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.seed,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.photo_camera_rounded,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _photoPath == null
                    ? 'Tap to add a picture (optional)'
                    : 'Tap to change your picture',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
              const SizedBox(height: 12),
              Text(
                onboarding ? 'Welcome to Tint Tubes' : 'Your profile',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tell us a little about you to get started.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 28),
              const Text(
                'What should we call you?',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _name,
                maxLength: ProfileRepository.maxNameLength,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Nickname',
                  filled: true,
                  fillColor: AppColors.panel,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'How old are you?',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final a in AgeRange.values)
                    ChoiceChip(
                      label: Text(a.label),
                      selected: _age == a,
                      onSelected: (on) => setState(() => _age = on ? a : null),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              if (widget.onlineAvailable)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.leaderboard_rounded),
                  title: const Text('Join the online leaderboard'),
                  subtitle: Text(
                    _age != AgeRange.under13
                        ? 'Sends your nickname, age range, picture and '
                              'score to our server. Other players see only '
                              'your nickname and score.'
                        : 'Not available for players under 13.',
                    style: const TextStyle(fontSize: 12),
                  ),
                  value: _online && _mayGoOnline,
                  onChanged: _mayGoOnline
                      ? (v) => setState(() => _online = v)
                      : null,
                ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _online && _mayGoOnline
                        ? Icons.cloud_upload_outlined
                        : Icons.lock_outline_rounded,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _online && _mayGoOnline
                          ? 'Your profile is stored online while this is '
                                'on. Switch it off, or use "Delete my '
                                'online data" in Settings, to remove it.'
                          : 'This stays on your device. It is not sent to '
                                'us or anyone else.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _complete ? _save : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    onboarding ? 'Start playing' : 'Save',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
