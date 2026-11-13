import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app_services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/coin_badge.dart';
import '../../../core/widgets/confetti.dart';
import '../../../core/widgets/sound_toggle.dart';
import '../../../data/missions_repository.dart';
import '../../../data/progress_repository.dart';
import '../../../data/stats_repository.dart';
import '../../achievements/domain/achievement.dart';
import '../../challenge/domain/challenge.dart';
import '../../levels/presentation/level_select_screen.dart';
import '../../share/domain/milestones.dart';
import '../../share/domain/poster_data.dart';
import '../../share/presentation/share_poster_screen.dart';
import '../domain/difficulty.dart';
import '../domain/level_generator.dart';
import '../domain/scoring.dart';
import '../domain/solver.dart';
import '../domain/tube_rules.dart';
import 'widgets/board_layout.dart';
import 'widgets/board_painter.dart';
import 'widgets/heart_bottle.dart';
import 'widgets/tool_button.dart';
import 'widgets/win_dialog.dart';

/// Coins charged each time a hint is shown.
const int kHintCost = 1;

/// Coins charged for the extra empty tube, once per level.
const int kExtraTubeCost = 5;

/// Pours the first-level walkthrough guides the player through.
const int kTutorialPours = 2;

/// Length of one game of Rush.
const int kRushSeconds = 120;

/// Coins for each puzzle solved in a game of Rush.
const int kRushCoinsPerPuzzle = 3;

/// Plays one of four things; exactly one must be given: the levels of a
/// [difficulty], the daily puzzle of [dailyDay], a friend's [challenge],
/// or [rush] mode (as many small puzzles as possible before time runs
/// out).
class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.services,
    this.difficulty,
    this.dailyDay,
    this.challenge,
    this.rush = false,
  }) : assert(
         (difficulty != null ? 1 : 0) +
                 (dailyDay != null ? 1 : 0) +
                 (challenge != null ? 1 : 0) +
                 (rush ? 1 : 0) ==
             1,
       );

  final AppServices services;
  final Difficulty? difficulty;
  final int? dailyDay;
  final Challenge? challenge;
  final bool rush;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late final _pourCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late final _selectCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 140),
    value: 1,
  );

  AppServices get _services => widget.services;
  ProgressRepository get _progress => _services.progress;
  Difficulty? get _difficulty => widget.difficulty;
  Challenge? get _challenge => widget.challenge;
  bool get _rush => widget.rush;
  final _opened = DateTime.now();

  // Rush mode.
  int _rushSeed = Random().nextInt(1 << 20);
  int _rushSolved = 0;
  int _rushLeft = kRushSeconds;
  Timer? _rushTimer;
  bool _rushOver = false;

  int _level = 1;
  Tubes _tubes = [];
  Tubes _initial = [];
  int _par = 1;
  final List<Tubes> _history = [];
  int? _selected, _previousSelected;
  PourAnimation? _pour;
  List<int>? _hint;
  Timer? _hintTimer;
  bool _loading = true;
  bool _extraTubeUsed = false;
  bool _thinking = false;
  bool _usedUndo = false;
  bool _usedHint = false;
  int _moves = 0;

  /// Hidden-colour levels: units at the bottom of each tube not yet seen.
  List<int>? _hidden;

  /// Guided pours left in the first-level walkthrough; 0 when not active.
  int _tutorialLeft = 0;
  List<int>? _tutorialMove;

  bool get _heartLevel => _difficulty?.isHeartLevel(_level) ?? false;
  bool get _hiddenLevel => _difficulty?.isHiddenLevel(_level) ?? false;
  bool get _tutorial => _tutorialLeft > 0;

  @override
  void initState() {
    super.initState();
    final d = _difficulty;
    _loadLevel(d == null ? 0 : _progress.currentLevel(d));
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _rushTimer?.cancel();
    _services.stats.add(
      Stat.seconds,
      DateTime.now().difference(_opened).inSeconds,
    );
    _pourCtrl.dispose();
    _selectCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLevel(int level) async {
    setState(() {
      _level = level;
      _loading = true;
      _tutorialLeft = 0;
    });
    final d = _difficulty;
    final Puzzle puzzle;
    final c = _challenge;
    if (_rush) {
      puzzle = await compute(generateRushPuzzleIsolate, _rushSeed + level);
    } else if (c != null) {
      final tier = c.difficulty;
      puzzle = tier == null
          ? await compute(generateDailyPuzzleIsolate, c.number)
          : await compute(generatePuzzleIsolate, (tier.index, c.number));
    } else if (d == null) {
      puzzle = await compute(generateDailyPuzzleIsolate, widget.dailyDay!);
    } else {
      _progress.setCurrentLevel(d, level);
      puzzle = await compute(generatePuzzleIsolate, (d.index, level));
    }
    if (!mounted || _level != level) return;
    setState(() {
      _initial = puzzle.tubes;
      _par = puzzle.par;
      _reset();
      _hidden = _hiddenLevel
          ? [for (final t in _tubes) max(0, t.length - 1)]
          : null;
      _syncHidden();
      _loading = false;
    });
    if (_rush && !_rushOver) {
      _rushTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _rushLeft--);
        if (_rushLeft <= 0) _endRush();
      });
    }
    if (d == Difficulty.easy && level == 1 && !_progress.tutorialDone) {
      _tutorialLeft = kTutorialPours;
      _refreshTutorial();
    }
  }

  void _reset() {
    _tubes = copyTubes(_initial);
    _history.clear();
    _selected = _previousSelected = null;
    _pour = null;
    _hint = null;
    _extraTubeUsed = false;
    _usedUndo = false;
    _usedHint = false;
    _moves = 0;
    _syncHidden();
  }

  /// Keeps [_hidden] in step with the tubes: the top of every tube is
  /// always visible, and so is any liquid of the same colour right below
  /// what is visible. Liquid that has been seen once stays seen.
  void _syncHidden() {
    final h = _hidden;
    if (h == null) return;
    while (h.length < _tubes.length) {
      h.add(0);
    }
    if (h.length > _tubes.length) h.removeRange(_tubes.length, h.length);
    for (var i = 0; i < h.length; i++) {
      final t = _tubes[i];
      var v = min(h[i], max(0, t.length - 1));
      while (v > 0 && t[v - 1] == t[v]) {
        v--;
      }
      h[i] = v;
    }
  }

  bool get _busy => _loading || _pour != null || _rushOver;

  bool _canPick(int i) => _tubes[i].isNotEmpty && !isComplete(_tubes[i]);

  void _select(int? i) {
    _previousSelected = _selected;
    _selected = i;
    _selectCtrl.forward(from: 0);
  }

  void _onTubeTap(int i) {
    if (_busy) return;
    setState(() {
      if (!_tutorial) _hint = null;
      final sel = _selected;
      final n = sel == null || sel == i ? 0 : pourCount(_tubes[sel], _tubes[i]);
      if (sel == i) {
        _select(null);
      } else if (n > 0) {
        _startPour(sel!, i, n);
      } else if (_canPick(i)) {
        _services.haptics.select();
        _select(i);
      } else {
        _select(null);
      }
      _applyTutorialGlow();
    });
  }

  void _startPour(int from, int to, int n) {
    _history.add(copyTubes(_tubes));
    final color = _tubes[from].last;
    applyPour(_tubes, from, to, n);
    _moves++;
    _services.stats.add(Stat.pours);
    _services.missions.record(MissionEvent.pour);
    _selected = _previousSelected = null;
    _pour = PourAnimation(from, to, color, n);
    _pourCtrl.duration = Duration(
      milliseconds: _services.settings.pourSpeed.millis,
    );
    // Start the sound as the liquid starts to flow, after the tube has tilted.
    Future.delayed(_pourCtrl.duration! * BoardPainter.flowStart, () {
      if (mounted) _services.sound.playPour();
    });
    _pourCtrl.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      setState(() {
        _pour = null;
        _syncHidden();
      });
      final solved = isSolved(_tubes);
      if (isComplete(_tubes[to])) {
        _services.haptics.medium();
        if (!solved) _services.sound.playComplete();
      }
      if (_tutorial) _advanceTutorial(solved);
      if (solved) _onSolved();
    });
  }

  // ---- First-level walkthrough -------------------------------------------

  Future<void> _refreshTutorial() async {
    if (!_tutorial) return;
    final move = await compute(hintMove, copyTubes(_tubes));
    if (!mounted || !_tutorial) return;
    setState(() {
      _tutorialMove = move;
      _applyTutorialGlow();
    });
  }

  /// Glows the tube to pick up, or, once it is picked up, where to pour.
  void _applyTutorialGlow() {
    if (!_tutorial) return;
    final move = _tutorialMove;
    if (move == null || _pour != null) {
      _hint = null;
    } else {
      _hint = [_selected == move[0] ? move[1] : move[0]];
    }
  }

  void _advanceTutorial(bool solved) {
    _tutorialLeft--;
    _tutorialMove = null;
    if (_tutorialLeft > 0 && !solved) {
      _refreshTutorial();
      return;
    }
    _tutorialLeft = 0;
    _progress.tutorialDone = true;
    setState(() => _hint = null);
    if (!solved) {
      _showMessage(
        'That is the whole game: fill every tube with a single colour.',
      );
    }
  }

  String? get _tutorialText {
    final move = _tutorialMove;
    if (!_tutorial || move == null || _pour != null) return null;
    return _selected == move[0]
        ? 'Now tap the glowing tube to pour into it'
        : 'Tap the glowing tube to pick it up';
  }

  // ---- Toolbar actions ----------------------------------------------------

  void _undo() {
    if (_busy || _history.isEmpty) return;
    setState(() {
      _tubes = _history.removeLast();
      _selected = _previousSelected = null;
      _hint = null;
      _usedUndo = true;
      _moves++; // undoing is not free, so it counts towards the star rating
      _syncHidden();
    });
    _refreshTutorial();
  }

  void _restart() {
    if (_busy) return;
    setState(() {
      // A tube that was paid for stays for the rest of the level.
      final keepExtraTube = _extraTubeUsed;
      _reset();
      if (keepExtraTube) {
        _extraTubeUsed = true;
        _tubes.add([]);
        _syncHidden();
      }
    });
    _refreshTutorial();
  }

  void _addTube() {
    if (_busy || _extraTubeUsed) return;
    if (!_progress.spend(kExtraTubeCost)) {
      _showMessage(
        'An extra tube costs $kExtraTubeCost coins. '
        'Earn coins by collecting stars.',
      );
      return;
    }
    setState(() {
      _extraTubeUsed = true;
      _tubes.add([]);
      for (final h in _history) {
        h.add([]);
      }
      _syncHidden();
    });
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(duration: const Duration(seconds: 3), content: Text(text)),
      );
  }

  Future<void> _showHint() async {
    if (_busy || _thinking || _tutorial) return;
    if (_progress.coins < kHintCost) {
      _showMessage(
        'A hint costs $kHintCost coin. Earn coins by collecting stars.',
      );
      return;
    }
    setState(() {
      _thinking = true;
      _select(null);
    });
    final before = _moves;
    final move = await compute(hintMove, copyTubes(_tubes));
    if (!mounted) return;
    setState(() => _thinking = false);
    if (_moves != before || _busy) return;
    if (move == null) {
      // Nothing to show, so nothing is charged.
      _showMessage(
        'No way forward from here. Try Undo, Restart or an extra tube.',
      );
      return;
    }
    if (!_progress.spend(kHintCost)) return;
    _services.stats.add(Stat.hints);
    setState(() {
      _hint = move;
      _usedHint = true;
    });
    _hintTimer?.cancel();
    _hintTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _hint = null);
    });
  }

  // ---- Winning ------------------------------------------------------------

  Future<void> _onSolved() async {
    if (_rush) {
      if (_rushOver) return;
      _rushSolved++;
      _services.haptics.heavy();
      _services.sound.playComplete();
      _loadLevel(_level + 1);
      return;
    }
    final stars = starsForMoves(_moves, _par);
    _services.haptics.heavy();
    _services.sound.playWin();
    if (_challenge != null) return _onChallengeSolved(stars);

    final d = _difficulty;
    final int earned;
    var unlocked = const <Achievement>[];
    var lastLevel = false;
    String? note;
    final missions = _services.missions;
    if (d == null) {
      earned = _services.daily.completePuzzle(_moves);
      if (earned > 0) {
        _services.stats.add(Stat.dailies);
        missions.record(MissionEvent.daily);
      }
    } else {
      final firstTime = _progress.starsFor(d, _level) == 0;
      earned = _progress.completeLevel(d, _level, stars);
      lastLevel = d.isLastLevel(_level);
      if (!lastLevel) _progress.setCurrentLevel(d, _level + 1);
      unlocked = _services.achievements.recordLevel(
        firstTime: firstTime,
        stars: stars,
        heart: _heartLevel,
        hidden: _hiddenLevel,
        usedUndo: _usedUndo,
        usedHelp: _usedHint || _extraTubeUsed,
      );
      _services.stats.add(Stat.solves);
      missions.record(MissionEvent.solve);
      missions.record(MissionEvent.star, stars);
      if (stars == 3) missions.record(MissionEvent.perfect);
      if (!_usedUndo) missions.record(MissionEvent.noUndo);
      if (firstTime && _services.spins.recordNewLevel()) {
        note = 'You earned a lucky spin! Find it on the home screen.';
      }
    }
    final solvedMoves = _moves;

    final action = await showDialog<WinAction>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Stack(
        children: [
          WinDialog(
            title: d == null
                ? 'Daily puzzle solved!'
                : (lastLevel
                      ? 'You finished ${d.label}!'
                      : 'Level $_level complete!'),
            rewardLabel: d == null
                ? 'Daily reward'
                : (_heartLevel ? 'Double reward' : 'Reward'),
            nextLabel: d == null || lastLevel ? 'Home' : 'Next level',
            achievements: unlocked,
            onShare: d != null && isMilestone(d, _level)
                ? () => _openSharePoster(d, _level)
                : null,
            onChallenge: () => _shareChallenge(
              Challenge(
                difficulty: d,
                number: d == null ? widget.dailyDay! : _level,
                moves: solvedMoves,
              ),
            ),
            note: note,
            moves: _moves,
            stars: stars,
            coinsEarned: earned,
          ),
          const Positioned.fill(child: Confetti()),
        ],
      ),
    );
    if (!mounted) return;
    if (action == WinAction.replay) {
      if (d != null) _progress.setCurrentLevel(d, _level);
      setState(_reset);
    } else if (d == null || lastLevel) {
      Navigator.pop(context);
    } else {
      _loadLevel(_level + 1);
    }
  }

  void _shareChallenge(Challenge c) {
    SharePlus.instance.share(ShareParams(text: c.shareText));
  }

  Future<void> _onChallengeSolved(int stars) async {
    final c = _challenge!;
    final won = _moves < c.moves;
    if (won && _services.stats.markOnce('challenge:${c.code}')) {
      _services.stats.add(Stat.challengesWon);
    }
    final action = await showDialog<WinAction>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Stack(
        children: [
          WinDialog(
            title: won
                ? 'Challenge won!'
                : (_moves == c.moves ? 'It is a tie!' : 'Not this time'),
            note: won
                ? 'You needed ${c.moves - _moves} fewer moves than your '
                      'friend.'
                : 'Your friend solved it in ${c.moves} moves.',
            nextLabel: 'Home',
            replayLabel: 'Try again',
            onChallenge: won
                ? () => _shareChallenge(
                    Challenge(
                      difficulty: c.difficulty,
                      number: c.number,
                      moves: _moves,
                    ),
                  )
                : null,
            moves: _moves,
            stars: stars,
            coinsEarned: 0,
            rewardLabel: '',
            showReward: false,
          ),
          if (won) const Positioned.fill(child: Confetti()),
        ],
      ),
    );
    if (!mounted) return;
    if (action == WinAction.replay) {
      setState(_reset);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _endRush() async {
    _rushTimer?.cancel();
    _rushTimer = null;
    setState(() => _rushOver = true);
    final solved = _rushSolved;
    final stats = _services.stats;
    final best = stats.raiseTo(Stat.rushBest, solved);
    stats.add(Stat.rushGames);
    _services.missions.record(MissionEvent.rush);
    final coins = solved * kRushCoinsPerPuzzle;
    _progress.addCoins(coins);
    _services.sound.playWin();
    final again = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.timer_rounded, size: 44, color: AppColors.star),
        title: const Text("Time's up!"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$solved',
              style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w900),
            ),
            Text(solved == 1 ? 'puzzle solved' : 'puzzles solved'),
            const SizedBox(height: 10),
            Text(
              best && solved > 0
                  ? 'New best score!'
                  : 'Best: ${stats.value(Stat.rushBest)}',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.star,
              ),
            ),
            if (coins > 0) ...[
              const SizedBox(height: 12),
              CoinBadge(coins: coins, fontSize: 18),
            ],
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Home'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Play again'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (again != true) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      _rushOver = false;
      _rushSolved = 0;
      _rushLeft = kRushSeconds;
      _rushSeed = Random().nextInt(1 << 20);
    });
    _loadLevel(0);
  }

  String get _rushClock =>
      '${max(0, _rushLeft) ~/ 60}:${(max(0, _rushLeft) % 60).toString().padLeft(2, '0')}';

  void _openSharePoster(Difficulty d, int level) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SharePosterScreen(
          progress: _progress,
          data: PosterData.forMilestone(
            _progress,
            d,
            level,
            playerName: _services.profile.name,
            playerPhoto: _services.profile.photoPath,
          ),
        ),
      ),
    );
  }

  Future<void> _openLevels() async {
    final d = _difficulty;
    if (_pour != null || d == null) return;
    final picked = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => LevelSelectScreen(
          progress: _progress,
          difficulty: d,
          current: _level,
        ),
      ),
    );
    if (picked != null && picked != _level) _loadLevel(picked);
  }

  // ---- UI -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final d = _difficulty;
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              if (!_loading && _tutorialText != null)
                _Banner(icon: Icons.touch_app_rounded, text: _tutorialText!)
              else if (!_loading && _hiddenLevel)
                const _Banner(
                  icon: Icons.visibility_off_rounded,
                  text: 'Hidden colours: pour to uncover what is below',
                ),
              if (!_loading && d != null && _heartLevel)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: HeartBottle(
                    completed: _tubes.where(isComplete).length,
                    total: d.filledTubesForLevel(_level),
                  ),
                ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildBoard(),
              ),
              _buildToolbar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final d = _difficulty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 12, 0),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Home',
                iconSize: 28,
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              SoundToggle(settings: _services.settings),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      _rush
                          ? 'RUSH'
                          : _challenge != null
                          ? 'CHALLENGE'
                          : d == null
                          ? 'DAILY'
                          : d.label.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        letterSpacing: 2,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      _rush
                          ? _rushClock
                          : _challenge != null
                          ? 'Beat ${_challenge!.moves} moves'
                          : d == null
                          ? 'Puzzle'
                          : 'Level $_level',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              ListenableBuilder(
                listenable: _progress,
                builder: (_, _) => CoinBadge(coins: _progress.coins),
              ),
            ],
          ),
          if (_rush)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Solved $_rushSolved',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.star,
                ),
              ),
            )
          else if (!_loading)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Moves $_moves',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(width: 14),
                  const Icon(
                    Icons.star_rounded,
                    size: 16,
                    color: AppColors.star,
                  ),
                  Text(
                    ' 3 stars in ${threeStarMoves(_par)} or fewer',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBoard() {
    return LayoutBuilder(
      builder: (context, box) {
        final size = box.biggest;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) {
            final i = BoardLayout.compute(
              size,
              _tubes.length,
            ).hit(d.localPosition);
            if (i != null) {
              _onTubeTap(i);
            } else if (_selected != null && !_busy) {
              setState(() {
                _select(null);
                _applyTutorialGlow();
              });
            }
          },
          child: ListenableBuilder(
            listenable: Listenable.merge([
              _services.settings,
              _services.cosmetics,
            ]),
            builder: (context, _) => CustomPaint(
              size: size,
              painter: BoardPainter(
                tubes: _tubes,
                selected: _selected,
                previousSelected: _previousSelected,
                pour: _pour,
                hint: _hint,
                pourProgress: _pourCtrl,
                selectProgress: _selectCtrl,
                tubeStyle: _services.cosmetics.tubeStyle,
                colorBlind: _services.settings.colorBlind,
                hidden: _hidden,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildToolbar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ToolButton(
            icon: Icons.undo_rounded,
            label: 'Undo',
            onTap: _history.isEmpty ? null : _undo,
          ),
          ToolButton(
            icon: Icons.refresh_rounded,
            label: 'Restart',
            onTap: _restart,
          ),
          if (!_rush)
            ToolButton(
              icon: Icons.lightbulb_outline_rounded,
              label: _thinking ? '…' : 'Hint',
              cost: kHintCost,
              onTap: _tutorial ? null : _showHint,
            ),
          if (!_rush && _challenge == null)
            ToolButton(
              icon: Icons.add_rounded,
              label: 'Tube',
              cost: _extraTubeUsed ? null : kExtraTubeCost,
              onTap: _extraTubeUsed ? null : _addTube,
            ),
          if (_difficulty != null)
            ToolButton(
              icon: Icons.grid_view_rounded,
              label: 'Levels',
              onTap: _openLevels,
            ),
        ],
      ),
    );
  }
}

/// One-line note under the header (walkthrough step, hidden-colour level).
class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.hintGlow),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
