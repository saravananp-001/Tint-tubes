/// The three difficulty tiers. Each has its own fixed run of levels.
///
/// Every [heartInterval]th level is a "heart level": a much bigger board
/// where each colour fills several tubes, paying double coins.
enum Difficulty {
  /// A short tier for learning the game.
  easy(
    label: 'Easy',
    blurb: 'Learn the game · 20 levels',
    levelCount: 20,
    baseColors: 3,
    colorSteps: [4, 10],
    heartColors: 5,
    heartStep: null,
    hiddenFrom: null,
    hiddenSlots: [],
    unlockCost: 0,
    coinsPerStar: 5,
  ),
  medium(
    label: 'Medium',
    blurb: '100 levels · up to 18 tubes',
    levelCount: 100,
    baseColors: 7,
    colorSteps: [15, 40, 70],
    heartColors: 7,
    heartStep: 50,
    hiddenFrom: 8,
    hiddenSlots: [3],
    unlockCost: 150,
    coinsPerStar: 10,
  ),
  hard(
    label: 'Hard',
    blurb: '1000 levels · up to 22 tubes',
    levelCount: 1000,
    baseColors: 10,
    colorSteps: [100, 400],
    heartColors: 9,
    heartStep: 300,
    hiddenFrom: 6,
    hiddenSlots: [1, 3],
    unlockCost: 400,
    coinsPerStar: 20,
  );

  const Difficulty({
    required this.label,
    required this.blurb,
    required this.levelCount,
    required this.baseColors,
    required this.colorSteps,
    required this.heartColors,
    required this.heartStep,
    required this.hiddenFrom,
    required this.hiddenSlots,
    required this.unlockCost,
    required this.coinsPerStar,
  });

  final String label;
  final String blurb;

  /// Number of levels in this tier.
  final int levelCount;

  /// Colours used on level 1 of this tier.
  final int baseColors;

  /// Ordinary levels gain a colour after each of these levels.
  final List<int> colorSteps;

  /// Colours used on this tier's first heart levels.
  final int heartColors;

  /// Heart levels gain a colour after this level, if set.
  final int? heartStep;

  /// First level that may be a hidden-colour level; null for none.
  final int? hiddenFrom;

  /// Positions within each block of [heartInterval] levels that are
  /// hidden-colour levels.
  final List<int> hiddenSlots;

  /// Coins needed to open this tier; 0 means open from the start.
  final int unlockCost;

  /// Coins paid for every new star earned on an ordinary level.
  final int coinsPerStar;

  /// Every this-many levels is a heart level.
  static const heartInterval = 5;

  /// Tubes each colour fills on a heart level.
  static const heartSets = 2;

  bool isHeartLevel(int level) => level % heartInterval == 0;

  /// On a hidden-colour level only the top of each tube shows; the liquid
  /// underneath is revealed as it is uncovered.
  bool isHiddenLevel(int level) {
    final from = hiddenFrom;
    return from != null &&
        level >= from &&
        hiddenSlots.contains(level % heartInterval);
  }

  bool isLastLevel(int level) => level >= levelCount;

  /// Distinct colours on the board.
  int colorsForLevel(int level) {
    if (isHeartLevel(level)) {
      final step = heartStep;
      return heartColors + (step != null && level > step ? 1 : 0);
    }
    return baseColors + colorSteps.where((s) => level > s).length;
  }

  /// How many tubes each colour fills when the level is solved.
  int setsForLevel(int level) => isHeartLevel(level) ? heartSets : 1;

  /// Tubes that hold liquid at the start of the level.
  int filledTubesForLevel(int level) =>
      colorsForLevel(level) * setsForLevel(level);

  /// Coins paid for every new star earned on [level].
  int coinsPerStarAt(int level) =>
      isHeartLevel(level) ? coinsPerStar * 2 : coinsPerStar;
}
