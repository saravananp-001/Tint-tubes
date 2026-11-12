import 'package:flutter/material.dart';

import '../../data/cosmetics_repository.dart';
import '../theme/cosmetics.dart';

/// Makes the player's cosmetics available to every screen.
class CosmeticsScope extends InheritedNotifier<CosmeticsRepository> {
  const CosmeticsScope({
    super.key,
    required CosmeticsRepository super.notifier,
    required super.child,
  });
}

/// Full-screen backdrop in the background theme the player has chosen.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme =
        context
            .dependOnInheritedWidgetOfExactType<CosmeticsScope>()
            ?.notifier
            ?.background ??
        BackgroundTheme.night;
    return SizedBox.expand(
      child: DecoratedBox(decoration: theme.decoration, child: child),
    );
  }
}
