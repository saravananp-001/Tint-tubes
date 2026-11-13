import 'package:flutter/material.dart';

import '../../../app_services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_background.dart';
import '../../../data/cloud/cloud_service.dart';
import '../../../data/profile_repository.dart';
import '../../profile/presentation/profile_screen.dart';

/// Top players by stars, with the player's own position. Only players
/// who joined in their profile take part.
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _Board {
  const _Board(this.top, this.rank);

  final List<LeaderboardEntry> top;
  final int rank;
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  Future<_Board>? _board;

  AppServices get _services => widget.services;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _board = _services.online.active ? _load() : null;
    });
  }

  Future<_Board> _load() async {
    // Make sure the player's latest score is in before reading.
    await _services.online.flush();
    final cloud = _services.online.cloud;
    final top = await cloud.topPlayers();
    final rank = await cloud.rankFor(_services.progress.allStars);
    return _Board(top, rank);
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
      if (mounted) _reload();
    });
  }

  Widget _message(IconData icon, String text, {Widget? action}) => Center(
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
          if (action != null) ...[const SizedBox(height: 20), action],
        ],
      ),
    ),
  );

  Widget _joinPrompt() {
    if (!ProfileRepository.mayGoOnline(_services.profile.ageRange)) {
      return _message(
        Icons.lock_outline_rounded,
        'The online leaderboard is not available for players under 13.',
      );
    }
    return _message(
      Icons.leaderboard_rounded,
      'Join the leaderboard to see how your stars compare with other '
      'players. You can leave at any time.',
      action: FilledButton(
        onPressed: _openProfile,
        child: const Text('Open my profile'),
      ),
    );
  }

  Widget _list(_Board board) {
    final me = _services.online.cloud.playerId;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'Your position: #${board.rank}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.star,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: board.top.length,
            itemBuilder: (context, i) {
              final entry = board.top[i];
              final mine = entry.playerId == me;
              return Card(
                color: mine ? AppColors.seed : AppColors.panel,
                child: ListTile(
                  leading: SizedBox(
                    width: 36,
                    child: Text(
                      '${i + 1}',
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
                  subtitle: Text('${entry.levels} levels cleared'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, color: AppColors.star),
                      const SizedBox(width: 4),
                      Text(
                        '${entry.stars}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final board = _board;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Leaderboard'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (board != null)
            IconButton(
              tooltip: 'Refresh',
              onPressed: _reload,
              icon: const Icon(Icons.refresh_rounded),
            ),
        ],
      ),
      body: AppBackground(
        child: SafeArea(
          child: board == null
              ? _joinPrompt()
              : FutureBuilder<_Board>(
                  future: board,
                  builder: (context, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final data = snap.data;
                    if (data == null) {
                      return _message(
                        Icons.cloud_off_rounded,
                        'Could not load the leaderboard. Check your '
                        'internet connection.',
                        action: FilledButton(
                          onPressed: _reload,
                          child: const Text('Try again'),
                        ),
                      );
                    }
                    return _list(data);
                  },
                ),
        ),
      ),
    );
  }
}
