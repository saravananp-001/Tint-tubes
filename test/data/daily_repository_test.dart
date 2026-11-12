import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tint_tubes/app_services.dart';
import 'package:tint_tubes/data/daily_repository.dart';
import 'package:tint_tubes/features/achievements/domain/achievement.dart';

void main() {
  late AppServices services;
  var now = DateTime(2026, 11, 12, 9);

  setUp(() async {
    now = DateTime(2026, 11, 12, 9);
    SharedPreferences.setMockInitialValues({});
    services = AppServices(
      await SharedPreferences.getInstance(),
      now: () => now,
    );
  });

  test('gift pays once a day and grows with the streak', () {
    final daily = services.daily;
    expect(daily.giftAvailable, isTrue);
    expect(daily.claimGift(), 5);
    expect(daily.claimGift(), 0);
    expect(daily.streak, 1);

    now = DateTime(2026, 11, 13, 23, 59);
    expect(daily.giftAvailable, isTrue);
    expect(daily.nextGift, 8);
    expect(daily.claimGift(), 8);
    expect(daily.streak, 2);
    expect(services.progress.coins, 13);
  });

  test('missing a day restarts the streak', () {
    final daily = services.daily;
    daily.claimGift();
    now = DateTime(2026, 11, 14, 8);
    expect(daily.streak, 0);
    expect(daily.claimGift(), 5);
    expect(daily.streak, 1);
  });

  test('gift is capped from day 7', () {
    expect(DailyRepository.giftFor(7), 23);
    expect(DailyRepository.giftFor(30), 23);
  });

  test('daily puzzle pays once per day', () {
    final daily = services.daily;
    expect(daily.completePuzzle(), kDailyPuzzleReward);
    expect(daily.completePuzzle(), 0);
    expect(daily.puzzleSolvedToday, isTrue);
    now = DateTime(2026, 11, 13, 0, 1);
    expect(daily.puzzleSolvedToday, isFalse);
    expect(daily.completePuzzle(), kDailyPuzzleReward);
  });

  test('a 7-day gift streak unlocks Regular', () {
    var unlocked = <Achievement>[];
    for (var day = 0; day < 7; day++) {
      now = DateTime(2026, 11, 12 + day, 9);
      services.daily.claimGift();
      unlocked = services.achievements.recordDailyStreak(services.daily.streak);
    }
    expect(unlocked, [Achievement.regular]);
  });
}
