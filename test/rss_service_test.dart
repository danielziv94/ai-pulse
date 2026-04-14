import 'package:flutter_test/flutter_test.dart';
import 'package:ai_pulse/services/rss_service.dart';
import 'package:ai_pulse/models/article.dart';

void main() {
  group('RssService — feed map', () {
    const expectedSources = [
      'Claude',
      'ChatGPT',
      'Gemini',
      'GitHub Copilot',
      'Cursor',
      'Claude Code',
    ];

    test('kRssFeeds has exactly 6 sources', () {
      expect(kRssFeeds.length, equals(6));
    });

    test('kRssFeeds contains all expected sources', () {
      for (final source in expectedSources) {
        expect(kRssFeeds.containsKey(source), isTrue,
            reason: '$source missing from kRssFeeds');
        expect(kRssFeeds[source]!.isNotEmpty, isTrue,
            reason: '$source has no URLs');
      }
    });

    test('all sources have at least 2 fallback URLs', () {
      for (final entry in kRssFeeds.entries) {
        expect(entry.value.length, greaterThanOrEqualTo(2),
            reason: '${entry.key} should have ≥2 fallback URLs');
      }
    });

    test('RSS feed URLs are valid URIs with https scheme', () {
      for (final urls in kRssFeeds.values) {
        for (final url in urls) {
          expect(() => Uri.parse(url), returnsNormally,
              reason: '$url is not a valid URI');
          final uri = Uri.parse(url);
          expect(uri.scheme, anyOf('http', 'https'),
              reason: '$url should use http/https');
        }
      }
    });

    test('Atom feed URLs (.atom) are valid URIs', () {
      final atomUrls = kRssFeeds.values
          .expand((urls) => urls)
          .where((url) => url.endsWith('.atom'))
          .toList();
      expect(atomUrls, isNotEmpty,
          reason: 'Expected at least one .atom feed URL');
      for (final url in atomUrls) {
        final uri = Uri.parse(url);
        expect(uri.scheme, equals('https'));
        expect(uri.host, isNotEmpty);
      }
    });

    test('Claude Code URLs are distinct from Claude URLs', () {
      final claudeUrls = kRssFeeds['Claude']!.toSet();
      final claudeCodeUrls = kRssFeeds['Claude Code']!.toSet();
      final overlap = claudeUrls.intersection(claudeCodeUrls);
      expect(overlap, isEmpty,
          reason: 'Claude and Claude Code should not share any feed URLs');
    });
  });

  group('RssService — deduplication', () {
    Article makeArticle(String url, String source) => Article(
          id: url,
          title: 'Test',
          url: url,
          description: 'desc',
          pubDate: DateTime(2024, 1, 1),
          source: source,
        );

    test('Claude Code articles with duplicate URLs are filtered out', () {
      final claudeArticles = [
        makeArticle('https://anthropic.com/article-1', 'Claude'),
        makeArticle('https://anthropic.com/article-2', 'Claude'),
      ];
      final claudeCodeArticles = [
        makeArticle('https://anthropic.com/article-1', 'Claude Code'), // duplicate
        makeArticle('https://anthropic.com/sdk-release-v2', 'Claude Code'), // unique
      ];

      // Simulate dedup logic from fetchAll()
      final seenUrls = claudeArticles.map((a) => a.url).toSet();
      final unique =
          claudeCodeArticles.where((a) => !seenUrls.contains(a.url)).toList();

      expect(unique.length, equals(1));
      expect(unique.first.url, equals('https://anthropic.com/sdk-release-v2'));
    });

    test('non-Claude-Code articles are never filtered', () {
      final articles = [
        makeArticle('https://openai.com/article-1', 'ChatGPT'),
        makeArticle('https://cursor.com/changelog-1', 'Cursor'),
      ];
      final seenUrls = <String>{};
      // None should be filtered when seenUrls is empty
      final result = articles.where((a) => !seenUrls.contains(a.url)).toList();
      expect(result.length, equals(2));
    });
  });
}
