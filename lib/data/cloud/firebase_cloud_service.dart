import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import 'cloud_service.dart';

/// Firebase-backed [CloudService].
///
/// - `players/{uid}`: private profile (name, age range, picture, score),
///   readable only by its owner.
/// - `leaderboard/{uid}`: public row with nickname and scores only.
/// - `daily/{day}/scores/{uid}`: public daily puzzle score.
/// - Storage `profile_photos/{uid}.jpg`: the picture, owner only.
///
/// Players are signed in anonymously, so there is no login screen.
class FirebaseCloudService implements CloudService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  /// File name of the picture that is currently uploaded; null if none.
  /// Unknown until the private profile has been read once.
  String? _uploadedPhoto;
  bool _photoKnown = false;

  @override
  bool get available => true;

  @override
  String? get playerId => _auth.currentUser?.uid;

  Future<String> _signIn() async {
    final user = _auth.currentUser ?? (await _auth.signInAnonymously()).user!;
    return user.uid;
  }

  Reference _photoRef(String uid) => _storage.ref('profile_photos/$uid.jpg');

  @override
  Future<void> savePlayer(PlayerSnapshot player) async {
    final uid = await _signIn();
    final private = _db.doc('players/$uid');

    if (!_photoKnown) {
      final existing = await private.get();
      _uploadedPhoto = existing.data()?['photoSource'] as String?;
      _photoKnown = true;
    }
    // The picture is best effort: if it cannot be stored (for example
    // Storage is not set up), the profile and score are still saved and
    // the picture is tried again on the next change.
    final path = player.photoPath;
    final source = path?.split('/').last;
    if (source != _uploadedPhoto) {
      try {
        if (path == null) {
          await _deletePhoto(uid);
        } else {
          await _photoRef(
            uid,
          ).putFile(File(path), SettableMetadata(contentType: 'image/jpeg'));
        }
        _uploadedPhoto = source;
      } on FirebaseException catch (e) {
        debugPrint('Profile picture not uploaded: ${e.code}');
      }
    }

    final batch = _db.batch()
      ..set(private, {
        'name': player.name,
        'ageRange': player.ageRange,
        'photoSource': _uploadedPhoto,
        'stars': player.stars,
        'levels': player.levels,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    final row = _db.doc('leaderboard/$uid');
    if (player.onLeaderboard) {
      batch.set(row, {
        'name': player.name,
        'stars': player.stars,
        'levels': player.levels,
        'playerLevel': player.playerLevel,
        'week': player.week,
        'weekStars': player.weekStars,
        'lastWeek': player.lastWeek,
        'lastWeekStars': player.lastWeekStars,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      batch.delete(row);
    }
    await batch.commit();
  }

  static int _int(Map<String, dynamic> data, String key) =>
      (data[key] as num?)?.toInt() ?? 0;

  /// Rows of [query], reading each entry's score from [scoreField].
  Future<List<LeaderboardEntry>> _entries(
    Query<Map<String, dynamic>> query,
    String scoreField,
  ) async {
    await _signIn();
    final result = await query.get();
    return [
      for (final doc in result.docs)
        LeaderboardEntry(
          playerId: doc.id,
          name: doc.data()['name'] as String? ?? 'Player',
          score: _int(doc.data(), scoreField),
          levels: _int(doc.data(), 'levels'),
          playerLevel: max(1, _int(doc.data(), 'playerLevel')),
        ),
    ];
  }

  Future<int> _count(Query<Map<String, dynamic>> query) async {
    await _signIn();
    return (await query.count().get()).count ?? 0;
  }

  CollectionReference<Map<String, dynamic>> get _board =>
      _db.collection('leaderboard');

  CollectionReference<Map<String, dynamic>> _daily(int day) =>
      _db.collection('daily/$day/scores');

  @override
  Future<List<LeaderboardEntry>> topPlayers({int limit = 50}) =>
      _entries(_board.orderBy('stars', descending: true).limit(limit), 'stars');

  @override
  Future<int> rankFor(int stars) async =>
      await _count(_board.where('stars', isGreaterThan: stars)) + 1;

  @override
  Future<List<LeaderboardEntry>> weeklyTop(int week, {int limit = 50}) =>
      _entries(
        _board
            .where('week', isEqualTo: week)
            .where('weekStars', isGreaterThan: 0)
            .orderBy('weekStars', descending: true)
            .limit(limit),
        'weekStars',
      );

  @override
  Future<int> weeklyRank(int week, int stars) async {
    // Players still in that week, plus those who have since moved on and
    // carry it as their previous week.
    final current = await _count(
      _board
          .where('week', isEqualTo: week)
          .where('weekStars', isGreaterThan: stars)
          .orderBy('weekStars', descending: true),
    );
    final moved = await _count(
      _board
          .where('lastWeek', isEqualTo: week)
          .where('lastWeekStars', isGreaterThan: stars)
          .orderBy('lastWeekStars', descending: true),
    );
    return current + moved + 1;
  }

  @override
  Future<void> saveDailyScore(int day, String name, int moves) async {
    final uid = await _signIn();
    await _daily(day).doc(uid).set({
      'name': name,
      'moves': moves,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<List<LeaderboardEntry>> dailyTop(int day, {int limit = 50}) =>
      _entries(_daily(day).orderBy('moves').limit(limit), 'moves');

  @override
  Future<int> dailyRank(int day, int moves) async =>
      await _count(_daily(day).where('moves', isLessThan: moves)) + 1;

  @override
  Future<void> deleteDailyScores(List<int> days) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || days.isEmpty) return;
    final batch = _db.batch();
    for (final day in days) {
      batch.delete(_daily(day).doc(uid));
    }
    await batch.commit();
  }

  Future<void> _deletePhoto(String uid) async {
    try {
      await _photoRef(uid).delete();
    } on FirebaseException catch (e) {
      if (_uploadedPhoto != null && e.code != 'object-not-found') rethrow;
    }
  }

  @override
  Future<void> deleteMyData() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final uid = user.uid;
    await _deletePhoto(uid);
    final batch = _db.batch()
      ..delete(_db.doc('players/$uid'))
      ..delete(_db.doc('leaderboard/$uid'));
    await batch.commit();
    await user.delete();
    _uploadedPhoto = null;
    _photoKnown = false;
  }
}
