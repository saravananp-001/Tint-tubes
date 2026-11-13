import 'package:flutter/material.dart';

import '../../../app_services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/coin_badge.dart';
import '../../../data/cloud/cloud_service.dart';
import '../../../data/profile_repository.dart';
import '../../profile/domain/player_rank.dart';
import '../../profile/presentation/profile_screen.dart';

/// Three boards: all-time stars, stars earned this week, and today's
/// daily puzzle in fewest moves. Only players who joined in their profile
/// take part.
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

/// One loaded board: the top rows and the player's own position, which is
/// null when they have no score on it yet.
class _Board {
  const _Board(this.top, this.rank);

  final List<LeaderboardEntry> top;
  final int? rank;
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  AppServices get _services => widget.services;
  CloudService get _cloud => _services.online.cloud;

  /// Bumped to make every tab load again.
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _payWeeklyPrize();
  }

  Future<void> _payWeeklyPrize() async {
    final prize = await _services.online.claimWeeklyPrize();
    if (prize == null || !mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(
          Icons.emoji_events_rounded,
          size: 44,
          color: AppColors.star,
        ),
        title: Text('Last week: #${prize.rank}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (prize.coins > 0) ...[
              const Text('Your prize'),
              const SizedBox(height: 8),
              CoinBadge(coins: prize.coins, fontSize: 22),
            ] else
              const Text(
                'Finish in the top 10 this week to win coins.',
                textAlign: TextAlign.center,
              ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Nice'),
          ),
        ],
      ),
    );
  }

  Future<_Board> _allTime() async {
    await _services.online.flush();
    return _Board(
      await _cloud.topPlayers(),
      await _cloud.rankFor(_services.progress.allStars),
    );
  }

  Future<_Board> _weekly() async {
    await _services.online.flush();
    final weekly = _services.online.weekly;
    final stars = weekly.stars;
    return _Board(
      await _cloud.weeklyTop(weekly.currentWeek),
      stars > 0 ? await _cloud.weeklyRank(weekly.currentWeek, stars) : null,
    );
  }

  Future<_Board> _daily() async {
    await _services.online.flush();
    final daily = _services.daily;
    final moves = daily.puzzleBestMoves;
    return _Board(
      await _cloud.dailyTop(daily.today),
      moves == null ? null : await _cloud.dailyRank(daily.today, moves),
    );
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => ProfileScreen(
          profile: _services.profile,
          onlineAvailable: _services.online.available,
          onDone: () => Navigator.pop(ctx),
        ),
      ),
    ).then((_) {
      if (mounted) setState(() => _generation++);
    });
  }

  Widget _joinPrompt() {
    if (!ProfileRepository.mayGoOnline(_services.profile.ageRange)) {
      return const _Message(
        icon: Icons.lock_outline_rounded,
        text: 'The online leaderboard is not available for players under 13.',
      );
    }
    return _Message(
      icon: Icons.leaderboard_rounded,
      text:
          'Join the leaderboard to see how you compare with other '
          'players. You can leave at any time.',
      action: FilledButton(
        onPressed: _openProfile,
        child: const Text('Open my profile'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final active = _services.online.active;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text('Leaderboard'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            if (active)
              IconButton(
                tooltip: 'Refresh',
                onPressed: () => setState(() => _generation++),
                icon: const Icon(Icons.refresh_rounded),
              ),
          ],
          bottom: active
              ? const TabBar(
                  tabs: [
                    Tab(text: 'This week'),
                    Tab(text: 'Daily puzzle'),
                    Tab(text: 'All time'),
                  ],
                )
              : null,
        ),
        body: AppBackground(
          child: SafeArea(
            child: !active
                ? _joinPrompt()
                : TabBarView(
                    children: [
                      _BoardView(
                        key: ValueKey('week$_generation'),
                        load: _weekly,
                        me: _cloud.playerId,
                        caption:
                            'Stars earned since Monday. Top 3 win 100, 60 '
                            'and 40 coins; the rest of the top 10 win 20.',
                        noRank: 'Earn a star this week to enter.',
                      ),
                      _BoardView(
                        key: ValueKey('day$_generation'),
                        load: _daily,
                        me: _cloud.playerId,
                        caption:
                            "Today's daily puzzle in the fewest moves. "
                            'Replay it to improve your score.',
                        noRank: "Solve today's puzzle to enter.",
                        moves: true,
                      ),
                      _BoardView(
                        key: ValueKey('all$_generation'),
                        load: _allTime,
                        me: _cloud.playerId,
                        caption: 'Every star collected so far.',
                        noRank: '',
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.action});

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: AppColors.star),
          const SizedBox(height: 16),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          if (action != null) ...[const SizedBox(height: 20), action!],
        ],
      ),
    ),
  );
}

/// One tab: loads its board once and shows it.
class _BoardView extends StatefulWidget {
  const _BoardView({
    super.key,
    required this.load,
    required this.me,
    required this.caption,
    required this.noRank,
    this.moves = false,
  });

  final Future<_Board> Function() load;
  final String? me;
  final String caption;

  /// Shown instead of the position when the player has no score here.
  final String noRank;

  /// Scores are move counts (fewer is better) rather than stars.
  final bool moves;

  @override
  State<_BoardView> createState() => _BoardViewState();
}

class _BoardViewState extends State<_BoardView>
    with AutomaticKeepAliveClientMixin {
  late Future<_Board> _board = widget.load();

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<_Board>(
      future: _board,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final board = snap.data;
        if (board == null) {
          return _Message(
            icon: Icons.cloud_off_rounded,
            text:
                'Could not load the leaderboard. Check your internet '
                'connection.',
            action: FilledButton(
              onPressed: () => setState(() => _board = widget.load()),
              child: const Text('Try again'),
            ),
          );
        }
        final rank = board.rank;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
              child: Text(
                rank != null ? 'Your position: #$rank' : widget.noRank,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.star,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                widget.caption,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ),
            Expanded(
              child: board.top.isEmpty
                  ? const Center(
                      child: Text(
                        'Nobody is on this board yet. Be the first!',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: board.top.length,
                      itemBuilder: (context, i) => _Row(
                        position: i + 1,
                        entry: board.top[i],
                        mine: board.top[i].playerId == widget.me,
                        moves: widget.moves,
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.position,
    required this.entry,
    required this.mine,
    required this.moves,
  });

  final int position;
  final LeaderboardEntry entry;
  final bool mine, moves;

  static const _medals = [
    Color(0xFFFFD54F),
    Color(0xFFCFD8DC),
    Color(0xFFD7A86E),
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      color: mine ? AppColors.seed : AppColors.panel,
      child: ListTile(
        leading: SizedBox(
          width: 36,
          child: position <= 3
              ? Icon(
                  Icons.emoji_events_rounded,
                  color: _medals[position - 1],
                  size: 28,
                )
              : Text(
                  '$position',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
        title: Text(
          mine ? '${entry.name} (you)' : entry.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: moves
            ? null
            : Text(
                'Level ${entry.playerLevel} · '
                '${PlayerRank.titleFor(entry.playerLevel)}',
              ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!moves) const Icon(Icons.star_rounded, color: AppColors.star),
            const SizedBox(width: 4),
            Text(
              moves ? '${entry.score} moves' : '${entry.score}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
