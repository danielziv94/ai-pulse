import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'logger_service.dart';

class GeminiService {
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  Future<String?> summarize(String content) async {
    if (_apiKey.isEmpty) {
      LoggerService.instance.log('Gemini: GEMINI_API_KEY not set — skipping');
      return null;
    }
    if (content.trim().isEmpty) return null;

    final trimmed =
        content.length > 3000 ? content.substring(0, 3000) : content;

    try {
      final response = await http
          .post(
            Uri.parse('$_endpoint?key=$_apiKey'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {
                      'text':
                          'Write a detailed two-paragraph summary of this AI news article or release note.\n\n'
                          'Paragraph 1 (4-5 sentences): Describe exactly what was announced, released, or changed. '
                          'Include specific names — model names, version numbers, feature names, company names, '
                          'researcher names — and any concrete numbers (parameters, benchmarks, percentages, dates).\n\n'
                          'Paragraph 2 (4-5 sentences): Explain why this matters. Who benefits and how? '
                          'What problem does it solve? How does it compare to previous work or competitors? '
                          'What are the broader implications for AI development or for developers and users?\n\n'
                          'Rules: Plain English only. No bullet points. No markdown. No headers. '
                          'Do not start with "This article", "The article", or "According to". '
                          'Write both paragraphs as flowing prose.\n\n'
                          '$trimmed',
                    }
                  ]
                }
              ],
              'generationConfig': {
                'maxOutputTokens': 600,
                'temperature': 0.4,
              },
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final candidates = data['candidates'] as List<dynamic>?;
        if (candidates != null && candidates.isNotEmpty) {
          final parts =
              candidates[0]['content']?['parts'] as List<dynamic>?;
          if (parts != null && parts.isNotEmpty) {
            final text = parts[0]['text'] as String?;
            LoggerService.instance.log('Gemini: summary generated (${text?.length ?? 0} chars)');
            return text?.trim();
          }
        }
        LoggerService.instance.log('Gemini: unexpected response shape');
      } else if (response.statusCode == 429) {
        LoggerService.instance.log('Gemini: quota exceeded (429)');
        debugPrint('GeminiService: quota exceeded (429)');
      } else {
        LoggerService.instance
            .log('Gemini: HTTP ${response.statusCode} — ${response.body}');
        debugPrint(
            'GeminiService: error ${response.statusCode} — ${response.body}');
      }
    } on TimeoutException {
      LoggerService.instance.log('Gemini: request timed out after 15s');
      debugPrint('GeminiService: timeout');
    } catch (e) {
      LoggerService.instance.log('Gemini: exception — $e');
      debugPrint('GeminiService: exception — $e');
    }
    return null;
  }
}
