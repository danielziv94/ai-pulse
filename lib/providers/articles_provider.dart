import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/article.dart';
import '../services/rss_service.dart';
import '../services/gemini_service.dart';
import '../services/cache_service.dart';
import '../services/notification_service.dart';
import '../services/logger_service.dart';

// Semaphore to limit concurrent Gemini calls to 5
class _Semaphore {
  final int maxCount;
  int _count;
  final List<Completer<void>> _waiters = [];

  _Semaphore(this.maxCount) : _count = maxCount;

  Future<void> acquire() async {
    if (_count > 0) {
      _count--;
      return;
    }
    final completer = Completer<void>();
    _waiters.add(completer);
    await completer.future;
  }

  void release() {
    if (_waiters.isNotEmpty) {
      final completer = _waiters.removeAt(0);
      completer.complete();
    } else {
      _count++;
    }
  }
}

class ArticlesProvider extends ChangeNotifier {
  final RssService _rssService = RssService();
  final GeminiService _geminiService = GeminiService();
  final CacheService _cacheService = CacheService();
  final NotificationService _notificationService = NotificationService.instance;
  final _Semaphore _geminiSemaphore = _Semaphore(5);

  List<Article> _allArticles = [];
  String _selectedSource = 'All';
  int _timeWindowHours = 24;
  ThemeMode _themeMode = ThemeMode.dark;
  Set<String> _savedIds = {};
  bool _isLoading = false;
  String? _error;
  Map<String, String> _resolvedUrls = {};
  Set<String> _previousArticleIds = {};

  // Toggle states
  bool _notificationsEnabled = false;
  bool _geminiEnabled = true;
  bool _logsEnabled = false;

  // ── Getters ──────────────────────────────────────────────────────────

  bool get isLoading => _isLoading;
  String? get error => _error;
  ThemeMode get themeMode => _themeMode;
  Map<String, String> get resolvedUrls => Map.unmodifiable(_resolvedUrls);
  bool get notificationsEnabled => _notificationsEnabled;
  bool get geminiEnabled => _geminiEnabled;
  bool get logsEnabled => _logsEnabled;
  String get selectedSource => _selectedSource;
  int get timeWindowHours => _timeWindowHours;

  List<Article> get filteredArticles {
    final cutoff =
        DateTime.now().subtract(Duration(hours: _timeWindowHours));
    return _allArticles.where((a) {
      final inWindow = a.pubDate.isAfter(cutoff);
      final matchSource =
          _selectedSource == 'All' || a.source == _selectedSource;
      return inWindow && matchSource;
    }).toList();
  }

  List<Article> get savedArticles =>
      _allArticles.where((a) => a.isSaved).toList()
        ..sort((a, b) => b.pubDate.compareTo(a.pubDate));

  // ── Initialisation ────────────────────────────────────────────────────

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    final savedIds = await _cacheService.getSavedIds();
    _savedIds = savedIds.toSet();

    _notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
    _geminiEnabled = prefs.getBool('gemini_enabled') ?? true;
    _logsEnabled = prefs.getBool('logs_enabled') ?? false;

    LoggerService.instance.setEnabled(_logsEnabled);
    LoggerService.instance.log('ArticlesProvider: init (notifications=$_notificationsEnabled, gemini=$_geminiEnabled, logs=$_logsEnabled)');

    await refresh();
  }

  // ── Toggles ───────────────────────────────────────────────────────────

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    if (value) {
      await _notificationService.scheduleHourlyBackgroundCheck();
    } else {
      await _notificationService.cancelHourlyBackgroundCheck();
    }
    notifyListeners();
  }

  Future<void> setGeminiEnabled(bool value) async {
    _geminiEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('gemini_enabled', value);
    notifyListeners();
  }

  Future<void> setLogsEnabled(bool value) async {
    _logsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('logs_enabled', value);
    LoggerService.instance.setEnabled(value);
    LoggerService.instance.log('Logging ${value ? "enabled" : "disabled"}');
    notifyListeners();
  }

  // ── Refresh ───────────────────────────────────────────────────────────

  Future<void> refresh() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      LoggerService.instance.log('ArticlesProvider: starting refresh');
      final fetched = await _rssService.fetchAll();
      _resolvedUrls = Map.from(_rssService.resolvedUrls);

      // Restore saved state
      for (final article in fetched) {
        if (_savedIds.contains(article.id)) {
          article.isSaved = true;
        }
      }

      // New article detection for notifications
      final newIds = fetched.map((a) => a.id).toSet();
      final brandNewIds = newIds.difference(_previousArticleIds);
      final newCount = _previousArticleIds.isEmpty ? 0 : brandNewIds.length;

      // Update known IDs in cache (for background service comparison)
      if (newIds.isNotEmpty) {
        await _cacheService.setKnownArticleIds(newIds.toList());
      }

      _previousArticleIds = newIds;
      _allArticles = fetched;

      _isLoading = false;
      notifyListeners();

      if (_geminiEnabled) {
        await _generateSummaries();
      }

      if (newCount > 0 && _notificationsEnabled) {
        await _notificationService.showNewArticlesNotification(newCount);
      }

      LoggerService.instance
          .log('ArticlesProvider: refresh done — ${fetched.length} articles, $newCount new');
    } catch (e) {
      LoggerService.instance.log('ArticlesProvider: refresh error — $e');
      _error = 'Failed to load articles. Check your connection.';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _generateSummaries() async {
    final articles = List<Article>.from(_allArticles);
    final futures = articles.map((article) async {
      final cached = await _cacheService.getSummary(article.id);
      if (cached != null) {
        article.aiSummary = cached;
        notifyListeners();
        return;
      }

      await _geminiSemaphore.acquire();
      try {
        final content = article.description.isNotEmpty
            ? article.description
            : article.title;
        final summary = await _geminiService.summarize(content);
        if (summary != null && summary.isNotEmpty) {
          article.aiSummary = summary;
          await _cacheService.saveSummary(article.id, summary);
          notifyListeners();
        }
      } finally {
        _geminiSemaphore.release();
      }
    });

    await Future.wait(futures);
  }

  // ── Filters ───────────────────────────────────────────────────────────

  void setSource(String source) {
    _selectedSource = source;
    notifyListeners();
  }

  void setTimeWindow(int hours) {
    _timeWindowHours = hours;
    notifyListeners();
  }

  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  // ── Saved articles ────────────────────────────────────────────────────

  Future<void> toggleSave(Article article) async {
    article.isSaved = !article.isSaved;
    if (article.isSaved) {
      _savedIds.add(article.id);
    } else {
      _savedIds.remove(article.id);
    }
    await _cacheService.setSavedIds(_savedIds.toList());
    notifyListeners();
  }

  // ── Cache management ──────────────────────────────────────────────────

  Future<void> clearSummaryCache() async {
    await _cacheService.clearAllSummaries();
    for (final article in _allArticles) {
      article.aiSummary = null;
    }
    notifyListeners();
    if (_geminiEnabled) {
      _generateSummaries();
    }
  }
}
