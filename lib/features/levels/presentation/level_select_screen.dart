import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/star_row.dart';
import '../../../data/progress_repository.dart';
import '../../game/domain/difficulty.dart';

/// Grid of levels for one difficulty. Pops with the chosen level number.
class LevelSelectScreen extends StatelessWidget {
  const LevelSelectScreen({
    super.key,
    required this.progress,
    required this.difficulty,
    required this.current,
  });

  final ProgressRepository progress;
  final Difficulty difficulty;
  final int current;

  @override
  Widget build(BuildContext context) {
    final maxLevel = progress.maxLevel(difficulty);
    final count = difficulty.levelCount;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('${difficulty.label} levels'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: AppBackground(
        child: SafeArea(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemCount: count,
            itemBuilder: (context, i) {
              final level = i + 1;
              final unlocked = level <= maxLevel;
              final stars = progress.starsFor(difficulty, level);
              return Material(
                color: level == current
                    ? AppColors.seed
                    : (unlocked ? AppColors.panel : AppColors.panelDim),
                borderRadius: BorderRadius.circular(14),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: unlocked ? () => Navigator.pop(context, level) : null,
                  child: unlocked
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (difficulty.isHeartLevel(level))
                              const Icon(
                                Icons.favorite_rounded,
                                size: 12,
                                color: AppColors.heart,
                              ),
                            if (difficulty.isHiddenLevel(level))
                              const Icon(
                                Icons.visibility_off_rounded,
                                size: 12,
                                color: Colors.white70,
                              ),
                            Text(
                              '$level',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (stars > 0) StarRow(stars: stars, size: 13),
                          ],
                        )
                      : const Icon(
                          Icons.lock_rounded,
                          size: 18,
                          color: Colors.white38,
                        ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
