import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../data/settings_repository.dart';

/// The optional daily reminder: a local notification in the evening of
/// each of the next few days. Opening the game pushes them back, so a
/// player who already played today is not reminded, and one who stays
/// away for a week stops being reminded at all.
class ReminderService {
  ReminderService(this._settings);

  final SettingsRepository _settings;
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  /// Hour of the day (24 h, local time) the reminder is shown.
  static const hour = 19;

  /// Days from today on which a reminder is planned.
  static const days = [1, 2, 3, 5, 7];

  static const _messages = [
    'Your daily gift and puzzle are waiting.',
    'Keep your streak alive: collect today\'s gift.',
    'A fresh daily puzzle is ready. Can you solve it in fewer moves?',
    'Your tubes miss you. New missions are ready.',
    'It has been a while. Come back for your daily gift.',
  ];

  Future<void> _init() async {
    if (_ready) return;
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    _ready = true;
  }

  /// Switches the reminder on, asking for permission if needed. Returns
  /// false, leaving it off, if the player refused.
  Future<bool> enable() async {
    try {
      await _init();
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      if (granted == false) return false;
      _settings.reminder = true;
      await refresh();
      return true;
    } catch (e) {
      debugPrint('Reminder not enabled: $e');
      return false;
    }
  }

  Future<void> disable() async {
    _settings.reminder = false;
    try {
      await _init();
      for (var i = 0; i < days.length; i++) {
        await _plugin.cancel(id: i);
      }
    } catch (e) {
      debugPrint('Reminder not cancelled: $e');
    }
  }

  /// Plans the reminders afresh, counting from today. Call on app start.
  Future<void> refresh() async {
    if (!_settings.reminder) return;
    try {
      await _init();
      final now = DateTime.now();
      for (var i = 0; i < days.length; i++) {
        final when = DateTime(now.year, now.month, now.day + days[i], hour);
        await _plugin.zonedSchedule(
          id: i,
          title: 'Tint Tubes',
          body: _messages[i],
          scheduledDate: tz.TZDateTime.from(when, tz.UTC),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'daily_reminder',
              'Daily reminder',
              channelDescription: 'One reminder a day about the daily gift',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Reminder not planned: $e');
    }
  }
}
