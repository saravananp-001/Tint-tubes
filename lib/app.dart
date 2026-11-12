import 'package:flutter/material.dart';

import 'app_services.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_background.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/profile/presentation/profile_screen.dart';

class TintTubesApp extends StatelessWidget {
  const TintTubesApp({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return CosmeticsScope(
      notifier: services.cosmetics,
      child: MaterialApp(
        title: 'Tint Tubes: Color Sort Puzzle',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        // New players see the optional profile screen once, then home.
        home: services.profile.asked
            ? HomeScreen(services: services)
            : Builder(
                builder: (context) => ProfileScreen(
                  profile: services.profile,
                  onboarding: true,
                  onDone: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HomeScreen(services: services),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
