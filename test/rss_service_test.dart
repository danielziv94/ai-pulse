import 'package:flutter_test/flutter_test.dart';
import 'package:ai_pulse/services/rss_service.dart';
import 'package:ai_pulse/models/article.dart';

void main() {
  group('RssService — feed map', () {
    const expectedSources = [
      'Anthropic',
      'OpenAI',
      'Google',
      'GitHub',
      'Cursor',
    ];

    test('kRssFeeds has exactly 5 sources', () {
      expect(kRssFeeds.length, equals(5));
    });

    test('kRssFeeds contains all expected company-name sources', () {
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

    test('all source names are company names not product names', () {
      const productNames = [
        'Claude',
        'ChatGPT',
        'Gemini',
        'GitHub Copilot',
        'Claude Code',
      ];
      for (final name in productNames) {
        expect(kRssFeeds.containsKey(name), isFalse,
            reason: '$name is a product name and should not be a source key');
      }
    });

    test('RSS feed URLs are valid URIs with http/https scheme', () {
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

    test('kSources matches kRssFeeds keys (plus All)', () {
      final feedSources = kRssFeeds.keys.toSet();
      final filterSources = kSources.where((s) => s != 'All').toSet();
      expect(filterSources, equals(feedSources));
    });
  });
}
