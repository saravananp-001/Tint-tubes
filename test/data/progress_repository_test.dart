import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tint_tubes/data/progress_repository.dart';
import 'package:tint_tubes/features/game/domain/difficulty.dart';

void main() {
  late ProgressRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repo = ProgressRepository(await SharedPreferences.getInstance());
  });

  test('only easy is open at the start', () {
    expect(repo.isUnlocked(Difficulty.easy), isTrue);
    expect(repo.isUnlocked(Difficulty.medium), isFalse);
    expect(repo.isUnlocked(Difficulty.hard), isFalse);
    expect(repo.coins, 0);
  });

  test('coins are paid per new star only', () {
    expect(repo.completeLevel(Difficulty.easy, 1, 2), 10);
    expect(repo.completeLevel(Difficulty.easy, 1, 2), 0);
    expect(repo.completeLevel(Difficulty.easy, 1, 1), 0);
    expect(repo.completeLevel(Difficulty.easy, 1, 3), 5);
    expect(repo.coins, 15);
    expect(repo.starsFor(Difficulty.easy, 1), 3);
    expect(repo.maxLevel(Difficulty.easy), 2);
  });

  test('stars are stored per level, even out of order', () {
    repo.completeLevel(Difficulty.easy, 3, 2);
    expect(repo.starsFor(Difficulty.easy, 1), 0);
    expect(repo.starsFor(Difficulty.easy, 3), 2);
    expect(repo.totalStars(Difficulty.easy), 2);
  });

  test('progress stops at the last level of a tier', () {
    const d = Difficulty.easy;
    expect(repo.isFinished(d), isFalse);
    repo.completeLevel(d, d.levelCount, 1);
    expect(repo.maxLevel(d), d.levelCount);
    expect(repo.isFinished(d), isTrue);
  });

  test('sharing a milestone pays once per milestone', () {
    expect(repo.shareRewardClaimed(Difficulty.easy, 10), isFalse);
    expect(repo.claimShareReward(Difficulty.easy, 10), kShareReward);
    expect(repo.claimShareReward(Difficulty.easy, 10), 0);
    expect(repo.shareRewardClaimed(Difficulty.easy, 10), isTrue);
    expect(repo.claimShareReward(Difficulty.easy, 20), kShareReward);
    expect(repo.claimShareReward(Difficulty.medium, 10), kShareReward);
    expect(repo.coins, kShareReward * 3);
  });

  test('spending needs enough coins', () {
    expect(repo.spend(1), isFalse);
    repo.completeLevel(Difficulty.easy, 1, 1);
    expect(repo.spend(1), isTrue);
    expect(repo.coins, 4);
    expect(repo.spend(5), isFalse);
    expect(repo.coins, 4);
  });

  test('unlocking spends coins and needs enough of them', () {
    expect(repo.unlock(Difficulty.medium), isFalse);
    for (var level = 1; level <= 10; level++) {
      repo.completeLevel(Difficulty.easy, level, 3);
    }
    // Eight ordinary levels at 15 coins plus two heart levels at 30.
    expect(repo.coins, 180);
    expect(repo.unlock(Difficulty.medium), isTrue);
    expect(repo.coins, 30);
    expect(repo.isUnlocked(Difficulty.medium), isTrue);
    expect(repo.isUnlocked(Difficulty.hard), isFalse);
  });
}
