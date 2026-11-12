import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tint_tubes/app_services.dart';
import 'package:tint_tubes/core/theme/cosmetics.dart';

void main() {
  test('items must be bought before they can be used', () async {
    SharedPreferences.setMockInitialValues({});
    final services = AppServices(await SharedPreferences.getInstance());
    final cosmetics = services.cosmetics;

    expect(cosmetics.tubeStyle, TubeStyle.classic);
    expect(cosmetics.owns(TubeStyle.jar), isFalse);
    expect(cosmetics.buy(TubeStyle.jar), isFalse); // no coins
    cosmetics.select(TubeStyle.jar);
    expect(cosmetics.tubeStyle, TubeStyle.classic);

    services.progress.addCoins(100);
    expect(cosmetics.buy(TubeStyle.jar), isTrue);
    expect(cosmetics.buy(TubeStyle.jar), isTrue); // not charged twice
    expect(services.progress.coins, 100 - TubeStyle.jar.price);
    cosmetics.select(TubeStyle.jar);
    expect(cosmetics.tubeStyle, TubeStyle.jar);

    expect(cosmetics.buy(BackgroundTheme.ocean), isTrue);
    cosmetics.select(BackgroundTheme.ocean);
    expect(cosmetics.background, BackgroundTheme.ocean);
    expect(cosmetics.tubeStyle, TubeStyle.jar);
  });
}
