import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/articles_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/news_card.dart';
import '../widgets/source_filter.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final PageController _pageController =
      PageController(viewportFraction: 0.88);
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ArticlesProvider>();
    final articles = provider.filteredArticles;
    final isDark = provider.themeMode == ThemeMode.dark;
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, MMM d').format(now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Pulse',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateStr,
                      style: const TextStyle(fontSize: 12, color: kMutedGrey),
                    ),
                  ],
                ),
              ),
              // Live indicator + refresh
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF22c55e),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Live',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF22c55e),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed:
                        provider.isLoading ? null : () => provider.refresh(),
                    icon: provider.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: kIndigo,
                            ),
                          )
                        : Icon(
                            Icons.refresh,
                            size: 20,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ── Source filter pills ───────────────────────────────────────────
        const SourceFilter(),

        const SizedBox(height: 16),

        // ── Error banner ──────────────────────────────────────────────────
        if (provider.error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              provider.error!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ),

        // ── Card feed ─────────────────────────────────────────────────────
        Expanded(
          child: provider.isLoading && articles.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(color: kIndigo),
                )
              : articles.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.article_outlined,
                              size: 48, color: kMutedGrey),
                          const SizedBox(height: 12),
                          Text(
                            'No articles in the last '
                            '${_timeWindowLabel(provider.timeWindowHours)}',
                            style: const TextStyle(
                                color: kMutedGrey, fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => provider.refresh(),
                            child: const Text('Refresh',
                                style: TextStyle(color: kIndigo)),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: kIndigo,
                      onRefresh: () => provider.refresh(),
                      child: Column(
                        children: [
                          Expanded(
                            child: PageView.builder(
                              controller: _pageController,
                              itemCount: articles.length,
                              onPageChanged: (i) =>
                                  setState(() => _currentPage = i),
                              itemBuilder: (context, index) =>
                                  NewsCard(article: articles[index]),
                            ),
                          ),

                          // Dot indicators — uniform 7×7 circles, color-only transition
                          if (articles.length > 1)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  articles.length.clamp(0, 20),
                                  (i) {
                                    final isActive = i == _currentPage;
                                    return AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 3),
                                      width: 7,
                                      height: 7,
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? const Color(0xFF7c3aed)
                                            : const Color(0xFF2a2a2e),
                                        shape: BoxShape.circle,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
        ),
      ],
    );
  }

  String _timeWindowLabel(int hours) {
    if (hours < 24) return '${hours}h';
    if (hours == 24) return '24 hours';
    if (hours == 48) return '48 hours';
    return '7 days';
  }
}
