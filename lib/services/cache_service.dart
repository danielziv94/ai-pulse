import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static const String _summaryPrefix = 'summary_';
  static const String _savedKey = 'saved_articles';
  static const String _knownIdsKey = 'known_article_ids';

  Future<String?> getSummary(String articleId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_summaryPrefix$articleId');
  }

  Future<void> saveSummary(String articleId, String summary) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_summaryPrefix$articleId', summary);
  }

  Future<void> clearAllSummaries() async {
    final prefs = await SharedPreferences.getInstance();
    final keys =
        prefs.getKeys().where((k) => k.startsWith(_summaryPrefix)).toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  Future<List<String>> getSavedIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_savedKey) ?? [];
  }

  Future<void> setSavedIds(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_savedKey, ids);
  }

  Future<List<String>> getKnownArticleIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_knownIdsKey) ?? [];
  }

  Future<void> setKnownArticleIds(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    // Keep only the latest 500 IDs to prevent unbounded growth
    final trimmed = ids.length > 500 ? ids.sublist(ids.length - 500) : ids;
    await prefs.setStringList(_knownIdsKey, trimmed);
  }
}
