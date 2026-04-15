import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/articles_provider.dart';
import '../services/logger_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ArticlesProvider>();
    final isDark = provider.themeMode == ThemeMode.dark;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          // ── Header ────────────────────────────────────────────────────
          Text(
            'Settings',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Customise your AI Pulse experience',
            style: TextStyle(fontSize: 13, color: kMutedGrey),
          ),

          const SizedBox(height: 24),

          // ── Section 1: Notifications ──────────────────────────────────
          _SectionHeader(label: 'Notifications', isDark: isDark),
          const SizedBox(height: 8),
          _SettingsCard(
            isDark: isDark,
            child: _ToggleRow(
              icon: Icons.notifications_rounded,
              iconColor: const Color(0xFF818cf8),
              title: 'Background notifications',
              subtitle:
                  'Hourly check for new articles (uses battery)',
              value: provider.notificationsEnabled,
              onChanged: (v) =>
                  context.read<ArticlesProvider>().setNotificationsEnabled(v),
            ),
          ),

          const SizedBox(height: 20),

          // ── Section 2: AI Summaries ───────────────────────────────────
          _SectionHeader(label: 'AI Summaries', isDark: isDark),
          const SizedBox(height: 8),
          _SettingsCard(
            isDark: isDark,
            child: _ToggleRow(
              icon: Icons.auto_awesome_rounded,
              iconColor: const Color(0xFF34d399),
              title: 'Gemini AI summaries',
              subtitle:
                  'Generate 2-3 sentence summaries via Gemini API. '
                  'Requires a Gemini API key set at build time.',
              value: provider.geminiEnabled,
              onChanged: (v) =>
                  context.read<ArticlesProvider>().setGeminiEnabled(v),
            ),
          ),

          const SizedBox(height: 20),

          // ── Section 3: Developer ──────────────────────────────────────
          _SectionHeader(label: 'Developer', isDark: isDark),
          const SizedBox(height: 8),
          _SettingsCard(
            isDark: isDark,
            child: Column(
              children: [
                _ToggleRow(
                  icon: Icons.bug_report_rounded,
                  iconColor: const Color(0xFFfbbf24),
                  title: 'Debug logs',
                  subtitle: provider.logsEnabled
                      ? (LoggerService.instance.logFilePath != null
                          ? 'Log: ${LoggerService.instance.logFilePath}'
                          : 'Opening log file…')
                      : 'Write timestamped logs to device storage '
                          '(DCIM/PulseLogs or Android/data/…/PulseLogs).',
                  value: provider.logsEnabled,
                  onChanged: (v) =>
                      context.read<ArticlesProvider>().setLogsEnabled(v),
                ),
                Divider(
                  color: isDark ? kBorderDark : Colors.grey.shade200,
                  height: 1,
                  indent: 48,
                ),
                _TimeWindowRow(isDark: isDark, provider: provider),
                Divider(
                  color: isDark ? kBorderDark : Colors.grey.shade200,
                  height: 1,
                  indent: 48,
                ),
                _ThemeRow(isDark: isDark, provider: provider),
                Divider(
                  color: isDark ? kBorderDark : Colors.grey.shade200,
                  height: 1,
                  indent: 48,
                ),
                _CacheClearRow(isDark: isDark, provider: provider),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // ── About ─────────────────────────────────────────────────────
          const Center(
            child: Text(
              'Personal app by Daniel · Not for distribution',
              style: TextStyle(fontSize: 11, color: kMutedGrey),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 4),
          const Center(
            child: Text(
              'AI Pulse v1.0.2',
              style: TextStyle(fontSize: 11, color: kMutedGrey),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final bool isDark;

  const _SectionHeader({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: isDark ? kIndigoLight : kIndigo,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final Widget child;
  final bool isDark;

  const _SettingsCard({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? kCardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? kBorderDark : Colors.grey.shade200),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: child,
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark =
        context.watch<ArticlesProvider>().themeMode == ThemeMode.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: kMutedGrey,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: kIndigo,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}

class _TimeWindowRow extends StatelessWidget {
  final bool isDark;
  final ArticlesProvider provider;

  const _TimeWindowRow(
      {required this.isDark, required this.provider});

  static const _options = [
    (label: '6h', hours: 6),
    (label: '24h', hours: 24),
    (label: '48h', hours: 48),
    (label: '7d', hours: 168),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.access_time_rounded,
                  size: 20, color: kMutedGrey),
              const SizedBox(width: 14),
              Text(
                'Time window',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SafeArea(
            top: false,
            bottom: false,
            child: Row(
              children: _options.map((opt) {
                final isActive = provider.timeWindowHours == opt.hours;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => context
                        .read<ArticlesProvider>()
                        .setTimeWindow(opt.hours),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isActive ? kIndigo : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isActive
                              ? kIndigo
                              : (isDark
                                  ? kBorderDark
                                  : Colors.grey.shade300),
                        ),
                      ),
                      child: Text(
                        opt.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isActive ? Colors.white : kMutedGrey,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeRow extends StatelessWidget {
  final bool isDark;
  final ArticlesProvider provider;

  const _ThemeRow({required this.isDark, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(
            isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            size: 20,
            color: kMutedGrey,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Dark mode',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          Switch(
            value: isDark,
            onChanged: (_) =>
                context.read<ArticlesProvider>().toggleTheme(),
            activeThumbColor: kIndigo,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}

class _CacheClearRow extends StatelessWidget {
  final bool isDark;
  final ArticlesProvider provider;

  const _CacheClearRow(
      {required this.isDark, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          const Icon(Icons.delete_outline_rounded,
              size: 20, color: kMutedGrey),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Clear summary cache',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Remove all cached Gemini summaries',
                  style: TextStyle(fontSize: 11, color: kMutedGrey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () async {
              await context
                  .read<ArticlesProvider>()
                  .clearSummaryCache();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cache cleared')),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.redAccent,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: const Text('Clear',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
