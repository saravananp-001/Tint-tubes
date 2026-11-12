import 'package:flutter/material.dart';

import '../../../app_services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/coin_badge.dart';
import '../../share/domain/poster_data.dart';
import '../../share/presentation/share_poster_screen.dart';
import '../domain/achievement.dart';

/// Every achievement with its progress and reward.
class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final repo = services.achievements;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Achievements'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: AppBackground(
        child: SafeArea(
          child: ListenableBuilder(
            listenable: repo,
            builder: (context, _) => ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: Achievement.values.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final a = Achievement.values[i];
                final done = repo.isUnlocked(a);
                final value = repo.progressOf(a);
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: done ? AppColors.panel : AppColors.panelDim,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        a.icon,
                        size: 34,
                        color: done ? AppColors.star : Colors.white38,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a.title,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              a.description,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white70,
                              ),
                            ),
                            if (!done && a.goal > 1) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: value / a.goal,
                                        minHeight: 6,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$value / ${a.goal}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (done)
                        IconButton(
                          tooltip: 'Share',
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SharePosterScreen(
                                progress: services.progress,
                                data: PosterData.forAchievement(
                                  services.progress,
                                  a,
                                  playerName: services.profile.name,
                                  playerPhoto: services.profile.photoPath,
                                ),
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.share_rounded),
                        )
                      else
                        CoinBadge(coins: a.reward, fontSize: 14),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
