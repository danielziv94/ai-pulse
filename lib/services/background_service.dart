import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import 'cache_service.dart';
import 'notification_service.dart';
import 'rss_service.dart';

const String kBgTaskName = 'ai_pulse_hourly_check';
const String kBgTaskUniqueName = 'ai_pulse_hourly_unique';

/// WorkManager callback — runs in a separate Dart isolate.
/// Must be a top-level function annotated with @pragma('vm:entry-point').
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();

      final rssService = RssService();
      final cacheService = CacheService();
      final notificationService = NotificationService.instance;

      await notificationService.init();

      final articles = await rssService.fetchAll();

      if (articles.isEmpty) return true;

      final knownIds = await cacheService.getKnownArticleIds();
      final newArticles =
          articles.where((a) => !knownIds.contains(a.id)).toList();

      if (newArticles.isNotEmpty) {
        // Persist the new IDs so next run doesn't double-notify
        final allIds = {...knownIds, ...newArticles.map((a) => a.id)}.toList();
        await cacheService.setKnownArticleIds(allIds);
        await notificationService.showNewArticlesNotification(newArticles.length);
      }

      return true;
    } catch (e) {
      // Return true so WorkManager doesn't retry immediately on crash
      debugPrint('[BgTask] Error in background task: $e');
      return true;
    }
  });
}
