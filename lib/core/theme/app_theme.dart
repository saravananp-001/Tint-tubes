import 'package:flutter/material.dart';

abstract final class AppColors {
  static const seed = Color(0xFF5C6BC0);
  static const coin = Color(0xFFFFC83D);
  static const star = Color(0xFFFFD54F);
  static const starEmpty = Color(0x40FFFFFF);
  static const panel = Color(0x26FFFFFF);
  static const panelDim = Color(0x12FFFFFF);
  static const cork = Color(0xFFD7A86E);
  static const heart = Color(0xFFFF2D78);
  static const hintGlow = Color(0xFFFFEB3B);

  /// Liquid colours, indexed by the colour ids used in the puzzle model.
  static const liquids = <Color>[
    Color(0xFFE53935), // red
    Color(0xFF1E88E5), // blue
    Color(0xFF43A047), // green
    Color(0xFFFDD835), // yellow
    Color(0xFF8E24AA), // purple
    Color(0xFFFB8C00), // orange
    Color(0xFFEC407A), // pink
    Color(0xFF26C6DA), // cyan
    Color(0xFF8D6E63), // brown
    Color(0xFFC0CA33), // lime
    Color(0xFF5C6BC0), // indigo
    Color(0xFFB0BEC5), // silver
  ];
}

ThemeData buildAppTheme() => ThemeData(
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.seed,
    brightness: Brightness.dark,
  ),
  useMaterial3: true,
);
