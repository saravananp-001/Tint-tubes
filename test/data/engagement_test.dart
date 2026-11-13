import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tint_tubes/core/theme/cosmetics.dart';
import 'package:tint_tubes/data/daily_repository.dart';
import 'package:tint_tubes/data/missions_repository.dart';
import 'package:tint_tubes/data/progress_repository.dart';
import 'package:tint_tubes/data/spin_repository.dart';
import 'package:tint_tubes/data/stats_repository.dart';
import 'package:tint_tubes/data/weekly_repository.dart';
import 'package:tint_tubes/features/challenge/domain/challenge.dart';
import 'package:tint_tubes/features/game/domain/difficulty.dart';
import 'package:tint_tubes/features/game/domain/level_generator.dart';
import 'package:tint_tubes/features/game/domain/solver.dart';
import 'package:tint_tubes/features/profile/domain/player_rank.dart';

void main() {
  late SharedPreferences prefs;
  late ProgressRepository progress;
  var now = DateTime(2026, 11, 9); // a Monday

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    progress = ProgressRepository(prefs);
    now = DateTime(2026, 11, 9);
  });

  group('streak freeze', () {
    late DailyRepository daily;
    setUp(() => daily = DailyRepository(prefs, progress, now: () => now));

    test('a missed day resets the streak without a freeze', () {
      daily.claimGift();
      now = now.add(const Duration(days: 2));
      expect(daily.streak, 0);
    });

    test('a freeze covers one missed day and is used up', () {
      progress.addCoins(100);
      daily.claimGift();
      expect(daily.buyFreeze(), isTrue);
      now = now.add(const Duration(days: 2));
      expect(daily.streak, 1);
      expect(daily.freezesNeeded, 1);
      daily.claimGift();
      expect(daily.streak, 2);
      expect(daily.freezes, 0);
    });

    test('two missed days need two freezes', () {
      progress.addCoins(100);
      daily.claimGift();
      daily.buyFreeze();
      now = now.add(const Duration(days: 3));
      expect(daily.streak, 0);
    });

    test('no more than the maximum can be held', () {
      progress.addCoins(500);
      for (var i = 0; i < kMaxFreezes; i++) {
        expect(daily.buyFreeze(), isTrue);
      }
      expect(daily.buyFreeze(), isFalse);
      expect(progress.coins, 500 - kMaxFreezes * kFreezeCost + 0);
    });

    test('the best daily puzzle score is kept', () {
      expect(daily.completePuzzle(30), kDailyPuzzleReward);
      expect(daily.completePuzzle(25), 0);
      expect(daily.completePuzzle(40), 0);
      expect(daily.puzzleBestMoves, 25);
    });
  });

  group('missions', () {
    late MissionsRepository missions;
    setUp(() => missions = MissionsRepository(prefs, progress, now: () => now));

    test('there are three different missions a day', () {
      expect(missions.today.toSet(), hasLength(MissionsRepository.perDay));
    });

    test('a finished mission pays once', () {
      final m = missions.today.first;
      expect(missions.claim(m), 0);
      missions.record(m.event, m.target);
      expect(missions.isDone(m), isTrue);
      expect(missions.claimable, greaterThanOrEqualTo(1));
      expect(missions.claim(m), m.reward);
      expect(missions.claim(m), 0);
      expect(progress.coins, m.reward);
    });

    test('progress starts again the next day', () {
      final m = missions.today.first;
      missions.record(m.event, m.target);
      now = now.add(const Duration(days: 1));
      for (final next in missions.today) {
        expect(missions.progressOf(next), 0);
        expect(missions.isClaimed(next), isFalse);
      }
    });
  });

  group('lucky spin', () {
    test('every fifth new level earns a spin', () {
      final spins = SpinRepository(
        prefs,
        progress,
        DailyRepository(prefs, progress),
      );
      for (var i = 1; i < kLevelsPerSpin; i++) {
        expect(spins.recordNewLevel(), isFalse);
      }
      expect(spins.recordNewLevel(), isTrue);
      expect(spins.spins, 1);
    });

    test('a spin pays its prize and is used up', () {
      final daily = DailyRepository(prefs, progress);
      final spins = SpinRepository(prefs, progress, daily, random: Random(1));
      expect(spins.spin(), isNull);
      for (var i = 0; i < kLevelsPerSpin; i++) {
        spins.recordNewLevel();
      }
      final prize = SpinRepository.prizes[spins.spin()!];
      expect(spins.spins, 0);
      if (prize.isFreeze) {
        expect(daily.freezes, 1);
      } else {
        expect(progress.coins, prize.coins);
      }
    });
  });

  group('weekly stars', () {
    test('count from the start of the week and roll over on Monday', () {
      progress.completeLevel(Difficulty.easy, 1, 3);
      final weekly = WeeklyRepository(prefs, progress, now: () => now);
      expect(weekly.stars, 0);
      progress.completeLevel(Difficulty.easy, 2, 2);
      expect(weekly.stars, 2);
      expect(weekly.prizePending, isFalse);

      final first = weekly.currentWeek;
      now = now.add(const Duration(days: 7));
      expect(weekly.currentWeek, first + 7);
      expect(weekly.stars, 0);
      expect(weekly.previousWeek, first);
      expect(weekly.previousStars, 2);
      expect(weekly.prizePending, isTrue);
    });

    test('Sunday belongs to the week that started on Monday', () {
      final weekly = WeeklyRepository(prefs, progress, now: () => now);
      final monday = weekly.currentWeek;
      now = now.add(const Duration(days: 6));
      expect(weekly.currentWeek, monday);
    });

    test('prizes go to the top ten', () {
      expect(WeeklyRepository.prizeFor(1), 100);
      expect(WeeklyRepository.prizeFor(3), 40);
      expect(WeeklyRepository.prizeFor(10), 20);
      expect(WeeklyRepository.prizeFor(11), 0);
    });
  });

  group('challenge codes', () {
    test('round trip', () {
      const c = Challenge(difficulty: Difficulty.medium, number: 23, moves: 31);
      expect(c.code, 'TT-M23-31');
      final back = Challenge.parse(c.code)!;
      expect(back.difficulty, Difficulty.medium);
      expect(back.number, 23);
      expect(back.moves, 31);
    });

    test('daily puzzles and sloppy typing are understood', () {
      final c = Challenge.parse(' tt-d20770 - 22 ')!;
      expect(c.difficulty, isNull);
      expect(c.number, 20770);
      expect(c.moves, 22);
    });

    test('nonsense and impossible levels are refused', () {
      expect(Challenge.parse('hello'), isNull);
      expect(Challenge.parse('TT-E999-10'), isNull);
      expect(Challenge.parse('TT-M5-0'), isNull);
    });
  });

  test('player level grows with XP and titles follow', () {
    expect(const PlayerRank(0).level, 1);
    expect(const PlayerRank(49).level, 1);
    expect(const PlayerRank(50).level, 2);
    expect(const PlayerRank(200).level, 3);
    expect(const PlayerRank(0).title, 'Novice');
    expect(const PlayerRank(200).title, 'Mixer');
    expect(const PlayerRank(125).progress, closeTo(0.5, 0.01));
    final stats = StatsRepository(prefs)..add(Stat.dailies, 2);
    progress.completeLevel(Difficulty.easy, 1, 3);
    expect(PlayerRank.of(progress, stats).xp, 3 * 10 + 2 * 20);
  });

  test('rush puzzles are small and solvable', () {
    for (var seed = 0; seed < 6; seed++) {
      final puzzle = generateRushPuzzle(seed);
      expect(puzzle.tubes.length, inInclusiveRange(6, 8));
      expect(solve(puzzle.tubes), isNotNull);
    }
  });

  test('seasons can run over New Year', () {
    const winter = Season(12, 10, 1, 10);
    expect(winter.includes(DateTime(2026, 12, 25)), isTrue);
    expect(winter.includes(DateTime(2027, 1, 5)), isTrue);
    expect(winter.includes(DateTime(2026, 11, 13)), isFalse);
    const lights = Season(10, 10, 11, 20);
    expect(lights.includes(DateTime(2026, 11, 13)), isTrue);
    expect(lights.ends, '20 Nov');
  });
}
