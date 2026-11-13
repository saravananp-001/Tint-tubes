import '../../game/domain/difficulty.dart';

/// A puzzle a friend solved, and the number of moves to beat. It travels
/// as a short code such as `TT-M23-31` (Medium level 23 in 31 moves) or
/// `TT-D20770-22` (the daily puzzle of day 20770 in 22 moves).
class Challenge {
  const Challenge({
    required this.difficulty,
    required this.number,
    required this.moves,
  });

  /// The tier of the level, or null for a daily puzzle.
  final Difficulty? difficulty;

  /// The level, or the day number of a daily puzzle.
  final int number;

  /// Moves the challenger needed.
  final int moves;

  static const _letters = {
    'E': Difficulty.easy,
    'M': Difficulty.medium,
    'H': Difficulty.hard,
  };

  String get code {
    final d = difficulty;
    final letter = d == null
        ? 'D'
        : _letters.entries.firstWhere((e) => e.value == d).key;
    return 'TT-$letter$number-$moves';
  }

  String get shareText =>
      'I solved a Tint Tubes puzzle in $moves moves. Can you beat me?\n'
      'Open Tint Tubes, tap the menu, choose "Enter challenge code" and '
      'type: $code';

  /// Reads a code however it was typed; null if it is not a valid one.
  static Challenge? parse(String text) {
    final m = RegExp(
      r'([EMHD])\s*(\d{1,6})\s*-\s*(\d{1,4})',
    ).firstMatch(text.toUpperCase().replaceAll('TT-', ''));
    if (m == null) return null;
    final d = _letters[m[1]];
    final number = int.parse(m[2]!);
    final moves = int.parse(m[3]!);
    if (moves < 1 || number < 1) return null;
    if (d != null && number > d.levelCount) return null;
    return Challenge(difficulty: d, number: number, moves: moves);
  }
}
