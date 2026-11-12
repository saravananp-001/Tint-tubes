import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Round profile picture; a person icon when the player has not set one.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, required this.photoPath, this.size = 40});

  /// File path of the picture, or null for none.
  final String? photoPath;
  final double size;

  @override
  Widget build(BuildContext context) {
    final path = photoPath;
    final file = path == null ? null : File(path);
    if (file == null || !file.existsSync()) {
      return Icon(
        Icons.account_circle_rounded,
        size: size,
        color: AppColors.star,
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.star, width: size * 0.04),
        image: DecorationImage(image: FileImage(file), fit: BoxFit.cover),
      ),
    );
  }
}
