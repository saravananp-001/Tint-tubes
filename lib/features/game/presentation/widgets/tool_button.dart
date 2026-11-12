import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Round icon button with a caption, used in the game's bottom bar.
class ToolButton extends StatelessWidget {
  const ToolButton({
    super.key,
    required this.icon,
    required this.label,
    this.cost,
    this.onTap,
  });

  final IconData icon;
  final String label;

  /// Coin price shown next to the label, if the action is paid.
  final int? cost;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.35 : 1,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: AppColors.panel,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(icon, size: 26),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
              if (cost != null) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.monetization_on_rounded,
                  size: 13,
                  color: AppColors.coin,
                ),
                Text(
                  ' $cost',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
