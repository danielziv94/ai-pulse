import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/articles_provider.dart';
import '../theme/app_theme.dart';

class SettingsSheet extends StatelessWidget {
  const SettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ArticlesProvider>();
    final isDark = provider.themeMode == ThemeMode.dark;
    final timeWindow = provider.timeWindowHours;

    const timeOptions = [6, 24, 48, 168]; // hours
    const timeLabels = ['6h', '24h', '48h', '7d'];

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      decoration: BoxDecoration(
        color: isDark ? kCardDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? kBorderDark : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Settings',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 20),

          // Dark mode toggle
          Row(
            children: [
              Icon(isDark ? Icons.dark_mode : Icons.light_mode,
                  size: 20, color: isDark ? kIndigoLight : kIndigo),
              const SizedBox(width: 12),
              Text(
                'Dark Mode',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              Switch(
                value: isDark,
                activeThumbColor: kIndigo,
                onChanged: (_) => context.read<ArticlesProvider>().toggleTheme(),
              ),
            ],
          ),

          const SizedBox(height: 20),
          Text(
            'Time Window',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? kMutedGrey : Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),

          // Segmented control
          Row(
            children: List.generate(timeOptions.length, (i) {
              final isSelected = timeWindow == timeOptions[i];
              return Expanded(
                child: GestureDetector(
                  onTap: () => context.read<ArticlesProvider>().setTimeWindow(timeOptions[i]),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(right: i < timeOptions.length - 1 ? 6 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? kIndigo : (isDark ? kBgDark : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? kIndigo : (isDark ? kBorderDark : Colors.grey.shade300),
                      ),
                    ),
                    child: Text(
                      timeLabels[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : (isDark ? kMutedGrey : Colors.grey.shade700),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
