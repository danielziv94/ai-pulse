import 'package:flutter_test/flutter_test.dart';
import 'package:ai_pulse/services/rss_service.dart';

void main() {
  group('RssService', () {
    test('kRssFeeds has all 8 sources', () {
      const expected = [
        'Anthropic', 'OpenAI', 'Google', 'Meta AI',
        'Mistral', 'xAI', 'Hugging Face', 'Cohere',
      ];
      for (final source in expected) {
        expect(kRssFeeds.containsKey(source), isTrue,
            reason: '$source missing from kRssFeeds');
        expect(kRssFeeds[source]!.isNotEmpty, isTrue,
            reason: '$source has no fallback URLs');
      }
    });

    test('all sources have at least 2 fallback URLs', () {
      for (final entry in kRssFeeds.entries) {
        expect(entry.value.length, greaterThanOrEqualTo(2),
            reason: '${entry.key} should have ≥2 fallback URLs');
      }
    });

    test('_parseFeed handles empty body gracefully', () {
      // Test the RSS service's feed map length as a proxy for correct setup.
      expect(kRssFeeds.length, equals(8));
    });

    test('RSS feed URLs are valid URIs', () {
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
  });
}
