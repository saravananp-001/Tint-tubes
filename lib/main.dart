import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'app_services.dart';
import 'data/cloud/cloud_service.dart';
import 'data/cloud/firebase_cloud_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final prefs = await SharedPreferences.getInstance();
  final services = AppServices(prefs, cloud: await _cloud());
  services.reminder.refresh().ignore();
  runApp(TintTubesApp(services: services));
}

/// The online service, or the offline stand-in when no Firebase project
/// is configured or it fails to start.
Future<CloudService> _cloud() async {
  final options = firebaseOptions;
  if (options == null) return const NoCloudService();
  try {
    await Firebase.initializeApp(options: options);
    return FirebaseCloudService();
  } catch (e) {
    debugPrint('Firebase did not start: $e');
    return const NoCloudService();
  }
}
