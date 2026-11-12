import 'package:flutter_test/flutter_test.dart';
import 'package:tint_tubes/features/game/domain/difficulty.dart';
import 'package:tint_tubes/features/share/domain/milestones.dart';

void main() {
  test('milestones are 10, 25, 50, every 100th and the last level', () {
    List<int> all(Difficulty d) => [
      for (var l = 1; l <= d.levelCount; l++)
        if (isMilestone(d, l)) l,
    ];
    expect(all(Difficulty.easy), [10, 20]);
    expect(all(Difficulty.medium), [10, 25, 50, 100]);
    expect(all(Difficulty.hard), [
      10, 25, 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 1000, //
    ]);
    expect(isMilestone(Difficulty.easy, 25), isFalse);
  });

  test('lastMilestone picks the highest one reached', () {
    expect(lastMilestone(Difficulty.easy, 9), isNull);
    expect(lastMilestone(Difficulty.easy, 10), 10);
    expect(lastMilestone(Difficulty.easy, 19), 10);
    expect(lastMilestone(Difficulty.easy, 20), 20);
    expect(lastMilestone(Difficulty.hard, 260), 200);
  });
}
