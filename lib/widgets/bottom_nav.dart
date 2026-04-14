import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PulseBottomNav extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const PulseBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<PulseBottomNav> createState() => _PulseBottomNavState();
}

class _PulseBottomNavState extends State<PulseBottomNav>
    with TickerProviderStateMixin {
  // One burst + one scale controller per tab
  late final List<AnimationController> _burstControllers;
  late final List<AnimationController> _scaleControllers;
  late final List<Animation<double>> _burstAnimations;
  late final List<Animation<double>> _burstOpacity;
  late final List<Animation<double>> _scaleAnimations;

  static const _tabs = [
    (icon: Icons.rss_feed_rounded, label: 'Feed'),
    (icon: Icons.bookmark_rounded, label: 'Saved'),
    (icon: Icons.person_rounded, label: 'Profile'),
    (icon: Icons.settings_rounded, label: 'Settings'),
  ];

  @override
  void initState() {
    super.initState();

    _burstControllers = List.generate(
      _tabs.length,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      ),
    );

    _scaleControllers = List.generate(
      _tabs.length,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 150),
      ),
    );

    _burstAnimations = _burstControllers
        .map(
          (c) => Tween<double>(begin: 0, end: 1).animate(
            CurvedAnimation(parent: c, curve: Curves.easeOut),
          ),
        )
        .toList();

    _burstOpacity = _burstControllers
        .map(
          (c) => Tween<double>(begin: 1, end: 0).animate(
            CurvedAnimation(parent: c, curve: Curves.easeIn),
          ),
        )
        .toList();

    _scaleAnimations = _scaleControllers
        .map(
          (c) => TweenSequence<double>([
            TweenSequenceItem(
                tween: Tween(begin: 1.0, end: 1.15), weight: 1),
            TweenSequenceItem(
                tween: Tween(begin: 1.15, end: 1.0), weight: 1),
          ]).animate(CurvedAnimation(parent: c, curve: Curves.easeInOut)),
        )
        .toList();
  }

  @override
  void dispose() {
    for (final c in _burstControllers) {
      c.dispose();
    }
    for (final c in _scaleControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _handleTap(int index) {
    if (index == widget.currentIndex) return;

    // Burst circle animation
    _burstControllers[index].forward(from: 0);
    // Icon scale animation
    _scaleControllers[index].forward(from: 0);

    widget.onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? kCardDark : Colors.white;
    final borderColor = isDark ? kBorderDark : Colors.grey.shade200;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(top: BorderSide(color: borderColor, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(_tabs.length, (i) {
              final isActive = widget.currentIndex == i;
              final tab = _tabs[i];

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _handleTap(i),
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Burst circle
                        AnimatedBuilder(
                          animation: _burstControllers[i],
                          builder: (_, __) {
                            final scale = _burstAnimations[i].value;
                            final opacity = _burstOpacity[i].value;
                            return Opacity(
                              opacity: opacity,
                              child: Container(
                                width: 40 * scale,
                                height: 40 * scale,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: kIndigo.withValues(alpha: 0.25),
                                ),
                              ),
                            );
                          },
                        ),
                        // Icon + label
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedBuilder(
                              animation: _scaleControllers[i],
                              builder: (_, child) => Transform.scale(
                                scale: _scaleAnimations[i].value,
                                child: child,
                              ),
                              child: Icon(
                                tab.icon,
                                size: 22,
                                color: isActive ? kIndigo : kMutedGrey,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              tab.label,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isActive
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isActive ? kIndigo : kMutedGrey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
