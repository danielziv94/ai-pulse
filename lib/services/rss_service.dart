import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import '../models/article.dart';
import 'logger_service.dart';

const Map<String, List<String>> kRssFeeds = {
  // Anthropic has no public RSS — Google News is the reliable source
  'Anthropic': [
    'https://www.anthropic.com/news/rss',
    'https://www.anthropic.com/blog/rss',
    'https://news.google.com/rss/search?q=Anthropic+AI&hl=en-US&gl=US&ceid=US:en',
  ],
  // OpenAI has no public RSS — Google News fallback
  'OpenAI': [
    'https://openai.com/news/rss',
    'https://openai.com/blog/rss.xml',
    'https://news.google.com/rss/search?q=OpenAI+GPT&hl=en-US&gl=US&ceid=US:en',
  ],
  'Google': [
    'https://blog.google/technology/ai/rss/',
    'https://blog.google/technology/ai/rss',
    'https://ai.googleblog.com/feeds/posts/default',
    'https://news.google.com/rss/search?q=Google+DeepMind+AI&hl=en-US&gl=US&ceid=US:en',
  ],
  'Meta AI': [
    'https://ai.meta.com/blog/rss/',
    'https://ai.meta.com/blog/rss',
    'https://engineering.fb.com/category/ai-research/feed/',
    'https://news.google.com/rss/search?q=Meta+AI+Llama&hl=en-US&gl=US&ceid=US:en',
  ],
  // Mistral has no public RSS — Google News fallback
  'Mistral': [
    'https://mistral.ai/news/rss',
    'https://mistral.ai/news/feed.xml',
    'https://news.google.com/rss/search?q=Mistral+AI+model&hl=en-US&gl=US&ceid=US:en',
  ],
  // xAI has no public RSS — Google News fallback
  'xAI': [
    'https://x.ai/news/rss',
    'https://x.ai/blog/rss',
    'https://news.google.com/rss/search?q=xAI+Grok+Elon&hl=en-US&gl=US&ceid=US:en',
  ],
  'Hugging Face': [
    'https://huggingface.co/blog/feed.xml',
    'https://huggingface.co/blog/rss.xml',
    'https://news.google.com/rss/search?q=Hugging+Face+AI&hl=en-US&gl=US&ceid=US:en',
  ],
  'Cohere': [
    'https://cohere.com/blog/rss',
    'https://cohere.com/blog/feed',
    'https://cohere.com/feed.xml',
    'https://news.google.com/rss/search?q=Cohere+AI+LLM&hl=en-US&gl=US&ceid=US:en',
  ],
};

class RssService {
  final Map<String, String> resolvedUrls = {};

  Future<_FetchResult?> _tryFeedUrls(List<String> urls) async {
    for (final url in urls) {
      try {
        LoggerService.instance.log('RSS: trying $url');
        final response = await http
            .get(
              Uri.parse(url),
              headers: {
                'User-Agent': 'AIPulse/1.0 (Flutter; Android)',
                'Accept':
                    'application/rss+xml, application/xml, text/xml, */*',
              },
            )
            .timeout(const Duration(seconds: 10));
        if (response.statusCode == 200 && response.body.isNotEmpty) {
          LoggerService.instance.log('RSS: success $url (${response.body.length} bytes)');
          return _FetchResult(url: url, response: response);
        }
        LoggerService.instance
            .log('RSS: $url → HTTP ${response.statusCode}');
      } catch (e) {
        LoggerService.instance.log('RSS: $url → error: $e');
      }
    }
    return null;
  }

  Future<List<Article>> fetchAll() async {
    resolvedUrls.clear();

    final futures = kRssFeeds.entries.map((entry) async {
      final source = entry.key;
      final urls = entry.value;
      try {
        final result = await _tryFeedUrls(urls);
        if (result == null) {
          LoggerService.instance
              .log('RSS: all ${urls.length} URLs failed for $source');
          resolvedUrls[source] = 'unavailable';
          return <Article>[];
        }
        resolvedUrls[source] = result.url;
        final articles = _parseFeed(result.response.body, source);
        LoggerService.instance
            .log('RSS: $source → ${articles.length} articles from ${result.url}');
        return articles;
      } catch (e) {
        LoggerService.instance.log('RSS: processing error for $source — $e');
        resolvedUrls[source] = 'unavailable';
        return <Article>[];
      }
    });

    final results = await Future.wait(futures);
    final all = results.expand((list) => list).toList();
    all.sort((a, b) => b.pubDate.compareTo(a.pubDate));

    // Summary diagnostics
    LoggerService.instance.log('RSS fetch complete: ${all.length} total articles');
    for (final e in resolvedUrls.entries) {
      LoggerService.instance.log('  ${e.key}: ${e.value}');
    }

    return all;
  }

  List<Article> _parseFeed(String body, String source) {
    try {
      final document = XmlDocument.parse(body);
      // Try RSS 2.0 first
      final items = document.findAllElements('item').toList();
      if (items.isNotEmpty) {
        return items
            .map((item) => _parseRssItem(item, source))
            .whereType<Article>()
            .toList();
      }
      // Try Atom
      final entries = document.findAllElements('entry').toList();
      return entries
          .map((entry) => _parseAtomEntry(entry, source))
          .whereType<Article>()
          .toList();
    } catch (e) {
      debugPrint('RssService: XML parse error for $source — $e');
      return [];
    }
  }

  Article? _parseRssItem(XmlElement item, String source) {
    try {
      final title = _text(item, 'title');
      final link = _text(item, 'link') ?? _attr(item, 'link', 'href');
      final description = _stripHtml(_text(item, 'description') ?? '');
      final pubDateStr =
          _text(item, 'pubDate') ?? _text(item, 'dc:date') ?? '';
      final pubDate = _parseDate(pubDateStr);

      if (title == null || link == null) return null;

      return Article(
        id: link,
        title: title.trim(),
        url: link.trim(),
        description: description.trim(),
        pubDate: pubDate,
        source: source,
      );
    } catch (_) {
      return null;
    }
  }

  Article? _parseAtomEntry(XmlElement entry, String source) {
    try {
      final title = _text(entry, 'title');
      final linkEl = entry.findElements('link').firstOrNull;
      final link = linkEl?.getAttribute('href') ?? _text(entry, 'link');
      final summary = _stripHtml(
        _text(entry, 'summary') ?? _text(entry, 'content') ?? '',
      );
      final pubDateStr =
          _text(entry, 'published') ?? _text(entry, 'updated') ?? '';
      final pubDate = _parseDate(pubDateStr);

      if (title == null || link == null) return null;

      return Article(
        id: link,
        title: title.trim(),
        url: link.trim(),
        description: summary.trim(),
        pubDate: pubDate,
        source: source,
      );
    } catch (_) {
      return null;
    }
  }

  String? _text(XmlElement el, String tag) {
    try {
      final found = el.findElements(tag).firstOrNull;
      return found?.innerText.isNotEmpty == true ? found!.innerText : null;
    } catch (_) {
      return null;
    }
  }

  String? _attr(XmlElement el, String tag, String attr) {
    try {
      return el.findElements(tag).firstOrNull?.getAttribute(attr);
    } catch (_) {
      return null;
    }
  }

  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'&amp;'), '&')
        .replaceAll(RegExp(r'&lt;'), '<')
        .replaceAll(RegExp(r'&gt;'), '>')
        .replaceAll(RegExp(r'&quot;'), '"')
        .replaceAll(RegExp(r'&#39;'), "'")
        .replaceAll(RegExp(r'&nbsp;'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  DateTime _parseDate(String s) {
    if (s.isEmpty) return DateTime.now();
    try {
      return DateTime.parse(s);
    } catch (_) {
      try {
        return _parseRfc822(s);
      } catch (_) {
        return DateTime.now();
      }
    }
  }

  DateTime _parseRfc822(String s) {
    const months = {
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
      'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
    };
    final parts = s.trim().split(RegExp(r'[\s,]+'));
    final filtered = parts.where((p) => p.isNotEmpty).toList();
    if (filtered.length < 4) return DateTime.now();
    int i = 0;
    if (filtered[i].length == 3 && !RegExp(r'^\d').hasMatch(filtered[i])) i++;
    final day = int.tryParse(filtered[i++]) ?? 1;
    final month = months[filtered[i++].toLowerCase().substring(0, 3)] ?? 1;
    final year = int.tryParse(filtered[i++]) ?? 2024;
    final timeParts =
        (i < filtered.length ? filtered[i] : '00:00:00').split(':');
    final hour = int.tryParse(timeParts[0]) ?? 0;
    final minute = timeParts.length > 1 ? int.tryParse(timeParts[1]) ?? 0 : 0;
    final second = timeParts.length > 2 ? int.tryParse(timeParts[2]) ?? 0 : 0;
    return DateTime.utc(year, month, day, hour, minute, second);
  }
}

class _FetchResult {
  final String url;
  final http.Response response;
  const _FetchResult({required this.url, required this.response});
}
