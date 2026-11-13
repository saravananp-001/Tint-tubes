import 'package:flutter/material.dart';

import '../../../app_services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/coin_badge.dart';

/// Today's three missions, their progress, and their rewards to claim.
class MissionsScreen extends StatelessWidget {
  const MissionsScreen({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final missions = services.missions;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Daily missions'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: ListenableBuilder(
                listenable: services.progress,
                builder: (_, _) => CoinBadge(coins: services.progress.coins),
              ),
            ),
          ),
        ],
      ),
      body: AppBackground(
        child: SafeArea(
          child: ListenableBuilder(
            listenable: missions,
            builder: (context, _) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Three new missions every day. Finish one, then claim '
                    'its coins here.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                for (final m in missions.today)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: missions.isClaimed(m)
                          ? AppColors.panelDim
                          : AppColors.panel,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                m.label,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            if (missions.isClaimed(m))
                              const Icon(
                                Icons.check_circle_rounded,
                                color: Colors.white54,
                              )
                            else if (missions.isDone(m))
                              FilledButton(
                                onPressed: () => missions.claim(m),
                                child: Text('Claim ${m.reward}'),
                              )
                            else
                              CoinBadge(coins: m.reward, fontSize: 14),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: missions.progressOf(m) / m.target,
                            minHeight: 8,
                            color: AppColors.star,
                            backgroundColor: AppColors.starEmpty,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${missions.progressOf(m)} / ${m.target}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
