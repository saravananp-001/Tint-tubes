import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tint_tubes/data/cloud/cloud_service.dart';
import 'package:tint_tubes/data/online_sync.dart';
import 'package:tint_tubes/data/profile_repository.dart';
import 'package:tint_tubes/data/daily_repository.dart';
import 'package:tint_tubes/data/progress_repository.dart';
import 'package:tint_tubes/data/stats_repository.dart';
import 'package:tint_tubes/data/weekly_repository.dart';
import 'package:tint_tubes/features/game/domain/difficulty.dart';

class FakeCloud implements CloudService {
  final saved = <PlayerSnapshot>[];
  int deletes = 0;
  bool fail = false;

  @override
  bool get available => true;

  @override
  String? get playerId => 'me';

  @override
  Future<void> savePlayer(PlayerSnapshot player) async {
    if (fail) throw Exception('offline');
    saved.add(player);
  }

  @override
  Future<void> deleteMyData() async {
    if (fail) throw Exception('offline');
    deletes++;
  }

  final dailyScores = <int, int>{};

  @override
  Future<void> saveDailyScore(int day, String name, int moves) async {
    if (fail) throw Exception('offline');
    dailyScores[day] = moves;
  }

  @override
  Future<void> deleteDailyScores(List<int> days) async {
    if (fail) throw Exception('offline');
    days.forEach(dailyScores.remove);
  }

  int weekRank = 1;

  @override
  Future<int> weeklyRank(int week, int stars) async => weekRank;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late ProfileRepository profile;
  late ProgressRepository progress;
  late FakeCloud cloud;
  late OnlineSync sync;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    profile = ProfileRepository(prefs);
    progress = ProgressRepository(prefs);
    cloud = FakeCloud();
    sync = OnlineSync(
      profile,
      progress,
      cloud,
      weekly: WeeklyRepository(prefs, progress),
      stats: StatsRepository(prefs),
      daily: DailyRepository(prefs, progress),
      delay: Duration.zero,
    );
  });

  test('nothing is uploaded before a profile exists', () async {
    progress.completeLevel(Difficulty.easy, 1, 3);
    expect(await sync.flush(), isTrue);
    expect(cloud.saved, isEmpty);
  });

  test('the profile is uploaded without joining the leaderboard', () async {
    profile.save(name: 'Asha', ageRange: AgeRange.adult);
    progress.completeLevel(Difficulty.easy, 1, 3);
    expect(await sync.flush(), isTrue);
    expect(cloud.saved.single.name, 'Asha');
    expect(cloud.saved.single.onLeaderboard, isFalse);
    expect(profile.synced, isTrue);
  });

  test('joining the leaderboard uploads a public row', () async {
    profile.save(name: 'Asha', ageRange: AgeRange.adult, online: true);
    progress.completeLevel(Difficulty.easy, 1, 3);
    expect(await sync.flush(), isTrue);
    expect(cloud.saved.single.name, 'Asha');
    expect(cloud.saved.single.ageRange, 'adult');
    expect(cloud.saved.single.stars, 3);
    expect(cloud.saved.single.levels, 1);
    expect(cloud.saved.single.onLeaderboard, isTrue);
    expect(profile.synced, isTrue);

    // Unchanged data is not sent again.
    await sync.flush();
    expect(cloud.saved, hasLength(1));
  });

  test('players under 13 are never uploaded', () async {
    profile.save(name: 'Kid', ageRange: AgeRange.under13, online: true);
    expect(profile.online, isFalse);
    await sync.flush();
    expect(cloud.saved, isEmpty);
  });

  test('leaving deletes the online copy', () async {
    profile.save(name: 'Asha', ageRange: AgeRange.adult, online: true);
    await sync.flush();
    expect(await sync.leave(), isTrue);
    expect(cloud.deletes, 1);
    expect(profile.online, isFalse);
    expect(profile.synced, isFalse);

    // Nothing more is uploaded after opting out.
    progress.completeLevel(Difficulty.easy, 1, 3);
    await sync.flush();
    expect(cloud.saved, hasLength(1));

    // Joining the leaderboard again resumes uploads.
    profile.save(name: 'Asha', ageRange: AgeRange.adult, online: true);
    await sync.flush();
    expect(cloud.saved, hasLength(2));
  });

  test('a failed deletion is retried later', () async {
    profile.save(name: 'Asha', ageRange: AgeRange.adult, online: true);
    await sync.flush();
    cloud.fail = true;
    expect(await sync.leave(), isFalse);
    expect(profile.synced, isTrue);
    cloud.fail = false;
    expect(await sync.flush(), isTrue);
    expect(cloud.deletes, 1);
  });

  test('daily puzzle scores follow the leaderboard switch', () async {
    final prefs = await SharedPreferences.getInstance();
    final daily = DailyRepository(prefs, progress);
    daily.completePuzzle(27);
    profile.save(name: 'Asha', ageRange: AgeRange.adult);
    await sync.flush();
    expect(cloud.dailyScores, isEmpty);

    profile.save(name: 'Asha', ageRange: AgeRange.adult, online: true);
    await sync.flush();
    expect(cloud.dailyScores[daily.today], 27);

    profile.online = false;
    await sync.flush();
    expect(cloud.dailyScores, isEmpty);
  });

  test('last week\'s prize is paid once', () async {
    final prefs = await SharedPreferences.getInstance();
    profile.save(name: 'Asha', ageRange: AgeRange.adult, online: true);
    await prefs.setInt('week_id', 7);
    await prefs.setInt('week_base', 0);
    progress.completeLevel(Difficulty.easy, 1, 3);
    cloud.weekRank = 2;
    final prize = await sync.claimWeeklyPrize();
    expect(prize, (rank: 2, coins: 60));
    expect(await sync.claimWeeklyPrize(), isNull);
  });

  test('changing to under 13 removes the online copy', () async {
    profile.save(name: 'Asha', ageRange: AgeRange.adult, online: true);
    await sync.flush();
    profile.save(name: 'Asha', ageRange: AgeRange.under13);
    await sync.flush();
    expect(cloud.deletes, 1);
  });
}
