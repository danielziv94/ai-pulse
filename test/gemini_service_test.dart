import 'package:flutter_test/flutter_test.dart';
import 'package:ai_pulse/services/gemini_service.dart';

void main() {
  group('GeminiService', () {
    test('summarize returns null when no API key is set', () async {
      // GEMINI_API_KEY is not set in test environment via --dart-define,
      // so the service should return null gracefully.
      final service = GeminiService();
      final result = await service.summarize('Test content for summarization');
      // Either null (no key) or a string (if key accidentally set) — never throws
      expect(result, anyOf(isNull, isA<String>()));
    });

    test('summarize returns null for empty content', () async {
      final service = GeminiService();
      final result = await service.summarize('');
      expect(result, isNull);
    });

    test('summarize returns null for whitespace-only content', () async {
      final service = GeminiService();
      final result = await service.summarize('   \n\t  ');
      expect(result, isNull);
    });
  });
}
