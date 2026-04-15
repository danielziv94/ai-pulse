import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import '../models/article.dart';
import 'logger_service.dart';

const Map<String, List<String>> kRssFeeds = {
  'Anthropic': [
    'https://www.anthropic.com/news/rss',
    'https://raw.githubusercontent.com/taobojlen/anthropic-rss-feed/main/anthropic_news_rss.xml',
    'https://www.anthropic.com/rss.xml',
  ],
  'OpenAI': [
    'https://openai.com/news/rss.xml',
    'https://openai.com/news/rss',
    'https://openai.com/blog/rss.xml',
  ],
  'Google': [
    'https://blog.google/technology/ai/rss',
    'https://deepmind.google/discover/blog/rss',
    'https://blog.google/rss',
    'https://research.google/blog/rss',
  ],
  // GitHub Copilot AI/ML blog + changelog + general blog as fallback
  'GitHub': [
    'https://github.blog/ai-and-ml/github-copilot/feed/',
    'https://github.blog/changelog/feed/',
    'https://github.blog/feed/',
  ],
  'Cursor': [
    'https://cursor.com/blog/rss.xml',
    'https://cursor.com/rss.xml',
    'https://raw.githubusercontent.com/Olshansk/rss-feeds/main/feeds/feed_cursor.xml',
    'https://cursor-changelog.com/feed',
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

  /// Extracts the article URL from an Atom <entry>.
  /// Prefers <link rel="alternate" href="..."/> which GitHub Atom feeds use.
  String? _atomLink(XmlElement entry) {
    final links = entry.findElements('link').toList();
    if (links.isEmpty) return _text(entry, 'link');
    for (final l in links) {
      if (l.getAttribute('rel') == 'alternate') {
        final href = l.getAttribute('href');
        if (href != null && href.isNotEmpty) return href;
        final text = l.innerText.trim();
        return text.isNotEmpty ? text : null;
      }
    }
    final first = links.first;
    final href = first.getAttribute('href');
    if (href != null && href.isNotEmpty) return href;
    final text = first.innerText.trim();
    return text.isNotEmpty ? text : null;
  }

  Article? _parseAtomEntry(XmlElement entry, String source) {
    try {
      final title = _text(entry, 'title');
      final link = _atomLink(entry);
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
