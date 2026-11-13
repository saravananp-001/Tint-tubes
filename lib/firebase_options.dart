import 'package:firebase_core/firebase_core.dart';

/// Connection details of the Firebase project (`tinttubes`) behind
/// the online leaderboard. Set this to null to run the game fully offline
/// with every online feature hidden.
///
/// These values identify the project; they are not secrets. Access is
/// controlled by `firestore.rules` and `storage.rules`.
// ignore: unnecessary_nullable_for_final_variable_declarations
const FirebaseOptions? firebaseOptions = FirebaseOptions(
  apiKey: 'AIzaSyB-gwLo6GaJDRz-4eMknxCAXCIS7jZQq8A',
  appId: '1:352665638927:android:194ec1de9ae61c857f2b7a',
  messagingSenderId: '352665638927',
  projectId: 'tinttubes',
  storageBucket: 'tinttubes.firebasestorage.app',
);
