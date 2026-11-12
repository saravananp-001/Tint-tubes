import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Pill showing a coin amount.
class CoinBadge extends StatelessWidget {
  const CoinBadge({super.key, required this.coins, this.fontSize = 16});

  final int coins;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.monetization_on_rounded,
            color: AppColors.coin,
            size: fontSize + 4,
          ),
          const SizedBox(width: 5),
          Text(
            '$coins',
            style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
