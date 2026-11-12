import 'dart:math';

/// Units of liquid a tube can hold.
const int kTubeCapacity = 4;

/// A board: each tube lists its colour ids from bottom to top.
typedef Tubes = List<List<int>>;

Tubes copyTubes(Tubes t) => [for (final x in t) List<int>.of(x)];

bool isUniform(List<int> t) => t.every((c) => c == t.first);

bool isComplete(List<int> t) => t.length == kTubeCapacity && isUniform(t);

bool isSolved(Tubes tubes) => tubes.every((t) => t.isEmpty || isComplete(t));

/// Number of same-coloured units sitting on top of the tube.
int topRun(List<int> t) {
  if (t.isEmpty) return 0;
  var n = 1;
  while (n < t.length && t[t.length - 1 - n] == t.last) {
    n++;
  }
  return n;
}

/// Units that would move when pouring [a] into [b]; 0 if the pour is illegal.
int pourCount(List<int> a, List<int> b) {
  if (a.isEmpty || b.length == kTubeCapacity) return 0;
  if (b.isNotEmpty && b.last != a.last) return 0;
  return min(topRun(a), kTubeCapacity - b.length);
}

void applyPour(Tubes tubes, int from, int to, int n) {
  final c = tubes[from].last;
  tubes[from].removeRange(tubes[from].length - n, tubes[from].length);
  tubes[to].addAll(List.filled(n, c));
}
