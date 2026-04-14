import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/article.dart';
import '../providers/articles_provider.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ArticlesProvider>();
    final isDark = provider.themeMode == ThemeMode.dark;
    final resolvedUrls = provider.resolvedUrls;

    final sources = kSources.where((s) => s != 'All').toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // ── App header ────────────────────────────────────────────────────
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: kIndigo,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.bolt, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Pulse',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const Text(
                  'Version 1.0.0',
                  style: TextStyle(fontSize: 12, color: kMutedGrey),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 28),

        // ── Sources section ───────────────────────────────────────────────
        _SectionHeader(label: 'Sources', isDark: isDark),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark ? kCardDark : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? kBorderDark : Colors.grey.shade200),
          ),
          child: Column(
            children: sources.asMap().entries.map((entry) {
              final i = entry.key;
              final source = entry.value;
              final color = kSourceColors[source] ?? kMutedGrey;
              final url = resolvedUrls[source] ?? 'fetching…';
              final isUnavailable = url == 'unavailable';
              final isLast = i == sources.length - 1;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isUnavailable ? kMutedGrey : color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                source,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                url,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isUnavailable ? Colors.redAccent : kMutedGrey,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (isUnavailable)
                          const Icon(Icons.warning_amber_rounded,
                              size: 14, color: Colors.orange),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Divider(
                      color: isDark ? kBorderDark : Colors.grey.shade100,
                      height: 1,
                      indent: 32,
                    ),
                ],
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 28),

        // ── Cache section ─────────────────────────────────────────────────
        _SectionHeader(label: 'Cache', isDark: isDark),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark ? kCardDark : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? kBorderDark : Colors.grey.shade200),
          ),
          child: ListTile(
            leading: const Icon(Icons.delete_outline, color: kMutedGrey, size: 20),
            title: Text(
              'Clear summary cache',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            subtitle: const Text(
              'Re-fetches Gemini summaries on next refresh',
              style: TextStyle(fontSize: 11, color: kMutedGrey),
            ),
            trailing: const Icon(Icons.chevron_right, color: kMutedGrey, size: 18),
            onTap: () async {
              await context.read<ArticlesProvider>().clearSummaryCache();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cache cleared'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ),

        const SizedBox(height: 28),

        // ── About section ─────────────────────────────────────────────────
        _SectionHeader(label: 'About', isDark: isDark),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? kCardDark : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? kBorderDark : Colors.grey.shade200),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Personal app by Daniel. Not for distribution.',
                style: TextStyle(fontSize: 13, color: kMutedGrey),
              ),
              SizedBox(height: 4),
              Text(
                'github.com/danielziv94',
                style: TextStyle(fontSize: 12, color: kIndigo),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final bool isDark;

  const _SectionHeader({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.0,
        color: isDark ? kMutedGrey : Colors.grey.shade600,
      ),
    );
  }
}
