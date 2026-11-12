import 'tube_rules.dart';

String _key(Tubes tubes) {
  final parts = [
    for (final t in tubes) String.fromCharCodes(t.map((c) => 65 + c)),
  ]..sort();
  return parts.join('|');
}

List<List<int>> _candidates(Tubes s) {
  final good = <List<int>>[];
  final meh = <List<int>>[];
  for (var i = 0; i < s.length; i++) {
    final a = s[i];
    if (a.isEmpty || isComplete(a)) continue;
    var triedEmpty = false;
    for (var j = 0; j < s.length; j++) {
      if (i == j) continue;
      final b = s[j];
      final n = pourCount(a, b);
      if (n == 0) continue;
      if (b.isEmpty) {
        // Moving a single-colour tube into an empty one achieves nothing,
        // and all empty tubes are interchangeable.
        if (triedEmpty || isUniform(a)) continue;
        triedEmpty = true;
        meh.add([i, j]);
      } else if (n == topRun(a)) {
        good.add([i, j]);
      } else {
        meh.add([i, j]);
      }
    }
  }
  return good..addAll(meh);
}

/// Depth-first search for a solution. Returns the list of [from, to] moves,
/// or null if none was found within [maxNodes] visited states.
List<List<int>>? solve(Tubes start, {int maxNodes = 250000}) {
  if (isSolved(start)) return [];
  final seen = <String>{_key(start)};
  final states = <Tubes>[start];
  final moves = <List<List<int>>>[_candidates(start)];
  final idx = <int>[0];
  final path = <List<int>>[];

  while (states.isNotEmpty) {
    final d = states.length - 1;
    if (idx[d] >= moves[d].length) {
      states.removeLast();
      moves.removeLast();
      idx.removeLast();
      if (path.isNotEmpty) path.removeLast();
      continue;
    }
    final m = moves[d][idx[d]++];
    final next = copyTubes(states[d]);
    applyPour(next, m[0], m[1], pourCount(next[m[0]], next[m[1]]));
    if (!seen.add(_key(next))) continue;
    if (isSolved(next)) return path..add(m);
    if (seen.length > maxNodes) return null;
    states.add(next);
    moves.add(_candidates(next));
    idx.add(0);
    path.add(m);
  }
  return null;
}

/// First move of a solution from the given position, or null if stuck.
/// Top-level so it can run in a background isolate.
List<int>? hintMove(Tubes tubes) {
  final s = solve(tubes);
  return (s == null || s.isEmpty) ? null : s.first;
}
