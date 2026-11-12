import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tint_tubes/app_services.dart';
import 'package:tint_tubes/data/profile_repository.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  test('profile is empty and not yet asked on first launch', () {
    final profile = ProfileRepository(prefs);
    expect(profile.asked, isFalse);
    expect(profile.name, isNull);
    expect(profile.ageRange, isNull);
  });

  test('saving trims the name and remembers the answers', () {
    ProfileRepository(prefs).save(name: '  Mira  ', ageRange: AgeRange.adult);
    final profile = ProfileRepository(prefs);
    expect(profile.asked, isTrue);
    expect(profile.name, 'Mira');
    expect(profile.ageRange, AgeRange.adult);

    profile.save(name: '   ', ageRange: null);
    expect(profile.name, isNull);
    expect(profile.ageRange, isNull);

    profile.save(name: 'x' * 50);
    expect(profile.name!.length, ProfileRepository.maxNameLength);
  });

  test('the picture path is saved and can be removed', () {
    final profile = ProfileRepository(prefs);
    expect(profile.photoPath, isNull);
    profile.save(name: 'Mira', ageRange: AgeRange.adult, photoPath: '/p.jpg');
    expect(ProfileRepository(prefs).photoPath, '/p.jpg');
    profile.save(name: 'Mira', ageRange: AgeRange.adult);
    expect(profile.photoPath, isNull);
  });

  test('resetting progress keeps the profile', () async {
    final services = AppServices(prefs);
    services.profile.save(name: 'Mira', ageRange: AgeRange.teen);
    services.progress.addCoins(50);
    await services.resetProgress();
    expect(services.progress.coins, 0);
    expect(services.profile.name, 'Mira');
    expect(services.profile.asked, isTrue);
  });
}
