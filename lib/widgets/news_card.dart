import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../models/article.dart';
import '../providers/articles_provider.dart';
import '../theme/app_theme.dart';

// ── Shimmer widget ────────────────────────────────────────────────────────────

class _ShimmerLine extends StatefulWidget {
  final double width;

  const _ShimmerLine({this.width = double.infinity});

  @override
  State<_ShimmerLine> createState() => _ShimmerLineState();
}

class _ShimmerLineState extends State<_ShimmerLine>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..repeat(reverse: true);
    _colorAnimation = ColorTween(
      begin: kShimmerBase,
      end: kShimmerHighlight,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: 12,
          decoration: BoxDecoration(
            color: _colorAnimation.value,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      },
    );
  }
}

// ── Shimmer summary block ─────────────────────────────────────────────────────

class _ShimmerSummary extends StatelessWidget {
  const _ShimmerSummary();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ShimmerLine(),
        SizedBox(height: 6),
        _ShimmerLine(width: double.infinity),
        SizedBox(height: 6),
        _ShimmerLine(width: 220),
      ],
    );
  }
}

// ── News Card ─────────────────────────────────────────────────────────────────

class NewsCard extends StatefulWidget {
  final Article article;

  const NewsCard({super.key, required this.article});

  @override
  State<NewsCard> createState() => _NewsCardState();
}

class _NewsCardState extends State<NewsCard> {
  Timer? _shimmerTimer;
  bool _shimmerTimedOut = false;

  @override
  void initState() {
    super.initState();
    _startShimmerTimer();
  }

  void _startShimmerTimer() {
    _shimmerTimer?.cancel();
    if (widget.article.aiSummary == null) {
      _shimmerTimer = Timer(const Duration(seconds: 10), () {
        if (mounted && widget.article.aiSummary == null) {
          setState(() => _shimmerTimedOut = true);
        }
      });
    }
  }

  @override
  void didUpdateWidget(NewsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.article.id != widget.article.id) {
      _shimmerTimedOut = false;
      _startShimmerTimer();
    } else if (widget.article.aiSummary != null) {
      _shimmerTimer?.cancel();
    }
  }

  @override
  void dispose() {
    _shimmerTimer?.cancel();
    super.dispose();
  }

  Future<void> _openInChrome(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _shareArticle() {
    // Copy URL to clipboard then open system share sheet
    Clipboard.setData(ClipboardData(text: widget.article.url));
    Share.share(widget.article.url, subject: widget.article.title);
  }

  void _showLongPressSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ShareBottomSheet(article: widget.article),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ArticlesProvider>();
    final isDark = provider.themeMode == ThemeMode.dark;
    final geminiEnabled = provider.geminiEnabled;
    final sourceColor = kSourceColors[widget.article.source] ?? kMutedGrey;

    // Summary area logic
    final hasSummary = widget.article.aiSummary != null;
    final hasDescription = widget.article.description.isNotEmpty;

    const summaryStyle = TextStyle(
      fontSize: 11,
      color: kMutedGrey,
      height: 1.6,
    );

    // Each branch is an Align with a unique key so AnimatedSwitcher
    // detects the change and fades between states correctly.
    Widget summaryWidget;
    if (!geminiEnabled) {
      summaryWidget = Align(
        key: const ValueKey('rss_desc'),
        alignment: Alignment.topLeft,
        child: Text(
          widget.article.description.isNotEmpty
              ? widget.article.description
              : widget.article.title,
          overflow: TextOverflow.fade,
          style: summaryStyle,
        ),
      );
    } else if (hasSummary) {
      summaryWidget = Align(
        key: const ValueKey('ai_summary'),
        alignment: Alignment.topLeft,
        child: Text(
          widget.article.aiSummary!,
          overflow: TextOverflow.fade,
          style: summaryStyle,
        ),
      );
    } else if (_shimmerTimedOut || hasDescription) {
      summaryWidget = Align(
        key: const ValueKey('fallback_desc'),
        alignment: Alignment.topLeft,
        child: Text(
          widget.article.description,
          overflow: TextOverflow.fade,
          style: summaryStyle,
        ),
      );
    } else {
      summaryWidget = const Align(
        key: ValueKey('shimmer'),
        alignment: Alignment.topLeft,
        child: _ShimmerSummary(),
      );
    }

    return GestureDetector(
      onLongPress: _showLongPressSheet,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? kCardDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? kBorderDark : Colors.grey.shade200,
          ),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: source dot + name + time + share + bookmark
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: sourceColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.article.source,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: sourceColor,
                    ),
                  ),
                  // RSS badge when Gemini is disabled
                  if (!geminiEnabled) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: kBorderDark,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Text(
                        'RSS',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: kMutedGrey,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    widget.article.timeAgo,
                    style: const TextStyle(fontSize: 11, color: kMutedGrey),
                  ),
                  const SizedBox(width: 8),
                  // Share button (iOS-style upload icon)
                  GestureDetector(
                    onTap: _shareArticle,
                    child: const Icon(
                      Icons.ios_share,
                      size: 17,
                      color: kMutedGrey,
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => provider.toggleSave(widget.article),
                    child: Icon(
                      widget.article.isSaved
                          ? Icons.bookmark
                          : Icons.bookmark_outline,
                      size: 18,
                      color: widget.article.isSaved ? kIndigo : kMutedGrey,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Headline
              Text(
                widget.article.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black87,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 10),

              // Summary area — Expanded fills all remaining vertical space in the card
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: summaryWidget,
                  ),
                ),
              ),

              Divider(
                color: isDark ? kBorderDark : Colors.grey.shade200,
                height: 1,
              ),

              const SizedBox(height: 12),

              // Footer: read time + open button
              Row(
                children: [
                  const Icon(Icons.schedule, size: 12, color: kMutedGrey),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.article.estimatedReadMinutes} min read',
                    style:
                        const TextStyle(fontSize: 11, color: kMutedGrey),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _openInChrome(widget.article.url),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: kIndigo,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Open in Chrome',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Share bottom sheet ────────────────────────────────────────────────────────

class _ShareBottomSheet extends StatelessWidget {
  final Article article;

  const _ShareBottomSheet({required this.article});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      decoration: const BoxDecoration(
        color: kCardDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: kBorderDark,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            article.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.ios_share, color: kIndigoLight),
            title: const Text('Share article',
                style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Clipboard.setData(ClipboardData(text: article.url));
              Share.share(article.url, subject: article.title);
            },
          ),
          ListTile(
            leading: const Icon(Icons.open_in_browser, color: kIndigoLight),
            title: const Text('Open in Chrome',
                style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              launchUrl(Uri.parse(article.url),
                  mode: LaunchMode.externalApplication);
            },
          ),
        ],
      ),
    );
  }
}
