import 'dart:math';

import 'difficulty.dart';
import 'solver.dart';
import 'tube_rules.dart';

/// Number of empty tubes every level starts with.
const int kEmptyTubes = 2;

/// A generated level: the starting board and the move count of a known
/// solution, used as the par for star ratings.
typedef Puzzle = ({Tubes tubes, int par});

/// Builds the puzzle for a level. Deterministic: the same difficulty and
/// level always yield the same puzzle, and every puzzle is verified solvable.
Puzzle generatePuzzle(Difficulty difficulty, int level) => _build(
  colors: difficulty.colorsForLevel(level),
  filled: difficulty.filledTubesForLevel(level),
  seed: (difficulty.index + 1) * 1000003 + level * 7919,
);

/// Builds the daily puzzle for day number [day]: 7 to 9 colours, the same
/// for every player on that day.
Puzzle generateDailyPuzzle(int day) {
  final colors = 7 + day % 3;
  return _build(colors: colors, filled: colors, seed: 5000011 + day * 7919);
}

/// Builds a small, quick puzzle for Rush mode: 4 to 6 colours.
Puzzle generateRushPuzzle(int seed) {
  final colors = 4 + seed % 3;
  return _build(colors: colors, filled: colors, seed: 9000011 + seed * 7919);
}

Puzzle _build({required int colors, required int filled, required int seed}) {
  for (var attempt = 0; ; attempt++) {
    final rnd = Random(seed + attempt * 104729);
    final units = [
      for (var t = 0; t < filled; t++)
        for (var k = 0; k < kTubeCapacity; k++) t % colors,
    ]..shuffle(rnd);
    final tubes = <List<int>>[
      for (var i = 0; i < filled; i++)
        units.sublist(i * kTubeCapacity, (i + 1) * kTubeCapacity),
      for (var i = 0; i < kEmptyTubes; i++) <int>[],
    ];
    if (tubes.any(isComplete)) continue; // no freebies
    final solution = solve(tubes);
    if (solution != null) return (tubes: tubes, par: solution.length);
  }
}

/// Isolate entry point for [generatePuzzle].
Puzzle generatePuzzleIsolate((int difficultyIndex, int level) request) =>
    generatePuzzle(Difficulty.values[request.$1], request.$2);

/// Isolate entry point for [generateRushPuzzle].
Puzzle generateRushPuzzleIsolate(int seed) => generateRushPuzzle(seed);

/// Isolate entry point for [generateDailyPuzzle].
Puzzle generateDailyPuzzleIsolate(int day) => generateDailyPuzzle(day);
