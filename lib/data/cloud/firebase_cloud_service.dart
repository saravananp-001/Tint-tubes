import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import 'cloud_service.dart';

/// Firebase-backed [CloudService].
///
/// - `players/{uid}`: private profile (name, age range, picture, score),
///   readable only by its owner.
/// - `leaderboard/{uid}`: public row with nickname and score only.
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
      })
      ..set(_db.doc('leaderboard/$uid'), {
        'name': player.name,
        'stars': player.stars,
        'levels': player.levels,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    await batch.commit();
  }

  @override
  Future<List<LeaderboardEntry>> topPlayers({int limit = 50}) async {
    await _signIn();
    final result = await _db
        .collection('leaderboard')
        .orderBy('stars', descending: true)
        .limit(limit)
        .get();
    return [
      for (final doc in result.docs)
        LeaderboardEntry(
          playerId: doc.id,
          name: doc.data()['name'] as String? ?? 'Player',
          stars: (doc.data()['stars'] as num?)?.toInt() ?? 0,
          levels: (doc.data()['levels'] as num?)?.toInt() ?? 0,
        ),
    ];
  }

  @override
  Future<int> rankFor(int stars) async {
    await _signIn();
    final ahead = await _db
        .collection('leaderboard')
        .where('stars', isGreaterThan: stars)
        .count()
        .get();
    return (ahead.count ?? 0) + 1;
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
