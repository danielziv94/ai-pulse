import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/article.dart';
import '../providers/articles_provider.dart';
import '../theme/app_theme.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ArticlesProvider>();
    final saved = provider.savedArticles;
    final isDark = provider.themeMode == ThemeMode.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Text(
            'Saved',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
        Expanded(
          child: saved.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bookmark_outline, size: 48, color: kMutedGrey),
                      SizedBox(height: 12),
                      Text(
                        'No saved articles yet',
                        style: TextStyle(color: kMutedGrey, fontSize: 14),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Tap the bookmark on any card to save it',
                        style: TextStyle(color: kMutedGrey, fontSize: 12),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: saved.length,
                  separatorBuilder: (_, __) => Divider(
                    color: isDark ? kBorderDark : Colors.grey.shade200,
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    final article = saved[index];
                    return _SavedArticleTile(
                      article: article,
                      isDark: isDark,
                      onRemove: () => provider.toggleSave(article),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _SavedArticleTile extends StatelessWidget {
  final Article article;
  final bool isDark;
  final VoidCallback onRemove;

  const _SavedArticleTile({
    required this.article,
    required this.isDark,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final sourceColor = kSourceColors[article.source] ?? kMutedGrey;

    return InkWell(
      onTap: () => launchUrl(Uri.parse(article.url), mode: LaunchMode.externalApplication),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Source dot
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: sourceColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        article.source,
                        style: TextStyle(
                          fontSize: 11,
                          color: sourceColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Text(
                        ' · ',
                        style: TextStyle(color: kMutedGrey, fontSize: 11),
                      ),
                      Text(
                        article.timeAgo,
                        style: const TextStyle(color: kMutedGrey, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.bookmark, color: kIndigo, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}
