import 'package:flutter/material.dart';

/// One-off goals that pay coins when reached.
enum Achievement {
  firstPour(
    'First pour',
    'Solve your first level',
    reward: 10,
    goal: 1,
    icon: Icons.water_drop_rounded,
  ),
  sharpMind(
    'Sharp mind',
    'Earn 3 stars on 10 levels',
    reward: 20,
    goal: 10,
    icon: Icons.psychology_rounded,
  ),
  hotStreak(
    'Hot streak',
    'Earn 3 stars on 5 levels in a row',
    reward: 25,
    goal: 5,
    icon: Icons.local_fire_department_rounded,
  ),
  bigHeart(
    'Big heart',
    'Finish a heart level without Undo',
    reward: 25,
    goal: 1,
    icon: Icons.favorite_rounded,
  ),
  purist(
    'Purist',
    'Solve 10 new levels with no hint, extra tube or undo',
    reward: 30,
    goal: 10,
    icon: Icons.self_improvement_rounded,
  ),
  seer(
    'Seer',
    'Solve 10 hidden-colour levels',
    reward: 30,
    goal: 10,
    icon: Icons.visibility_rounded,
  ),
  starCollector(
    'Star collector',
    'Collect 100 stars',
    reward: 40,
    goal: 100,
    icon: Icons.star_rounded,
  ),
  regular(
    'Regular',
    'Collect the daily gift 7 days in a row',
    reward: 50,
    goal: 7,
    icon: Icons.calendar_month_rounded,
  ),
  easyDone(
    'Graduate',
    'Finish every Easy level',
    reward: 50,
    goal: 1,
    icon: Icons.school_rounded,
  ),
  mediumDone(
    'Expert',
    'Finish every Medium level',
    reward: 150,
    goal: 1,
    icon: Icons.military_tech_rounded,
  ),
  hardDone(
    'Master',
    'Finish every Hard level',
    reward: 500,
    goal: 1,
    icon: Icons.emoji_events_rounded,
  );

  const Achievement(
    this.title,
    this.description, {
    required this.reward,
    required this.goal,
    required this.icon,
  });

  final String title, description;

  /// Coins paid when it unlocks.
  final int reward;

  /// Progress needed to unlock.
  final int goal;
  final IconData icon;
}
