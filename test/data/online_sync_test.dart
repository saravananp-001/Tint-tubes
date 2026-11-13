import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tint_tubes/data/cloud/cloud_service.dart';
import 'package:tint_tubes/data/online_sync.dart';
import 'package:tint_tubes/data/profile_repository.dart';
import 'package:tint_tubes/data/progress_repository.dart';
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

  @override
  Future<List<LeaderboardEntry>> topPlayers({int limit = 50}) async => const [];

  @override
  Future<int> rankFor(int stars) async => 1;
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
    sync = OnlineSync(profile, progress, cloud, delay: Duration.zero);
  });

  test('nothing is uploaded until the player opts in', () async {
    profile.save(name: 'Asha', ageRange: AgeRange.adult);
    progress.completeLevel(Difficulty.easy, 1, 3);
    expect(await sync.flush(), isTrue);
    expect(cloud.saved, isEmpty);
    expect(profile.synced, isFalse);
  });

  test('opting in uploads the profile and score', () async {
    profile.save(name: 'Asha', ageRange: AgeRange.adult, online: true);
    progress.completeLevel(Difficulty.easy, 1, 3);
    expect(await sync.flush(), isTrue);
    expect(cloud.saved.single.name, 'Asha');
    expect(cloud.saved.single.ageRange, 'adult');
    expect(cloud.saved.single.stars, 3);
    expect(cloud.saved.single.levels, 1);
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

  test('changing to under 13 removes the online copy', () async {
    profile.save(name: 'Asha', ageRange: AgeRange.adult, online: true);
    await sync.flush();
    profile.save(name: 'Asha', ageRange: AgeRange.under13);
    await sync.flush();
    expect(cloud.deletes, 1);
  });
}
