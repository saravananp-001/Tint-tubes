import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tint_tubes/app_services.dart';
import 'package:tint_tubes/features/achievements/domain/achievement.dart';
import 'package:tint_tubes/features/game/domain/difficulty.dart';

void main() {
  late AppServices services;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    services = AppServices(await SharedPreferences.getInstance());
  });

  List<Achievement> solve(
    int level, {
    int stars = 3,
    bool usedUndo = false,
    bool usedHelp = false,
  }) {
    final firstTime = services.progress.starsFor(Difficulty.easy, level) == 0;
    services.progress.completeLevel(Difficulty.easy, level, stars);
    return services.achievements.recordLevel(
      firstTime: firstTime,
      stars: stars,
      heart: Difficulty.easy.isHeartLevel(level),
      hidden: false,
      usedUndo: usedUndo,
      usedHelp: usedHelp,
    );
  }

  test('first solve unlocks First pour and pays its reward once', () {
    expect(solve(1), [Achievement.firstPour]);
    // 3 stars at 5 coins each, plus the achievement.
    expect(services.progress.coins, 15 + Achievement.firstPour.reward);
    expect(solve(1), isEmpty);
    expect(services.achievements.isUnlocked(Achievement.firstPour), isTrue);
  });

  test('five 3-star solves in a row unlock Hot streak', () {
    solve(1);
    solve(2);
    solve(3, stars: 2); // breaks the run
    expect(services.achievements.progressOf(Achievement.hotStreak), 0);
    for (var l = 4; l <= 7; l++) {
      expect(solve(l), isNot(contains(Achievement.hotStreak)));
    }
    expect(solve(8), contains(Achievement.hotStreak));
  });

  test('a heart level without undo unlocks Big heart', () {
    expect(solve(5, usedUndo: true), isNot(contains(Achievement.bigHeart)));
    expect(solve(5), contains(Achievement.bigHeart));
  });

  test('Purist only counts new levels solved without help', () {
    solve(1, usedHelp: true);
    solve(1); // replay does not count
    solve(2, usedUndo: true);
    solve(3);
    expect(services.achievements.progressOf(Achievement.purist), 1);
  });

  test('reset wipes progress but keeps settings', () async {
    services.settings.colorBlind = true;
    solve(1);
    services.daily.claimGift();
    await services.resetProgress();
    expect(services.progress.coins, 0);
    expect(services.progress.allStars, 0);
    expect(services.achievements.isUnlocked(Achievement.firstPour), isFalse);
    expect(services.daily.giftAvailable, isTrue);
    expect(services.settings.colorBlind, isTrue);
  });
}
