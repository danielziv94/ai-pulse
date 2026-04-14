import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'background_service.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  factory NotificationService() => instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      debugPrint('NotificationService: permission granted = $granted');
    }
    _initialized = true;
  }

  Future<void> showNewArticlesNotification(int count) async {
    if (!_initialized) return;
    const androidDetails = AndroidNotificationDetails(
      'ai_pulse_channel',
      'AI Pulse',
      channelDescription: 'New AI article notifications',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );
    const details = NotificationDetails(android: androidDetails);
    await _plugin.show(
      0,
      'AI Pulse',
      '$count new AI article${count == 1 ? '' : 's'} available',
      details,
    );
  }

  /// Registers the hourly WorkManager background task.
  Future<void> scheduleHourlyBackgroundCheck() async {
    await Workmanager().registerPeriodicTask(
      kBgTaskUniqueName,
      kBgTaskName,
      frequency: const Duration(hours: 1),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
    debugPrint('NotificationService: hourly background check scheduled');
  }

  /// Cancels the hourly WorkManager background task.
  Future<void> cancelHourlyBackgroundCheck() async {
    await Workmanager().cancelByUniqueName(kBgTaskUniqueName);
    debugPrint('NotificationService: hourly background check cancelled');
  }
}
