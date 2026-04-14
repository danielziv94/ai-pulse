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
        content.length > 2000 ? content.substring(0, 2000) : content;

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
                          'Write a 4-5 sentence paragraph summarising this AI news article. '
                          'Cover: what was announced or discovered, why it matters, '
                          'and any key numbers, names, or technical details worth knowing. '
                          'Write in plain English, no bullet points, no markdown. '
                          'Do not start with "This article", "The article", or "According to".\n\n'
                          '$trimmed',
                    }
                  ]
                }
              ],
              'generationConfig': {
                'maxOutputTokens': 280,
                'temperature': 0.4,
              },
            }),
          )
          .timeout(const Duration(seconds: 8));

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
      LoggerService.instance.log('Gemini: request timed out after 8s');
      debugPrint('GeminiService: timeout');
    } catch (e) {
      LoggerService.instance.log('Gemini: exception — $e');
      debugPrint('GeminiService: exception — $e');
    }
    return null;
  }
}
