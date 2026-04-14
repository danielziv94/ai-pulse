import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_pulse/services/cache_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('CacheService', () {
    test('getSummary returns null when no summary cached', () async {
      final cache = CacheService();
      final result = await cache.getSummary('unknown_id');
      expect(result, isNull);
    });

    test('saveSummary then getSummary returns saved value', () async {
      final cache = CacheService();
      await cache.saveSummary('article_1', 'This is a great summary.');
      final result = await cache.getSummary('article_1');
      expect(result, equals('This is a great summary.'));
    });

    test('clearAllSummaries removes summary keys', () async {
      final cache = CacheService();
      await cache.saveSummary('article_1', 'Summary 1');
      await cache.saveSummary('article_2', 'Summary 2');
      await cache.clearAllSummaries();
      expect(await cache.getSummary('article_1'), isNull);
      expect(await cache.getSummary('article_2'), isNull);
    });

    test('getSavedIds returns empty list initially', () async {
      final cache = CacheService();
      final ids = await cache.getSavedIds();
      expect(ids, isEmpty);
    });

    test('setSavedIds persists and getSavedIds retrieves', () async {
      final cache = CacheService();
      await cache.setSavedIds(['id1', 'id2', 'id3']);
      final ids = await cache.getSavedIds();
      expect(ids, containsAll(['id1', 'id2', 'id3']));
    });

    test('getKnownArticleIds returns empty list initially', () async {
      final cache = CacheService();
      final ids = await cache.getKnownArticleIds();
      expect(ids, isEmpty);
    });

    test('setKnownArticleIds persists and getKnownArticleIds retrieves',
        () async {
      final cache = CacheService();
      final testIds = List.generate(10, (i) => 'article_$i');
      await cache.setKnownArticleIds(testIds);
      final retrieved = await cache.getKnownArticleIds();
      expect(retrieved.length, equals(10));
    });

    test('setKnownArticleIds trims to 500 max', () async {
      final cache = CacheService();
      final tooMany = List.generate(600, (i) => 'id_$i');
      await cache.setKnownArticleIds(tooMany);
      final retrieved = await cache.getKnownArticleIds();
      expect(retrieved.length, equals(500));
    });

    test('clearAllSummaries does not remove saved_articles key', () async {
      final cache = CacheService();
      await cache.setSavedIds(['saved_1', 'saved_2']);
      await cache.saveSummary('art', 'Summary');
      await cache.clearAllSummaries();
      // Saved IDs should be untouched
      final saved = await cache.getSavedIds();
      expect(saved, containsAll(['saved_1', 'saved_2']));
    });
  });
}
