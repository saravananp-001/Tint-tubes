/// Most moves allowed for a three-star finish.
int threeStarMoves(int par) => (par * 1.25).ceil();

/// Most moves allowed for a two-star finish.
int twoStarMoves(int par) => (par * 1.75).ceil();

/// Stars (1 to 3) for finishing a level in [moves] moves.
int starsForMoves(int moves, int par) {
  if (moves <= threeStarMoves(par)) return 3;
  if (moves <= twoStarMoves(par)) return 2;
  return 1;
}
