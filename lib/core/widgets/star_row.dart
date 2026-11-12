import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Three stars, [stars] of them filled.
class StarRow extends StatelessWidget {
  const StarRow({super.key, required this.stars, this.size = 16});

  final int stars;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          Icon(
            Icons.star_rounded,
            size: size,
            color: i < stars ? AppColors.star : AppColors.starEmpty,
          ),
      ],
    );
  }
}
