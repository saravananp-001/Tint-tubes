import 'package:flutter/material.dart';

import '../domain/challenge.dart';

/// Asks for a friend's challenge code. Returns the challenge, or null if
/// the player cancelled.
Future<Challenge?> showChallengeDialog(BuildContext context) =>
    showDialog<Challenge>(context: context, builder: (_) => const _Dialog());

class _Dialog extends StatefulWidget {
  const _Dialog();

  @override
  State<_Dialog> createState() => _DialogState();
}

class _DialogState extends State<_Dialog> {
  final _code = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _submit() {
    final challenge = Challenge.parse(_code.text);
    if (challenge == null) {
      setState(() => _error = 'That code does not look right');
    } else {
      Navigator.pop(context, challenge);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.sports_kabaddi_rounded, size: 40),
      title: const Text('Friend challenge'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Type the code a friend sent you and try to solve the same '
            'puzzle in fewer moves. To send one, solve any level and tap '
            '"Challenge a friend".',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _code,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            textAlign: TextAlign.center,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: 'TT-M23-31',
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Play')),
      ],
    );
  }
}
