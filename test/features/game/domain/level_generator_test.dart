import 'package:flutter_test/flutter_test.dart';
import 'package:tint_tubes/features/game/domain/difficulty.dart';
import 'package:tint_tubes/features/game/domain/level_generator.dart';
import 'package:tint_tubes/features/game/domain/scoring.dart';
import 'package:tint_tubes/features/game/domain/solver.dart';
import 'package:tint_tubes/features/game/domain/tube_rules.dart';

void main() {
  test('every difficulty yields deterministic, solvable levels quickly', () {
    for (final d in Difficulty.values) {
      final sw = Stopwatch()..start();
      final levels = {
        1, 2, 5, 9, 10, 17, 25, 30, 60, 71, 99, 305, 401, 999, //
      }.where((l) => l <= d.levelCount).followedBy([d.levelCount]);
      for (final level in levels) {
        final t0 = sw.elapsedMilliseconds;
        final puzzle = generatePuzzle(d, level);
        expect(puzzle.tubes, generatePuzzle(d, level).tubes);
        expect(puzzle.tubes.length, d.filledTubesForLevel(level) + kEmptyTubes);

        // Replay the solver's answer with the real game rules.
        final solution = solve(puzzle.tubes)!;
        expect(solution.length, puzzle.par);
        final t = copyTubes(puzzle.tubes);
        for (final m in solution) {
          final n = pourCount(t[m[0]], t[m[1]]);
          expect(n, greaterThan(0));
          applyPour(t, m[0], m[1], n);
        }
        expect(isSolved(t), isTrue, reason: '${d.name} level $level');
        // ignore: avoid_print
        print(
          '${d.name} $level: ${puzzle.tubes.length} tubes, par ${puzzle.par}, ${sw.elapsedMilliseconds - t0}ms',
        );
      }
      expect(sw.elapsedMilliseconds, lessThan(5000), reason: d.name);
    }
  });

  test('colour count grows within each difficulty range', () {
    expect(Difficulty.easy.colorsForLevel(1), 3);
    expect(Difficulty.easy.colorsForLevel(19), 5);
    expect(Difficulty.medium.colorsForLevel(1), 7);
    expect(Difficulty.medium.colorsForLevel(99), 10);
    expect(Difficulty.hard.colorsForLevel(1), 10);
    expect(Difficulty.hard.colorsForLevel(999), 12);
  });

  test('each tier has its fixed number of levels', () {
    expect(Difficulty.easy.levelCount, 20);
    expect(Difficulty.medium.levelCount, 100);
    expect(Difficulty.hard.levelCount, 1000);
    expect(Difficulty.medium.isLastLevel(99), isFalse);
    expect(Difficulty.medium.isLastLevel(100), isTrue);
  });

  test('every fifth level is a heart level with more tubes and pay', () {
    expect(Difficulty.easy.isHeartLevel(4), isFalse);
    expect(Difficulty.easy.isHeartLevel(5), isTrue);
    expect(Difficulty.easy.filledTubesForLevel(5), 10);
    expect(Difficulty.medium.filledTubesForLevel(5), 14);
    expect(Difficulty.hard.filledTubesForLevel(5), 18);
    expect(Difficulty.hard.filledTubesForLevel(305), 20);
    expect(Difficulty.easy.coinsPerStarAt(4), 5);
    expect(Difficulty.easy.coinsPerStarAt(5), 10);
  });

  test('star rating depends on moves against par', () {
    expect(starsForMoves(10, 10), 3);
    expect(starsForMoves(13, 10), 3);
    expect(starsForMoves(14, 10), 2);
    expect(starsForMoves(18, 10), 2);
    expect(starsForMoves(19, 10), 1);
  });

  test('hidden-colour levels: none on Easy, some on Medium and Hard', () {
    List<int> hidden(Difficulty d) => [
      for (var l = 1; l <= 20; l++)
        if (d.isHiddenLevel(l)) l,
    ];
    expect(hidden(Difficulty.easy), isEmpty);
    expect(hidden(Difficulty.medium), [8, 13, 18]);
    expect(hidden(Difficulty.hard), [6, 8, 11, 13, 16, 18]);
    for (final d in Difficulty.values) {
      for (var l = 1; l <= d.levelCount; l++) {
        expect(d.isHiddenLevel(l) && d.isHeartLevel(l), isFalse);
      }
    }
  });

  test('daily puzzle is the same all day and solvable', () {
    final a = generateDailyPuzzle(20769), b = generateDailyPuzzle(20769);
    expect(a.tubes, b.tubes);
    expect(a.par, greaterThan(0));
    expect(generateDailyPuzzle(20770).tubes, isNot(a.tubes));
  });
}
