import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/article.dart';
import '../providers/articles_provider.dart';
import '../theme/app_theme.dart';

class SourceFilter extends StatelessWidget {
  const SourceFilter({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ArticlesProvider>();
    final selected = provider.selectedSource;
    final isDark = provider.themeMode == ThemeMode.dark;

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: kSources.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final source = kSources[index];
          final isActive = selected == source;
          return GestureDetector(
            onTap: () => provider.setSource(source),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? kIndigo : (isDark ? kCardDark : Colors.grey.shade200),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive ? kIndigo : (isDark ? kBorderDark : Colors.grey.shade300),
                ),
              ),
              child: Text(
                source,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive
                      ? kIndigoLight
                      : (isDark ? kMutedGrey : Colors.grey.shade700),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
