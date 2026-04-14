import 'package:flutter_test/flutter_test.dart';
import 'package:ai_pulse/models/article.dart';

void main() {
  group('Article', () {
    Article makeArticle({
      DateTime? pubDate,
      String description = 'Hello world this is a test article',
      String? aiSummary,
    }) {
      return Article(
        id: 'https://example.com/article',
        title: 'Test Article',
        url: 'https://example.com/article',
        description: description,
        aiSummary: aiSummary,
        pubDate: pubDate ?? DateTime.now().subtract(const Duration(hours: 2)),
        source: 'OpenAI',
      );
    }

    test('timeAgo: minutes', () {
      final a = makeArticle(
          pubDate: DateTime.now().subtract(const Duration(minutes: 30)));
      expect(a.timeAgo, '30m ago');
    });

    test('timeAgo: hours', () {
      final a = makeArticle(
          pubDate: DateTime.now().subtract(const Duration(hours: 5)));
      expect(a.timeAgo, '5h ago');
    });

    test('timeAgo: days', () {
      final a = makeArticle(
          pubDate: DateTime.now().subtract(const Duration(days: 3)));
      expect(a.timeAgo, '3d ago');
    });

    test('timeAgo: weeks', () {
      final a = makeArticle(
          pubDate: DateTime.now().subtract(const Duration(days: 14)));
      expect(a.timeAgo, '2w ago');
    });

    test('estimatedReadMinutes: minimum 1', () {
      final a = makeArticle(description: 'Short.');
      expect(a.estimatedReadMinutes, greaterThanOrEqualTo(1));
    });

    test('estimatedReadMinutes: scales with word count', () {
      final long = List.filled(400, 'word').join(' ');
      final a = makeArticle(description: long);
      expect(a.estimatedReadMinutes, equals(2));
    });

    test('toJson / fromJson round-trip', () {
      final original = makeArticle(aiSummary: 'Great summary');
      final json = original.toJson();
      final restored = Article.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.url, original.url);
      expect(restored.description, original.description);
      expect(restored.aiSummary, original.aiSummary);
      expect(restored.pubDate.toIso8601String(),
          original.pubDate.toIso8601String());
      expect(restored.source, original.source);
      expect(restored.isSaved, original.isSaved);
    });

    test('fromJson handles missing aiSummary', () {
      final json = {
        'id': 'id',
        'title': 'title',
        'url': 'url',
        'description': 'desc',
        'pubDate': DateTime.now().toIso8601String(),
        'source': 'Google',
      };
      final a = Article.fromJson(json);
      expect(a.aiSummary, isNull);
    });

    test('isSaved default is false', () {
      final a = makeArticle();
      expect(a.isSaved, isFalse);
    });

    test('kSourceColors has all 6 sources', () {
      const expectedSources = [
        'Claude', 'ChatGPT', 'Gemini',
        'GitHub Copilot', 'Cursor', 'Claude Code',
      ];
      expect(kSourceColors.length, equals(6));
      for (final source in expectedSources) {
        expect(kSourceColors.containsKey(source), isTrue,
            reason: '$source missing from kSourceColors');
      }
    });
  });
}
